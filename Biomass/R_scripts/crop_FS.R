library(rgdal)
library(raster)
library(rgeos)

if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
}

FS <- readOGR(dsn = "FS_Units", layer = "FS_Units") 
plot(FS)


### SETWD based on whether it's Carmen's computer or Jose's computer)
if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/LEMMA_gnn_sppsz_2014_08_28/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/LEMMA_gnn_sppsz_2014_08_28/")
}

### Open GNN LEMMA data (see script crop_LEMMA.R for where LEMMA.gri comes from)
LEMMA <- raster("LEMMA.gri")
FS <- spTransform(FS, crs(LEMMA)) 

FS <- crop(FS, extent(-2362845, -1627605, 1232145, 2456985)) # Crop to only CA
plot(FS)

as.data.frame(FS@data$FORESTNAME)
FS <- FS[c(FS@data$FORESTNAME %in% c("Eldorado National Forest", "Sierra National Forest")),]
plot(FS)

if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
}

writeOGR(obj=FS, dsn="tempdir",layer = "FS", driver="ESRI Shapefile")


