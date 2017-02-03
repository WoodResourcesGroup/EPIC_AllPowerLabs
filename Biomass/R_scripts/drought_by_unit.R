#########################################################################################################################
###  THIS SCRIPT CROPS AND SAVES THE DROUGHT MORTALITY POLYGONS FOR EACH UNIT AND SET OF YEARS
#########################################################################################################################

##### ***THINGS YOU MIGHT NEED TO CHANGE*** #########
EPIC <- "C:/Users/Battles Lab/Box Sync/EPIC-Biomass" # Define where your EPIC-BIOMASS folder is located in Box Sync
#EPIC <- "C:/Users/Carmen/Box Sync/EPIC-Biomass"
#########################################################################################################################

library(rgdal)  
library(raster)  
options(digits = 5)

setwd(paste(EPIC, "/GIS Data/", sep=""))
drought <- readOGR("tempdir", "drought")
drought_bu <- drought
drought <- subset(drought, drought$RPT_YR %in% c(2014,2015))
drought <- spTransform(drought, crs(LEMMA))
drought_bu <- drought # backup so that I don't need to re-read if I accidentally override drought



units <- readOGR(dsn = "units", layer = "units_nokc")
units <- spTransform(units, crs(LEMMA))
KCNP <- readOGR(dsn = "Boundary_KingsNP_20100209", layer = "Boundary_KingsNP_20100209")
KCNP <- spTransform(KCNP, crs(LEMMA))
LTMU <- readOGR(dsn = "tempdir", layer = "FS_LTMU")
LTMU <- spTransform(LTMU, crs(LEMMA))

unit.names <- c("LNP", "ENF","ESP","LTMU","CSP","SNF","SQNP","KCNP", "MHSF")
plot()
for(i in 1:length(unit.names)) {
  UNIT <- unit.names[i]
  ### Single out the unit of interest
  if(UNIT %in% units$UNIT){
    unit <- units[units$UNIT==UNIT,]
  } else if (UNIT=="KCNP"){
    unit <- KCNP
  } else
    unit <- LTMU
  drought <- crop(drought, extent(unit)) # *****comment out this step for running on the entire drought data set*****
  writeOGR(drought, dsn="drought_byunit", layer=paste("drought_1415", UNIT, sep=""), driver="ESRI Shapefile", overwrite_layer = T)
  drought <- crop(drought, extent(unit)) # *****comment out this step for running on the entire drought data set*****
  writeOGR(drought, dsn="drought_byunit", layer=paste("drought_1415", UNIT, sep=""), driver="ESRI Shapefile", overwrite_layer = T)
}
