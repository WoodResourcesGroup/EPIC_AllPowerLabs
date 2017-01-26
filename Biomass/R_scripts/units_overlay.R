library(rgdal)
library(raster)

### Open FS units

# First all forests to give a CA overview map
if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
}

FS <- readOGR(dsn="tempdir",layer = "FS_CA") 
plot(FS_CA)

# Then forests of interest

FS <- readOGR(dsn="tempdir",layer = "FS") 
plot(FS, add= T, col="red")

### Open Mountain Home layer

Mtn_hm <- readOGR(dsn = "Mtn_home", layer = "Mtn_home_new")
Mtn_hm <- spTransform(Mtn_hm, crs(FS_CA))
plot(Mtn_hm, add=T, col="purple", border="purple")

if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/State_Parks")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/State_Parks")
}

### Open State Park layer
st_p <- readOGR(dsn = "State_Parks", layer = "two_parks")
st_p<- spTransform(st_p, crs(FS_CA))
plot(st_p, add=T, col="blue")

### Open National Park Layers

if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
}

sequ <- readOGR(dsn = "Boundary_SequoiaNP_20100209", layer = "Boundary_SequoiaNP_20100209")
sequ <- spTransform(sequ, crs(FS_CA))
plot(sequ, add=T, col="green") 

kc <- readOGR(dsn = "Boundary_KingsNP_20100209", layer = "Boundary_KingsNP_20100209")
kc <- spTransform(kc, crs(FS_CA))
plot(kc, add=T, col="green")

### Just plots
plot(FS_CA)
plot(FS, add= T, col="purple")
plot(Mtn_hm, add=T, col="red", border="red")
plot(st_p, add=T, col="deeppink2", border="deeppink2")
plot(sequ, add=T, col="green") 
plot(kc, add=T, col="green")

### Open Results



### Crop Results