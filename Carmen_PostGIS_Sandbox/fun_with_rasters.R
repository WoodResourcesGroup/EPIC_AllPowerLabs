library(rgdal)
library(sp)
library(raster)
library(rgeos)
library(stringr)
library(dplyr)

### GONZALEZ DATA
setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/Gonzalez Data")
PG_biomass <- raster("California_above_biomass_2010.tif")
PG_analysis <- raster("California biomass 2010 analysis.tif")
plot(PG_biomass)
plot(PG_analysis)
crs(PG_biomass)
crs(PG_analysis)
extent(PG_biomass)

### LEMMA DATA
setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/LEMMA_gnn_sppsz_2014_08_28/")
LEMMA <- raster("mr200_2012")
crs(LEMMA)
plot(LEMMA)
extent(LEMMA)
LEMMA <- crop(LEMMA, extent(extent(PG_biomass)))


### DROUGHT MORTALITY POLYGONS
setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/")
drought <- readOGR(dsn = "DroughtTreeMortality.gdb", layer = "DroughtTreeMortality")
plot(drought)
crs(drought)

### RAMIREZ DATA
setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/Ramirez Data/Copy of ENVI_FR.1754x4468x15x1000/")
CR_mort <- raster("FR_2016.01.13_167.bsq")
crs(CR_mort)
plot(CR_mort)
