### ONLY NEED TO INSTALL PACKAGES ONCE
#install.packages("rgdal")
#install.packages("raster")
#install.packages("rgeos")
#install.packages("stringr")
#install.packages("viridis")

### NOTE: Throughout this code, there are time-intensive steps that have already been done and only need to be done once, 
### such as cropping and rewriting large datasets. These steps are included but commented out to reduce processing time.

library(rgdal)
library(raster)
library(rgeos)
library(stringr)
library(viridis)
library(parallel)

options(digits = 5)

### OPEN LEMMA DATA 
setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/LEMMA_gnn_sppsz_2014_08_28/")
# LEMMA <- raster("mr200_2012")
# crs(LEMMA) # 5070. based on what this guys says: http://gis.stackexchange.com/questions/128190/convert-srtext-to-proj4text
# plot(LEMMA) # This is just plotting alias for FCID, forest class identification number, as described here: http://lemma.forestry.oregonstate.edu/data/structure-maps
# extent(LEMMA)

# LEMMA <- crop(LEMMA, extent(-2362845, -1627605, 1232145, 2456985)) # Crop LEMMA so it only contains CA
# LEMMA_bu <- LEMMA # backup
# writeRaster(LEMMA, filename = "LEMMA.grd", overwrite = T) # save a backup
# This creates both a .gri and a .grd file
# I tried writing the raster in GeoTIFF and IMG formats, but they do not retain attribute information, which is critical

LEMMA <- raster("LEMMA.gri")

### OPEN DROUGHT MORTALITY POLYGONS
setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
# drought <- readOGR(dsn = "DroughtTreeMortality.gdb", layer = "DroughtTreeMortality") 
# plot(drought, add = TRUE) # only plot if necessary; takes a long ass time
# crs(drought)
# drought <- spTransform(drought, crs(LEMMA)) #change it to CRS of Gonzalez and LEMMA data - this takes a while
# crs(drought)
# writeOGR(obj=drought, dsn="tempdir",layer = "drought", driver="ESRI Shapefile")
drought <- readOGR("tempdir", "drought")
drought_bu <- drought # backup so that I don't need to re-read if I accidentally override drought

### RAMIREZ DATA
# setwd("~/Box Sync/EPIC-Biomass/GIS Data/Ramirez Data/Copy of ENVI_FR.1754x4468x15x1000/")
# GDALinfo("FR_2016.01.13_167.bsq")
# CR_mort <- raster("FR_2016.01.13_167.bsq")
# crs(CR_mort)
# plot(CR_mort)
# CR_mort <- projectRaster(CR_mort, crs=crs(drought))
#setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/tempdir")
# writeRaster(CR_mort, filename = "CR_mort.tif", format = "GTiff", overwrite = TRUE) # save a backup 
# CR_mort <- raster("CR_mort.tif")

# narrow drought down to large-ish polygons and those with more than one tree
# might want to change these later
drought <- subset(drought, drought$ACRES > 2 & drought$NO_TREE > 1)
## print how much area this excludes: ~30,000 ACRES (out of ~4,000,000)
sum(subset(drought_bu, drought_bu$ACRES <= 2 | drought_bu$NO_TREE == 1)$ACRES)
sum(drought_bu$ACRES)
## print how many trees this excludes: ~90,000 trees (out of ~33,000,000)
sum(subset(drought_bu, drought_bu$ACRES <= 2 | drought_bu$NO_TREE == 1)$NO_TREE)
sum(na.omit(drought_bu$NO_TREE))

# Crop drought data to extent of Ramirez data 
# drought <- crop(drought, extent(CR_mort)) # *****commented out this step for running on the entire drought data set*****


## Create table of dia -> biomass parameters based on Jenkins paper - for now only broken down by broad genus category, but I could do it by individual species later if we want
## Source: J. C. Jenkins, D. C. Chojnacky, L. S. Heath, and R. A. Birdsey, "National-scale biomass estimators for United States tree species," For. Sci., vol. 49, no. 1, pp. 12-35, 2003.
## biomass = exp(B0 + B1*ln(dbh))
types <- c("Cedar", "Dougfir", "Fir", "Pine", "Spruce")
B0 <- as.numeric(c(-2.0336, -2.2304, -2.5384, -2.5356, -2.0773))
B1 <- as.numeric(c(2.2592, 2.4435, 2.4814, 2.4349, 2.3323))
BM_eqns <- cbind(types, B0, B1)

