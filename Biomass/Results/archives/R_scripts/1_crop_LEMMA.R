library(raster)

if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/LEMMA_gnn_sppsz_2014_08_28/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/LEMMA_gnn_sppsz_2014_08_28/")
}

LEMMA <- raster("mr200_2012") # see README.md for more info on 
crs(LEMMA) # 5070. based on what this guys says: http://gis.stackexchange.com/questions/128190/convert-srtext-to-proj4text
plot(LEMMA) # This is just plotting alias for FCID, forest class identification number, as described here: http://lemma.forestry.oregonstate.edu/data/structure-maps
extent(LEMMA)

LEMMA <- crop(LEMMA, extent(-2362845, -1627605, 1232145, 2456985)) # Crop LEMMA so it only contains CA
LEMMA_bu <- LEMMA # backup
writeRaster(LEMMA, filename = "LEMMA.grd", overwrite = T) # save a backup
# This creates both a .gri and a .grd file
# I tried writing the raster in GeoTIFF and IMG formats, but they do not retain attribute information, which is critical
