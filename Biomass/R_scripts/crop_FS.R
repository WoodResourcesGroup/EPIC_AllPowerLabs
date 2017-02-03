EPIC <- "C:/Users/Battles Lab/Box Sync/EPIC-Biomass" # Define where your EPIC-BIOMASS folder is located in Box Sync
#EPIC <- "C:/Users/Carmen/Box Sync/EPIC-Biomass"

library(rgdal)
library(raster)
library(rgeos)

setwd(paste(EPIC, "/GIS Data", sep=""))
FS_Units <- readOGR(dsn = "FS_Units", layer = "FS_Units") 
plot(FS_Units)

### SETWD based on whether it's Carmen's computer or Jose's computer)
setwd(paste(EPIC, "/GIS Data/LEMMA_gnn_sppsz_2014_08_28/", sep=""))
### Open GNN LEMMA data (see script crop_LEMMA.R for where LEMMA.gri comes from)
LEMMA <- raster("LEMMA.gri")
FS_Units <- spTransform(FS_Units, crs(LEMMA)) 

FS_CA <- crop(FS_Units, extent(-2362845, -1627605, 1232145, 2456985)) # Crop to only CA
plot(FS_CA)

### Save
setwd(paste(EPIC, "/GIS Data/tempdir", sep=""))
save(FS_CA, file="FS_CA.Rdata")

as.data.frame(FS_CA@data$FORESTNAME)
FS <- FS_CA[c(FS_CA@data$FORESTNAME %in% c("Eldorado National Forest", "Sierra National Forest")),]
plot(FS)

save(FS, file="FS.Rdata")

FS_LTMU <- subset(FS_Units, FS_Units$FORESTNAME=="Lake Tahoe Basin Management Unit")
plot(FS_LTMU)
save(FS_LTMU, file="FS_LTMU.Rdata")