Cedars <- c("CADE27", "THPL", "CHLA", "CHNO") # all have been checked for genus on plants.usda.gov
Dougfirs <- c("PSMA", "PSME") # all have been checked for genus plants.usda.gov
Firs <- c("ABAM", "ABBR", "ABGRC", "ABLA", "ABPRSH", "TSHE", "TSME")
Pines <- c("PIAL", "PIAR", "PIAT", "PIBA", "PICO", "PICO3", "PIFL2", "PIJE", "PILA", "PILO", "PIMO", "PIMO3", "PIMU", "PIPO", "PIRA2", "PISA2") # all have been checked for genus plants.usda.gov
Spruces <- c("PIEN", "PISI") # all have been checked for genus plants.usda.gov

### COMBINE LEMMA AND POLYGON DATA

ploop <- function(start, finish) {
  result.lemma.p <- data.frame()
  pb <- winProgressBar(title="Progress", min=start, max=finish, initial=0, label = "0% done")
  for (i in start:finish) { 
    info <- sprintf("%d%% done", round((i/finish)*100))
    setWinProgressBar(pb, value = i, label = info)
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
    if (is.na(mat[1,1])) {
      next
    }
    mat2 <- as.data.frame(tab[[1]]/s) # gives fraction of polygon occupied by each plot type. Adds up to 1 for each polygon.
    mat2 <- merge(mat, mat2, by="Var1")
    # extract attribute information from LEMMA for each plot number contained in the polygon:
    L.in.mat <- subset(LEMMA@data@attributes[[1]], LEMMA@data@attributes[[1]][,"ID"] %in% mat[,1])[,c("ID","BAC_GE_3","BPHC_GE_3_CRM","TPHC_GE_3","QMDC_DOM","CONPLBA","TREEPLBA")]
    # SKIP POLYGONS WITH NO CORRESPONDING RASTER DATA:
    if (is.na(L.in.mat[1,1])) {
      next
    }
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
    result.lemma.p <- rbind(final, result.lemma.p, make.row.names = T)
  }
  key <- seq(1, nrow(result.lemma.p)) # Create a key for each pixel (row)
  result.lemma.p <- cbind(key, result.lemma.p)
  names(result.lemma.p)[names(result.lemma.p)=="V1"] <- "x"
  names(result.lemma.p)[names(result.lemma.p)=="V2"] <- "y"
  names(result.lemma.p)[names(result.lemma.p)=="V3"] <- "D_CONBM_kg"
  names(result.lemma.p)[names(result.lemma.p)=="V4"] <- "relNO"
  names(result.lemma.p)[names(result.lemma.p)=="V5"] <- "relBA"
  names(result.lemma.p)[names(result.lemma.p)=="V6"] <- "PlotID"
  close(pb)
  return(result.lemma.p)
}


# Ten polygon test
strt<-Sys.time()
cheese10 <- ploop(1,10)
print(Sys.time()-strt)
# 6.45 seconds

# Full extent of CR 
strt<-Sys.time()
result.p <- ploop(1, nrow(drought))
print(Sys.time()-strt)
# 1.54 hours

# Take out nonsensical results
hist(result.p$D_CONBM_kg, xlim = c(-10000, 70000), breaks = 100)
result.p <- subset(result.p, result.p$D_CONBM_kg > 0 & result.p$D_CONBM_kg < 60000)

# CLEAR EVERYTHING IN LOOPS
remove(cell, final, L.in.mat, mat, mat2, merge)
remove(BM_eqns, BA, BM, clip1, clip2, CONPL)
remove(num, numcon, s, ext, i, tab, single, THA, TREEPL, TREEPLR, QMDC_DOM, Av_BM_TR, CONBM_kgha, CONBM_kg_pol, relNO, NO)
remove(pcoords, pmerge, CON_THA, key, NO_TREE, Pol.ID, Pol.NO_TREE, Pol.Pixels, Pol.Shap_Ar, Pol.x, Pol.y, RPT_YR, TOT_CONBM_kgha, tot_NO, totBA, i)
remove(All_CONBM_kgha, All_Pol_CONBM_kgha, D_Pol_CONBM_kg, key)

# Write and re-open results
setwd("~/Documents/Box Sync/EPIC-Biomass/R Results/")
write.csv(result.p, file = "Biomass_Pixels_LEMMA_sept22.csv", row.names=F)
result.p <- read.csv("Trial_Biomass_Pixels_LEMMA_sept22.csv")

# Test write and re-open results
write.csv(result.p, file = "LEMMA_TEST_CRMORT_FORLOOP.csv", row.names=F)
result.forloop <- read.csv("LEMMA_TEST_CRMORT_FORLOOP.csv")

## REMINDER: EVERTHING IS IN SRID EPSG 5070
