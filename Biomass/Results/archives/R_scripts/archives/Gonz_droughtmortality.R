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

### DROUGHT MORTALITY POLYGONS
setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/")
#drought <- readOGR(dsn = "DroughtTreeMortality.gdb", layer = "DroughtTreeMortality") 
# plot(drought, add = TRUE) # only plot if necessary; takes a long ass time
# crs(drought)
# drought <- spTransform(drought, crs(LEMMA)) #change it to CRS of Gonzalez and LEMMA data - this takes a while
# crs(drought)
# writeOGR(obj=drought, dsn="tempdir",layer = "drought", driver="ESRI Shapefile")
drought <- readOGR("tempdir", "drought")
drought_bu <- drought # backup so that I don't need to re-read if I accidentally override drought
# take out areas not in high hazard zones
#highhaz <- readOGR(dsn = "HighHazardZones.gdb", layer = "HHZ_Tier2")
#crs(highhaz)
#highhaz <- spTransform(highhaz, crs(drought))

#drought.test <- gIntersection(drought.s, highhaz)
#drought.s.gIntersection <- drought.test
# Intersection is too hard for now - ask Jose to do it on QGIS

# narrow drought down to large-ish polygons
drought <- subset(drought, drought$ACRES > 2)

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
drought.s <- subset(drought.s, drought.s$ACRES >2)
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
