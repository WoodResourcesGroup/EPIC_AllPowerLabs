library(rgdal)
library(raster)
library(rgeos)
library(stringr)
library(dplyr)
library(viridis)

### GONZALEZ DATA
setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/Gonzalez Data")
PG_biomass <- raster("California_above_biomass_2010.tif")
PG_analysis <- raster("California biomass 2010 analysis.tif")
library(viridis)
# plot(PG_biomass) #when plotted in Arc, there are large areas of the Sierra with ~600 Mg/ha, while the carbon figure in the paper is almost all below 
# 300 Mg/ha, so this is definitely biomass in Mg/ha, not carbon
# plot(PG_analysis)
crs(PG_biomass)
crs(PG_analysis) #EPSG 5070, same as LEMMA, in part because of what's in the PDF file in Gonzalez Data folder
extent(PG_biomass)

### LEMMA DATA
setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/LEMMA_gnn_sppsz_2014_08_28/")
#LEMMA <- raster("mr200_2012")
#crs(LEMMA) # 5070. based on what this guys says: http://gis.stackexchange.com/questions/128190/convert-srtext-to-proj4text
#plot(LEMMA) # This is just plotting alias for FCID, forest class identification number, as described here: http://lemma.forestry.oregonstate.edu/data/structure-maps
#extent(LEMMA)
#LEMMA <- crop(LEMMA, extent(-2362845, -1627605, 1232145, 2456985))
#writeRaster(LEMMA, filename = "LEMMA.tif", format = "GTiff", overwrite = TRUE) # save a backup
LEMMA <- raster("LEMMA.gri")

### DROUGHT MORTALITY POLYGONS
setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/")
drought.test <- readOGR(dsn = "DroughtTreeMortality.gdb", layer = "DroughtTreeMortality") 
# plot(drought, add = TRUE) # only plot if necessary; takes a long ass time
# crs(drought)
# drought <- spTransform(drought, crs(LEMMA)) #change it to CRS of Gonzalez and LEMMA data - this takes a while
# crs(drought)
# writeOGR(obj=drought, dsn="tempdir",layer = "drought", driver="ESRI Shapefile")
drought <- readOGR("tempdir", "drought")
drought_bu <- drought # backup so that I don't need to re-read if I accidentally override drought
# take out areas not in high hazard zones
highhaz <- readOGR(dsn = "HighHazardZones.gdb", layer = "HHZ_Tier2")
crs(highhaz)
highhaz <- spTransform(highhaz, crs(drought))
# test intersection
drought.test <- gIntersection(drought.s, highhaz)
plot(highhaz, ext = extent(drought.s), col='blue')
plot(drought.test, col='red', add=T)
plot(highhaz, add=T, col='blue')
plot(drought.s, add=T)
drought <- drought.test

# narrow drought down to large-ish polygons
drought <- 

### RAMIREZ DATA
setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/Ramirez Data/Copy of ENVI_FR.1754x4468x15x1000/")
GDALinfo("FR_2016.01.13_167.bsq")
CR_mort <- raster("FR_2016.01.13_167.bsq")
crs(CR_mort)
# plot(CR_mort)
# CR_mort <- projectRaster(CR_mort, crs=crs(drought))
setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/tempdir")
#writeRaster(CR_mort, filename = "CR_mort.tif", format = "GTiff", overwrite = TRUE) # save a backup 
CR_mort <- raster("CR_mort.tif")

### Find biomass for drought mortality polygons using Gonzalez data 

### Gonzalez data

# Try it on extent of Ramirez data so that I can compare the data sources?
drought.s <- crop(drought, extent(CR_mort))
plot(drought.s, add=T)
# These don't look like they overlap that well. NEED TO CHECK PROJECTION CONVERSIONS

