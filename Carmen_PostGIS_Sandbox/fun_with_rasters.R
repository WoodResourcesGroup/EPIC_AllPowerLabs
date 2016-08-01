library(rgdal)
library(sp)
library(raster)
setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/Gonzalez Data")
PG_CA_biomass <- raster("California_above_biomass_2010.tif")
crs(PG_CA_biomass)

setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/LEMMA_gnn_sppsz_2014_08_28/")
LEMMA <- raster("mr200_2012")
crs(LEMMA)

EPSG <- make_EPSG()
maybe <- subset(EPSG, code == 5070)

