
if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/")
}

Results <- readOGR(dsn = "R Results", layer = "Results_through15") 
