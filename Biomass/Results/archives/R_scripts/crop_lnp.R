EPIC <- "C:/Users/Battles Lab/Box Sync/EPIC-Biomass" # Define where your EPIC-BIOMASS folder is located in Box Sync
#EPIC <- "C:/Users/Carmen/Box Sync/EPIC-Biomass"

library(rgdal)
library(raster)
library(rgeos)

setwd(paste(EPIC, "/GIS Data", sep=""))

nat_parks <- readOGR(dsn = "Nat_Parks", layer = "nps_boundary")

LNP <- subset(nat_parks, nat_parks@data$PARKNAME=="Lassen Volcanic")
plot(LNP)

setwd(paste(EPIC, "/GIS Data/tempdir", sep=""))
save(LNP, file="LNP.Rdata")
