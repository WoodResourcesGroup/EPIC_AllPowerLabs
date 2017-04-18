#EPIC <- "C:/Users/Battles Lab/Box Sync/EPIC-Biomass" # Define where your EPIC-BIOMASS folder is located in Box Sync
EPIC <- "C:/Users/Carmen/Box Sync/EPIC-Biomass"

library(rgdal)
library(raster)

### Open FS units

# First national forests
setwd(paste(EPIC, "/GIS Data/tempdir", sep=""))
load(file="FS.Rdata")
# Then LTMU
load(file="FS_LTMU.Rdata")

### Open Mountain Home layer
setwd(paste(EPIC, "/GIS Data", sep=""))
Mtn_hm <- readOGR(dsn = "Mtn_home", layer = "Mtn_home_new")
Mtn_hm <- spTransform(Mtn_hm, crs(FS))

### Open State Park layer
st_p <- readOGR(dsn = "State_Parks", layer = "two_parks")
st_p<- spTransform(st_p, crs(FS))

### Open National Park Layers
sequ <- readOGR(dsn = "Boundary_SequoiaNP_20100209", layer = "Boundary_SequoiaNP_20100209")
sequ <- spTransform(sequ, crs(FS))
kc <- readOGR(dsn = "Boundary_KingsNP_20100209", layer = "Boundary_KingsNP_20100209")

KCNP <- spTransform(kc, crs(FS))
setwd(paste(EPIC, "/GIS Data/units", sep=""))
save(KCNP, file="KCNP.Rdata")

setwd(paste(EPIC, "/GIS Data/tempdir", sep=""))
load(file="LNP.Rdata")
LNP <- spTransform(LNP, crs(FS))

### Merge units
units <- union(Mtn_hm, st_p)
units <- union(units, sequ)
units <- union(units, FS)
units <- union(units, LNP)
units$UNIT <- c(rep("MH",6), "CSP", "ESP", "SQNP", "SNF", "ENF", "LNP")
# This vector of units does not include KCNP or LTMU

### Check them out
plot(units, col="green")
plot(FS_LTMU, add=T, col="orange")
plot(kc, add=T, col="red")

setwd(paste(EPIC, "/GIS Data/units", sep=""))
writeOGR(units, dsn="units_for_jose",layer="all_but_two", driver="ESRI Shapefile")
save(units, file="units.Rdata")
writeOGR(FS_LTMU, dsn="units_for_jose", layer = "LTMU", driver="ESRI Shapefile")
writeOGR(kc, dsn="units_for_jose",layer="KCNP",driver="ESRI Shapefile")
