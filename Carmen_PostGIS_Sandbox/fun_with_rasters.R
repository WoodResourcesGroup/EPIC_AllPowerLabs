<<<<<<< HEAD
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
# drought <- readOGR(dsn = "DroughtTreeMortality.gdb", layer = "DroughtTreeMortality") 
# plot(drought, add = TRUE) # only plot if necessary; takes a long ass time
# crs(drought)
# drought <- spTransform(drought, crs(LEMMA)) #change it to CRS of Gonzalez and LEMMA data - this takes a while
# crs(drought)
# writeOGR(obj=drought, dsn="tempdir",layer = "drought", driver="ESRI Shapefile")
drought <- readOGR("tempdir", "drought")
drought_bu <- drought # backup so that I don't need to re-read if I accidentally override drought

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
for (i in 1:nrow(drought.s)) {
  single <- drought.s[i,]
  clip1 <- crop(PG_biomass, extent(single))
  clip2 <- mask(clip1, single)
  ext <- extract(clip2, single) # extracts biomass values from the raster 
  tab <- lapply(ext, table)
  s <- sum(tab[[1]]) # This is different from length(clip2tg) because it doesn't include NAs
  mat <- as.data.frame(tab)
  mat2 <- as.data.frame(tab[[1]]/s)
  ave.biomass <- sum(ext[[1]])/s
  final <- cbind(single@data$RPT_YR,single@data$TPA,single@data$NO_TREE,single@data$FOR_TYP,single@data$Shap_Ar,ave.biomass, gCentroid(single)@coords) #need to add to this
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

###  LEMMA data 

result <- data.frame()
for (i in 2) { #for (i in nrow(drought)) 
  single <- drought[i,]
  clip1 <- crop(LEMMA, extent(single))
  clip2 <- mask(clip1, single)
  ext <- extract(clip2, single) # extracts data from the raster
  tab <- lapply(ext, table)
  s <- sum(tab[[1]])
  mat <- as.data.frame(tab)
  mat2 <- as.data.frame(tab[[1]]/s)
  final <- cbind(single@data$RPT_YR,single@data$TPA1,single@data$NO_TREES1,single@data$FOR_TYPE1,single@data$Shape_Area,mat,mat2$Freq) #need to add to this
  result <- rbind(final, result)
}

# test each step before running test loop:
singlet <- drought[1,]
clip1t <- crop(LEMMA, extent(singlet))
plot(clip1t)
plot(singlet, add=T)
clip2t <- mask(clip1t, singlet)
plot(clip2t)
plot(singlet, add=T)

extt <- extract(clip2t, singlet)
tabt <- lapply(extt, table)
st <- sum(tabt[[1]])
matt <- as.data.frame(tabt)
mat2t <- as.data.frame(tabt[[1]]/st)
finalt <- cbind(singlet@data$RPT_YR,singlet@data$TPA1,singlet@data$NO_TREES1,singlet@data$FOR_TYPE1,matt,mat2t$Freq)
resultt <- data.frame()
resultt <- rbind(finalt, resultt) # Problem: this doesn't retain spatial data, only attributes

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