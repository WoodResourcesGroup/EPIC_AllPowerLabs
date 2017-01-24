library(rgdal)
library(raster)

if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
}

drought <- readOGR(dsn = "DroughtTreeMortality.gdb", layer = "DroughtTreeMortality") 
#plot(drought, add = TRUE) # only plot if necessary; takes a long ass time
#crs(drought)
drought <- spTransform(drought, crs(LEMMA)) #change it to CRS of Gonzalez and LEMMA data - this takes a while
#crs(drought)
writeOGR(obj=drought, dsn="tempdir",layer = "drought", driver="ESRI Shapefile")

### TRANSFORMING 2016 DROUGHT DATA ON TURBO

if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Battles Lab/Box Sync/EPIC-Biomass/GIS Data/LEMMA_gnn_sppsz_2014_08_28/")
  } else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/LEMMA_gnn_sppsz_2014_08_28/")
 }

LEMMA <- raster("LEMMA.gri")

if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Battles Lab/Box Sync/EPIC-Biomass/GIS Data/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
}

drought16 <- readOGR(dsn = "ADS_2016", layer = "ADS_2016")
drought16 <- spTransform(drought16, crs(LEMMA)) #change it to CRS of Gonzalez and LEMMA data - this takes a while
crs(drought16)
writeOGR(obj=drought16, dsn="tempdir",layer = "drought16", driver="ESRI Shapefile")
