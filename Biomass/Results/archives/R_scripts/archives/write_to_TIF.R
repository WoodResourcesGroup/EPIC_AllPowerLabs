p <- result.p[,c("x", "y", "pmerge.CONBM_kg")]
coordinates(p) = ~x+y
proj4string(p) = CRS("+init=epsg:5070")
gridded(p) = TRUE
r = raster(p)
projection(r) = CRS(proj4string(p))
plot(r, col=viridis(n=20, option = 'inferno'), `extent<-`())
plot(r, col=rev(heat.colors(8, alpha=1)), breaks=seq(0,10000, by=1000))
writeRaster(r,"LEMMA_BM_sample.tif")
