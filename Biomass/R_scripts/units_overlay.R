library(rgdal)
library(raster)

### Open FS units

# First national forests
FS <- readOGR(dsn="tempdir",layer = "FS") 

# Then LTMU
if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
}
FS_LTMU <- readOGR(dsn="tempdir",layer = "FS_LTMU") 
FS_LTMU <- spTransform(FS_LTMU, crs(FS))

### Open Mountain Home layer
Mtn_hm <- readOGR(dsn = "Mtn_home", layer = "Mtn_home_new")
Mtn_hm <- spTransform(Mtn_hm, crs(FS))

### Open State Park layer
st_p <- readOGR(dsn = "State_Parks", layer = "two_parks")
st_p<- spTransform(st_p, crs(FS))

### Open National Park Layers
sequ <- readOGR(dsn = "Boundary_SequoiaNP_20100209", layer = "Boundary_SequoiaNP_20100209")
sequ <- spTransform(sequ, crs(FS))
kc <- readOGR(dsn = "Boundary_KingsNP_20100209", layer = "Boundary_KingsNP_20100209")
kc <- spTransform(kc, crs(FS))
lnp <- readOGR(dsn = "tempdir", layer = "LNP")
lnp <- spTransform(lnp, crs(FS))

### Merge units
units <- union(Mtn_hm, st_p)
units <- union(units, sequ)
units <- union(units, FS)
units <- union(units, lnp)
units$UNIT <- c(rep("MH",6), "CSP", "ESP", "SQNP", "SNF", "ENF", "LNP")
# This vector of units does not include KCNP or LTMU

### Check them out
plot(units, col="green")
plot(FS_LTMU, add=T, col="orange")
plot(kc, add=T, col="red")

writeOGR(units, dsn="units", layer="units_nokc", overwrite_layer = T, driver = "ESRI Shapefile")
