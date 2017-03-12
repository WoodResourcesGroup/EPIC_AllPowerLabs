

############################################################################
### TEST METHOD OF AVERAGING RESULTS USING RASTER 
### DO IT THE OLD WAY TO MAKE SURE RESULTS ARE CORRECT

strt<-Sys.time()
intersect <- gIntersection(unit, spdf_CSP, byid=T) 
print(Sys.time()-strt)
# Takes 30 min on Turbo!
KCNP.pts.intersect <- strsplit(dimnames(intersect@coords)[[1]], " ")
KCNP.pts.intersect.id <- as.numeric(sapply(KCNP.pts.intersect,"[[",2))
KCNP.pts.extract <- spdf[KCNP.pts.intersect.id, ]
test.intersect <- subset(spdf, spdf$key %in% KCNP.pts.intersect.id)

### Compare
length(subset(test.intersect, test.intersect$D_BM_kgha>0)) ## SAME AS ABOVE!
mean(subset(test.intersect$D_BM_kg, test.intersect$D_BM_kg>0)) ## SAME AS ABOVE!
mean(subset(raster.mask@data@values, raster.mask@data@values>0)) ## same as above!
