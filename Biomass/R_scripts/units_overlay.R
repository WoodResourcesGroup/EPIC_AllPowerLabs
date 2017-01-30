library(rgdal)
library(raster)

### Open FS units

# First all forests to give a CA overview map
if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
}
FS_CA <- readOGR(dsn="tempdir",layer = "FS_CA") 
plot(FS_CA)

# Then forests of interest
FS <- readOGR(dsn="tempdir",layer = "FS") 
plot(FS, add= T, col="red")

### Open Mountain Home layer
Mtn_hm <- readOGR(dsn = "Mtn_home", layer = "Mtn_home_new")
Mtn_hm <- spTransform(Mtn_hm, crs(FS_CA))

### Open State Park layer
st_p <- readOGR(dsn = "State_Parks", layer = "two_parks")
st_p<- spTransform(st_p, crs(FS_CA))

### Open National Park Layers
sequ <- readOGR(dsn = "Boundary_SequoiaNP_20100209", layer = "Boundary_SequoiaNP_20100209")
sequ <- spTransform(sequ, crs(FS_CA))
kc <- readOGR(dsn = "Boundary_KingsNP_20100209", layer = "Boundary_KingsNP_20100209")
kc <- spTransform(kc, crs(FS_CA))
lnp <- readOGR(dsn = "tempdir", layer = "LNP")
lnp <- spTransform(lnp, crs(FS_CA))

### Plot them
plot(FS_CA)
plot(FS, add= T, col="purple")
plot(Mtn_hm, add=T, col="red", border="red")
plot(st_p, add=T, col="deeppink2", border="deeppink2")
plot(sequ, add=T, col="green") 
plot(kc, add=T, col="green")
plot(lnp, add=T, col="orange")

### Open Results


### Crop and mask results once for each unit spdf

library(sp)
results_1215_MH <- crop(results_1215, extent(MH))
results_1215_MH <- spTransform(results_1215_MH, crs(Mtn_hm))

results_1215_FS <- crop(results_1215, extent(FS))

results_1215_kc <- crop(results_1215, extent(kc))
results_1215_lnp <- crop(results_1215, extent(lnp))

### Trying with gIntersect

# First find which points in results fall within MH
MH.intersect <- gIntersection(Mtn_hm, results_1215_MH, byid=T)
plot(Mtn_hm, add=T, border="orange")
MH.pts.intersect <- strsplit(dimnames(MH.intersect@coords)[[1]], " ")
MH.pts.intersect.id <- as.numeric(sapply(MH.pts.intersect,"[[",2))
MH.pts.extract <- results_1215_MH[MH.pts.intersect.id, ]
results_1215_MH_ex <- subset(results_1215_MH, results_1215_MH$key %in% MH.pts.intersect.id)

plot(results_1215_MH_ex)
plot(Mtn_hm, add=T, border="orange")

# Repeat for st_p
results_1215_SP <- crop(results_1215, extent(st_p))
results_1215_SP <- spTransform(results_1215_SP, crs(st_p))

### Divide into the two parks
CSP <- st_p[1,]
ESP <- st_p[2,]


