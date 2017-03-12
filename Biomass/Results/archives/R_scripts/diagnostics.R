### DIAGNOSTICS OF MH WEIRDNESS


EPIC <- "C:/Users/Carmen/Box Sync/EPIC-Biomass"
### Define where the cec-apl folder is
CEC <- "~/cec_apl/"

# Load results of live biomass analysis 
setwd(paste(EPIC, "/GIS Data/Results/Results_CRM", sep=""))
load("MH_raster_1215.Rdata")

load("Results_1215_MH_CRM.Rdata")
Results_1215 <- spdf
plot(Results_MH)
plot(raster.mask,add=T)
length(raster.mask)

r1215 <- raster.mask

load("Results_2016_MH_CRM.Rdata")
Results_16 <- spdf
plot(Results_16, pch=".")
plot(raster.mask,add=T)
length(raster.mask)
xyz <- as.data.frame(cbind(spdf@data$x, spdf@data$y, spdf@data$D_BM_kg))
try.raster <- rasterFromXYZ(xyz, crs = crs(spdf))
raster.mask <- mask(try.raster, unit)
plot(raster.mask, add=T)
r16 <- raster.mask
sumBM16 <- sum(na.omit(r16@data@values))
(sumBM16/2110)/1000
plot(drought, add=T, col="blue")
ggplot(data = results)+
  geom_histogram(mapping = aes(x = D_BM_kgha), fill = "red", bins = 40, alpha = .5)+
  geom_histogram(mapping = aes(x = BPH_GE_25_CRM), fill="blue", bins=40, alpha = .5)

max(results$D_BM_kgha)
sort(subset(results$D_BM_kgha, results$D_BM_kgha>2500000))

max(results$BPH_GE_25_CRM)

wrong <- subset(results, results$D_BM_kgha > results$BPH_GE_25_CRM)
xy <- wrong[,c("x","y")]
spdf <- SpatialPointsDataFrame(coords=xy, data = wrong, proj4string = crs(LEMMA))

### Investigate the subset of pixels with bad numbers
plot(spdf, pch=".")
summary(as.factor(wrong$Pol.ID))
plot(unit)
plot(spdf, add=T, pch=".", col="pink")
wpol <- subset(drought, drought$NO_TREES1 %in% wrong$Pol.NO_TREES1)
plot(wpol, add=T, border="orange")

## ALL THE PROBLEM POLYGONS ARE ONLY PARTIALLY WITHIN BOUNDS OF THE RESULTS

summary(as.factor(wrong$Pol.NO_TREES1))
summary((wrong$relNO))
summary(wrong$relNO*wrong$BM_tree_kg)
summary(wrong$D_BM_kg)
summary(wrong$BPH_GE_25_CRM)
summary(wrong$BPH_GE_25_CRM/wrong$TPH_GE_25)
summary(wrong$TPH_GE_25)