result <- data.frame()
for (i in 1:nrow(drought)) {
  single <- drought.s[i,]
  clip1 <- crop(PG_biomass, extent(single))
  clip2 <- mask(clip1, single)
  ext <- extract(clip2, single) # extracts biomass values from the raster 
  ave.biomass <- mean(ext[[1]])
  final <- cbind(single@data$RPT_YR,single@data$TPA,single@data$NO_TREE,single@data$FOR_TYP,single@data$Shap_Ar,ave.biomass, gCentroid(single)@coords) 
  final <- as.data.frame(final)
  names(final)[names(final)=="V1"] <- "RPT_YR"
  names(final)[names(final)=="V2"] <- "TPA"
  names(final)[names(final)=="V3"] <- "NO_TREE"
  names(final)[names(final)=="V4"] <- "FOR_TYP"
  names(final)[names(final)=="V5"] <- "Shap_Ar"
  names(final)[names(final)=="x"] <- "Cent.x"
  names(final)[names(final)=="y"] <- "Cent.y"  
  result <- rbind(final, result)
}
head(result)
write.csv(result, file = "Trial_Biomass_Polygons.csv", row.names=F)
result.trial <- read.csv("Trial_Biomass_Polygons.csv")

###  LEMMA data 

result.lemma <- data.frame()
for (i in 1:nrow(drought.s)) {
  single <- drought.s[i,]
  clip1 <- crop(LEMMA, extent(single))
  clip2 <- mask(clip1, single)
  ext <- extract(clip2, single) # extracts data from the raster
  tab <- lapply(ext, table) # creates a table that counts how many of each raster value there are 
  s <- sum(tab[[1]]) # Counts raster cells in clip2 - This is different from length(clip2tg) because it doesn't include NAs
  mat <- as.data.frame(tab)
  mat2 <- as.data.frame(tab[[1]]/s) # Gives fraction of polygon occupied by each plot type. Adds up to 1 for each polygon.
  L.in.mat <- subset(LEMMA@data@attributes[[1]], LEMMA@data@attributes[[1]][,"ID"] %in% mat[,1])[,c("ID","BPHC_GE_3_CRM","TPHC_GE_3")]
  merge <- merge(L.in.mat, mat2, by.y = "Var1", by.x = "ID")
  BM <- sum(merge$BPHC_GE_3_CRM*merge$Freq)
  THA <- sum(merge$TPHC_GE_3*merge$Freq)
  final <- cbind(single@data$RPT_YR,single@data$TPA,single@data$NO_TREE,single@data$FOR_TYP,single@data$Shap_Ar,BM, THA,gCentroid(single)@coords)
  final <- as.data.frame(final)
  names(final)[names(final)=="V1"] <- "RPT_YR"
  names(final)[names(final)=="V2"] <- "TPA"
  names(final)[names(final)=="V3"] <- "NO_TREE"
  names(final)[names(final)=="V4"] <- "FOR_TYP"
  names(final)[names(final)=="V5"] <- "Shap_Ar"
  names(final)[names(final)=="x"] <- "Cent.x"
  names(final)[names(final)=="y"] <- "Cent.y"  
  result.lemma <- rbind(final, result.lemma)
}
result.lemma$est.tot.trees <- ((result.lemma$Shap_Ar)/1000)*result.lemma$THA
result.lemma$est.perc.dead <- result.lemma$NO_TREE/result.lemma$est.tot.trees
result.lemma$est.dead.BM <- result.lemma$est.perc.dead * result.lemma$BM
head(result.lemma)


## NOW FIGURE OUT HOW TO COMBINE THIS WITH THE MATT TABLE - VLOOKUP STYLE


### TESTING ###

# Crop raster to single drought polygon and visualize to test the loop
singlet <- drought[1,]
clip1tG <- crop(PG_biomass, extent(singlet))
plot(clip1tG)
plot(singlet, add=T)
clip2tG <- mask(clip1tG, singlet)
plot(clip2tG, col=viridis(n=6))
plot(singlet, add=T) 
# Problem: when I do this with several different polygons, I find that the small polygons have only one or two raster pixels, and they're distorted by
# angled polygon sides. So we need to only use drought polygons of a certain size. FOr now, I set this to 5 acres.

# Calculate centroids
singlet.c <- gCentroid(singlet)
plot(gCentroid(singlet), add=T)
singlet.c@coords
gCentroid(singlet)@coords