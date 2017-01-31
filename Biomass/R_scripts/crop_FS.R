library(rgdal)
library(raster)
library(rgeos)

if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
}

FS_Units <- readOGR(dsn = "FS_Units", layer = "FS_Units") 
plot(FS_Units)


### SETWD based on whether it's Carmen's computer or Jose's computer)
if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/LEMMA_gnn_sppsz_2014_08_28/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/LEMMA_gnn_sppsz_2014_08_28/")
}

### Open GNN LEMMA data (see script crop_LEMMA.R for where LEMMA.gri comes from)
LEMMA <- raster("LEMMA.gri")
FS_Units <- spTransform(FS_Units, crs(LEMMA)) 

FS_CA <- crop(FS_Units, extent(-2362845, -1627605, 1232145, 2456985)) # Crop to only CA
plot(FS_CA)

### Save


if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
}

writeOGR(obj=FS_CA, dsn="tempdir",layer = "FS_CA", driver="ESRI Shapefile", overwrite_layer = TRUE)

as.data.frame(FS_CA@data$FORESTNAME)
FS <- FS_CA[c(FS_CA@data$FORESTNAME %in% c("Eldorado National Forest", "Sierra National Forest")),]
plot(FS)

if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
}

writeOGR(obj=FS, dsn="tempdir",layer = "FS", driver="ESRI Shapefile", overwrite_layer = TRUE)

FS_LTMU <- subset(FS_Units, FS_Units$FORESTNAME=="Lake Tahoe Basin Management Unit")
plot(FS_LTMU)
writeOGR(obj=FS_LTMU, dsn="tempdir",layer = "FS_LTMU", driver="ESRI Shapefile", overwrite_layer = TRUE)

