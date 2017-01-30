library(rgdal)

if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/R Results")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/R Results")
}

Results <- read.csv(file = "LEMMA_ADS_AllSpp_AlYrs_011817.csv", header = T)

Results <- readOGR(dsn = "R Results", layer = "Results_through15") 
plot(Results)

Cstack_info()
