

if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
}


nat_parks <- readOGR(dsn = "Nat_Parks", layer = "nps_boundary")
plot(nat_parks)

as.data.frame(sort(lnp$PARKNAME))

lnp <- subset(nat_parks, nat_parks@data$PARKNAME=="Lassen Volcanic")
plot(lnp)

writeOGR(obj=lnp, dsn="tempdir",layer = "LNP", driver="ESRI Shapefile", overwrite_layer = TRUE)

