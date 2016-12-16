install.packages("rgdal")
install.packages("raster") 
install.packages("rgeos") 
install.packages("stringr")
install.packages("viridis")
install.packages("parallel") 

library(rgdal) 
library(raster) 
library(rgeos) 
library(stringr) 
library(viridis) 
library(parallel) 

options(digits = 5)

### SETWD based on whether it's Carmen's computer or Jose's computer)
if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/LEMMA_gnn_sppsz_2014_08_28/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/LEMMA_gnn_sppsz_2014_08_28/")
}

### Open GNN LEMMA data (see script crop_LEMMA.R for where LEMMA.gri comes from)
LEMMA <- raster("LEMMA.gri")

### OPEN DROUGHT MORTALITY POLYGONS (see script transform_ADS.R for where "drought" comes from)
if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
}
drought <- readOGR("tempdir", "drought")
drought_bu <- drought # backup so that I don't need to re-read if I accidentally override drought

### RAMIREZ DATA (see script transform_CRmort.R for where "CR_mort.tif" comes from)
if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/tempdir/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/tempdir")
}
CR_mort <- raster("CR_mort.tif")

### Narrow drought down to large-ish polygons and those with more than one tree
# might want to change these later
drought <- subset(drought, drought$ACRES > 2 & drought$NO_TREE > 1)
## print how much area this excludes: ~30,000 ACRES (out of ~4,000,000)
sum(subset(drought_bu, drought_bu$ACRES <= 2 | drought_bu$NO_TREE == 1)$ACRES)
sum(drought_bu$ACRES)
## print how many trees this excludes: ~90,000 trees (out of ~33,000,000)
sum(subset(drought_bu, drought_bu$ACRES <= 2 | drought_bu$NO_TREE == 1)$NO_TREE)
sum(na.omit(drought_bu$NO_TREE))

### Crop drought data to extent of Ramirez data 
# drought <- crop(drought, extent(CR_mort)) # *****commented out this step for running on the entire drought data set*****

### Identify species in LEMMA
spp <- LEMMA@data@attributes[[1]][,"TREEPLBA"]
spp.names <- sort(unique(spp))

### Group conifers by genus
Cedars_Larch <- c("CADE27", "THPL", "CHLA", "CHNO", "LALY", "LAOC", "SEGI2", "SESE3") # all have been checked for genus on plants.usda.gov
Dougfirs <- c("PSMA", "PSME") # all have been checked for genus plants.usda.gov
Firs <- c("ABAM", "ABBR", "ABGRC", "ABLA", "ABPRSH", "TSHE", "TSME")
Pines <- c("PIAL", "PIAR", "PIAT", "PIBA", "PICO", "PICO3", "PIFL2", "PIJE", "PILA", "PILO", "PIMO", "PIMO3", "PIMU", "PIPO", "PIRA2", "PISA2") # all have been checked for genus plants.usda.gov
Spruces <- c("PIEN", "PISI") # all have been checked for genus plants.usda.gov

### Group hardwoods and junipers by Jenkins species group
hardwood.names <- subset(spp.names, !spp.names %in% c(Cedars_Larch, Dougfirs, Firs, Pines, Spruces))
mh <- c("JUHI", "AECA", "ARME", "CHCH7", "CONU4", "FRLA", "LIDE3", "PLRA", "PRVI", "UMCA")
wo <- c("JUCA7", "JUOC", "ACGL", "CELE3", "CUSA3", "JUOS", "OLTE", "PREM", "PRGLT", "PRPU")
mb <- c("ACMA3", "BEPA", "BEPAC", "")
aa <- c("ALRH2", "ALRU2", "POBAT", "POFR2", "POTR5", "SAAL2", "SALIX", "SANI")
mo <- c("QUAG", "QUDO", "QUEN", "QUERC", "QUGA4", "QUKE", "QULO", "QUWI2", "QUCH2")
remaining <- subset(spp.names, !spp.names %in% c(Cedars_Larch, Dougfirs, Firs, Pines, Spruces, mh, wo, mb, aa, mo))

### Create table of dia -> biomass parameters based on Jenkins paper - for now only broken down by broad genus category, but could do it by individual species later if we want
# Source: J. C. Jenkins, D. C. Chojnacky, L. S. Heath, and R. A. Birdsey, "National-scale biomass estimators for United States tree species," For. Sci., vol. 49, no. 1, pp. 12-35, 2003.
# biomass = exp(B0 + B1*ln(dbh))
types <- c("Cedar", "Dougfir", "Fir", "Pine", "Spruce", "mh", "wo", "mb", "aa", "mo")
B0 <- as.numeric(c(-2.0336, -2.2304, -2.5384, -2.5356, -2.0773, -2.4800, -.7152, -1.9123, -2.2094, -2.0127))
B1 <- as.numeric(c(2.2592, 2.4435, 2.4814, 2.4349, 2.3323, 2.4835, 1.7029, 2.3651, 2.3867, 2.4342))
BM_eqns <- cbind(types, B0, B1)

#* Species groups (SG) include aspen/alder/cottonwood/willow (aa), hard maple/oak/hickory/beech (mo), mixed hardwood (mh), soft maple/birch (mb), cedar/larch (cl), Douglas-fir (df), true fir/hemlock (tf), pine (pi), spruce (sp), and woodland conifer and softwood (wo).

library(doParallel)
library(foreach)
detectCores()
no_cores <- detectCores() - 1
c1 <- makeCluster(no_cores)
registerDoParallel(c1)

########### Find which polygons aren't going to work - these will automatically be left out of the foreach() loop ###########

# start timer
strt<-Sys.time()

inputs = 1:nrow(drought)
no.go <- foreach(i = inputs, .combine = rbind, .packages = c('raster', 'rgeos'), .errorhandling = "stop") %dopar% {
  single <- drought[i,]
  clip1 <- crop(LEMMA, extent(single))
  clip2 <- mask(clip1, single)
  ext <- extract(clip2, single)
  no.pixels <- length(subset(ext[[1]], !is.na(ext[[1]])))
  return(no.pixels)
} 

# end timer
print(Sys.time()-strt)
# 10 min for CR_mort subset of drought

zeros <- subset(no.go, no.go == 0)
zeros <- as.data.frame(zeros)
zero.i <- row.names(zeros)
zero.i <- as.integer(gsub("result.", "", zero.i))

saveRDS(zero.i,file="zero_i.Rdata")
readRDS("zero_i.Rdata")

###################################################################
# start timer
strt<-Sys.time()

# function

inputs = 1:nrow(drought)

result.lemma.p <- foreach(i=inputs, .combine = rbind, .packages = c('raster','rgeos'), .errorhandling="remove") %dopar% {
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
chocolate_CRMORT<- result.lemma.p
remove(result.lemma.p)

# end timer
print(Sys.time()-strt)
###################################################################
# 25 minutes for CRMORT


# Take out nonsensical results
hist(chocolate_CRMORT$D_CONBM_kg, xlim = c(-10000, 70000), breaks = 100)
chocolate_CRMORT <- subset(chocolate_CRMORT, chocolate_CRMORT$D_CONBM_kg > 0 & chocolate_CRMORT$D_CONBM_kg < 60000)

setwd("~/Documents/Box Sync/EPIC-Biomass/R Results/")
write.csv(chocolate_CRMORT, file = "LEMMA_parallel_CRMORT.csv", row.names=F)
result.parallel <- read.csv("LEMMA_parallel_CRMORT.csv")
 