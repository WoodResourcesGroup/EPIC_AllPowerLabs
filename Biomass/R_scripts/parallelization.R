library(doParallel)
library(foreach)
detectCores()
no_cores <- detectCores() - 1
c1 <- makeCluster(no_cores)
registerDoParallel(c1)


###################################################################
# start timer
strt<-Sys.time()

# function

inputs = 1:100

result.lemma.p <- foreach(i=inputs, .combine = rbind, .packages = c('raster','rgeos'), .errorhandling="stop") %dopar% {
  single <- drought[i,]
  clip1 <- crop(LEMMA, extent(single))
  clip2 <- mask(clip1, single)
  pcoords <- cbind(clip2@data@values, coordinates(clip2)) # coordinates of each pixel
  pcoords <- as.data.frame(pcoords)
  pcoords <- na.omit(pcoords)
  Pol.ID <- rep(i, nrow(pcoords)) # create a Polygon ID
  ext <- extract(clip2, single) # extracts data from the raster - this value is the plot # of the raster cell, which corresponds to detailed data in the attribute table
  tab <- lapply(ext, table) # creates a table that counts how many of each raster value there are in the polygon
  s <- sum(tab[[1]]) # Counts total raster cells the polygon - this is different from length(clip2tg) because it doesn't include NAs
  mat <- as.data.frame(tab)
  mat2 <- as.data.frame(tab[[1]]/s) # gives fraction of polygon occupied by each plot type. Adds up to 1 for each polygon.
  mat2 <- merge(mat, mat2, by="Var1")
  # extract attribute information from LEMMA for each plot number contained in the polygon:
  L.in.mat <- subset(LEMMA@data@attributes[[1]], LEMMA@data@attributes[[1]][,"ID"] %in% mat[,1])[,c("ID","BAC_GE_3","BPHC_GE_3_CRM","TPHC_GE_3","QMDC_DOM","CONPLBA","TREEPLBA")]
  merge <- merge(L.in.mat, mat2, by.y = "Var1", by.x = "ID") # merge LEMMA data with polygon data into one table
  # The below for loop calculates biomass per tree based on the average dbh of dominant and codominant trees for 
  # the most common conifer species in each raster cell:
  merge$CONBM_tree_kg <- 0
  merge$D_CONBM_kg <- 0
  merge$relNO <- 0
  for (i in 1:nrow(merge)) {
    cell <- merge[i,]
    if (cell$CONPLBA %in% Cedars) { #CONPLBA = Conifer tree species with plurality of basal area
      num <- (B0[1] + B1[1]*log(cell$QMDC_DOM)) # apply formula above, but w/o the exp. QMDC_DOM = Quadratic mean diameter of all dominant and codominant conifers
    } else if (cell$CONPLBA %in% Dougfirs) {
      num <- (B0[2] + B1[2]*log(cell$QMDC_DOM))
    } else if (cell$CONPLBA %in% Firs) {
      num <- (B0[3] + B1[3]*log(cell$QMDC_DOM))
    } else if (cell$CONPLBA %in% Pines) {
      num <- (B0[4] + B1[4]*log(cell$QMDC_DOM))
    } else if (cell$CONPLBA %in% Spruces) {
      num <- (B0[5] + B1[5]*log(cell$QMDC_DOM))
    } else {
      num <- 0
    }
    if (num == 0) {
      merge[i,]$CONBM_tree_kg <- 0 # assign 0 if no conifers
    } else {
      merge[i,]$CONBM_tree_kg <- exp(num) # finish the formula to assign biomass per tree in that pixel
    }
  }
  
  # Find biomass per pixel using biomass per tree and estimated number of trees
  pmerge <- merge(pcoords, merge, by.x ="V1", by.y = "ID") # pmerge has a line for every pixel
  # problem here
  pmerge$relBA <- pmerge$BAC_GE_3/sum(pmerge$BAC_GE_3) # Create column for % of polygon BA in that pixel. 
  # BAC_GE_3 is basal area of live conifers in that pixel.
  tot_NO <- single@data$NO_TREE # Total number of trees in the polygon
  pmerge$relNO <- tot_NO*pmerge$relBA # Assign approximate number of trees in that pixel based on proportion of BA in the pixel 
  # and total number of trees in polygon
  pmerge$D_CONBM_kg <- pmerge$relNO*pmerge$CONBM_tree_kg # D_CONBM_kg is total dead biomass in that pixel, based on biomass per tree and estimated number of trees in pixel
  
  # Create vectors that are the same length as pmerge to combine into final table:
  D_Pol_CONBM_kg <- rep(sum(pmerge$D_CONBM_kg), nrow(pmerge)) # Sum biomass over the entire polygon 
  Av_BM_TR <- D_Pol_CONBM_kg/tot_NO # Calculate average biomass per tree based on total polygon biomass and number of trees in the polygon
  QMDC_DOM <- pmerge$QMDC_DOM # Find the average of the pixels' quadratic mean diameters 
  CONPL <-  pmerge$CONPLBA # Find the conifer species that has a plurality in the most pixels
  Pol.x <- rep(gCentroid(single)@coords[1], nrow(pmerge)) 
  Pol.y <- rep(gCentroid(single)@coords[2], nrow(pmerge))
  RPT_YR <- rep(single@data$RPT_YR, nrow(pmerge))
  Pol.NO_TREE <- rep(single@data$NO_TREE, nrow(pmerge))
  Pol.Shap_Ar <- rep(single@data$Shap_Ar, nrow(pmerge))
  Pol.Pixels <- rep(s, nrow(pmerge)) # number of pixels
  
  # Estimate biomass of live AND dead trees based on LEMMA values of conifer biomass per pixel:
  All_CONBM_kgha <- pmerge$BPHC_GE_3_CRM # BPHC_GE_3_CRM is estimated biomass of all conifers from LEMMA
  All_Pol_CONBM_kgha <- rep(mean(pmerge$BPHC_GE_3_CRM),nrow(pmerge)) # Average across polygons
  CON_THA <- pmerge$TPHC_GE_3 # TPHC_GE_3 is conifer trees per hectare from LEMMA
  
  # Bring it all together
  final <- cbind(pmerge$x, pmerge$y, pmerge$D_CONBM_kg, pmerge$relNO,pmerge$relBA, pmerge$V1, Pol.ID, Pol.x, Pol.y, RPT_YR,Pol.NO_TREE, Pol.Shap_Ar,D_Pol_CONBM_kg,All_CONBM_kgha,All_Pol_CONBM_kgha,CON_THA, QMDC_DOM,Av_BM_TR)
  final <- as.data.frame(final)
  final$All_Pol_CON_NO <- (single@data$Shap_Ar/10000*900)*CON_THA # Estimate total number of conifers in the polygon
  final$All_Pol_CON_BM <- (single@data$Shap_Ar/10000*900)*All_Pol_CONBM_kgha # Estimate total conifer biomass in the polygon
  return(final)
}
key <- seq(1, nrow(result.lemma.p)) # Create a key for each pixel (row)
result.lemma.p <- cbind(key, result.lemma.p)
names(result.lemma.p)[names(result.lemma.p)=="V1"] <- "x"
names(result.lemma.p)[names(result.lemma.p)=="V2"] <- "y"
names(result.lemma.p)[names(result.lemma.p)=="V3"] <- "D_CONBM_kg"
names(result.lemma.p)[names(result.lemma.p)=="V4"] <- "relNO"
names(result.lemma.p)[names(result.lemma.p)=="V5"] <- "relBA"
names(result.lemma.p)[names(result.lemma.p)=="V6"] <- "PlotID"
chocolate100 <- result.lemma.p
remove(result.lemma.p)

# end timer
print(Sys.time()-strt)
###################################################################

