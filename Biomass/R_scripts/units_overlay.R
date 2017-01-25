library(rgdal)
library(raster)

### Open FS units

if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
}


FS <- readOGR(dsn="tempdir",layer = "FS") 
plot(FS)

### Open Mountain Home layer

Mtn_hm <- readOGR(dsn = "Mtn_home", layer = "Mtn_home_new")
plot(Mtn_hm, add=T)


if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/State_Parks")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/State_Parks")
}


### Open State Park layer
st_p <- readOGR(dsn = "CalStPrks_Geodata_Facilities_Public_2016_04.gdb", layer = "CalStPrks_Geodata_Facilities_Public_2016_04")

### Open National Park Layer

### Open Results

### Crop Results