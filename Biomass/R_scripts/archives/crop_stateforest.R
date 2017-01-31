
if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
}

FS <- readOGR(dsn = "FS_Units", layer = "FS_Units") 

# GET STATE FOREST DATA FROM HERE http://frap.fire.ca.gov/data/frapgisdata-sw-ownership13_2_download 