
### RAMIREZ DATA
if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/Ramirez Data/Copy of ENVI_FR.1754x4468x15x1000/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/Ramirez Data/Copy of ENVI_FR.1754x4468x15x1000/")
}
GDALinfo("FR_2016.01.13_167.bsq")
CR_mort <- raster("FR_2016.01.13_167.bsq")
crs(CR_mort)
plot(CR_mort)
CR_mort <- projectRaster(CR_mort, crs=crs(drought))

if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/tempdir/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/tempdir")
}

writeRaster(CR_mort, filename = "CR_mort.tif", format = "GTiff", overwrite = TRUE) # save a backup 
