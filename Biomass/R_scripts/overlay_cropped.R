### ATTEMPTS TO ACTUALLY CALCULATE BY PARK
### SOME OF THIS CODE IS PASTED FROM units_overlay.R on Carmen's PC


## Open LEMMA
if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Battles Lab/Box Sync/EPIC-Biomass/GIS Data/LEMMA_gnn_sppsz_2014_08_28/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/LEMMA_gnn_sppsz_2014_08_28/")
}

### Open GNN LEMMA data (see script crop_LEMMA.R for where LEMMA.gri comes from)
LEMMA <- raster("LEMMA.gri")

## Open shapefile for each park

library(rgdal)

setwd("C:/Users/Battles Lab/Box Sync/EPIC-Biomass/R Results")

LNP_1215 <- readOGR(dsn="Results_1215_crop", layer = "LNP_1215")

## Crop down to just 2014 and 2015 and check it out
LNP_1415 <- subset(LNP_1215, LNP_1215$RPT_YR > 2013)
plot(LNP_1415, pch=".")
plot(lnp, add=T, border = "pink")

## Check that results look OK - compare NO_TREES, biomass per tree, biomass per pixel

max(LNP_1415$D_BM_kg)
max(LNP_1415$D_BM_Mg)

# Max Mg per pixel of dead biomass is 96,000,000. That's way too high! Investigate below.
hist(LNP_1415$D_BM_Mg)
hist(LNP_1415$D_BM_Mg, xlim=c(0,1000), breaks=10000000, ylim=c(0,100000))

# How do dead trees per polygon and relative number of dead trees per pixel look?
hist(LNP_1415$relNO)
# It looks like my results are showing relNO of trees per pixel as high as 1,000,000, which is awfully high
    # Investigate how high that is by comparing to THA
hist(LNP_1415$THA*.09)
hist(LEMMA_LNP@data@attributes[[1]]$TPH_GE_3) # total TPH should not exceed 10,000, so the above results are definitely wrong

# Check average dead biomass per pixel averaged across all pixels in each polygon to see if they look ok
plot(unique(LNP_1415$P_NO_TR/LNP_1415$Pl_Sh_A), main="number of dead trees per sq m in polygon")
# Compare to that of the original drought polygon layer
plot(drought$NO_TREE/drought$Shap_Ar, main="number of dead trees per sq m in polygon from original drought data")
### THESE TWO NUMBERS ARE DRASTICALLY DIFFERENT. SOMETHING IS WRONG
### LOOK AT JUST THE ORIGINAL DROUGHT POLYGONS THAT FALL WITHIN LASSEN
library(rgeos)
drought.lnp <- crop(drought, extent(LNP_1415))
drought.lnp.1415 <- subset(drought.lnp, drought.lnp$RPT_YR>2013)
plot(drought.lnp.1415)
plot(LNP_1415, add=T, pch=".", col="orange")
plot(unique(LNP_1415$P_NO_TR/LNP_1415$Pl_Sh_A), main="number of dead trees per sq m in polygon")
plot(drought.lnp.1415$NO_TREE/drought.lnp.1415$Shap_Ar, main="number of dead trees per sq m in polygon from original drought data")
plot(sort(drought.lnp.1415$NO_TREE))
plot(sort(LNP_1415$P_NO_TR))

# Check number of dead trees in polygon against relNO * number of pixels in polygon

LNP_1415$D_BM_Mgha <- (LNP_1415$D_BM_kg/1000)/.09
hist(LNP_1415$D_BM_Mgha)
LNP_1415_D_BM_sum_kg <- sum(LNP_1415$D_BM_kg)

## Overlay with LEMMA
LEMMA_LNP <- crop(LEMMA, extent(lnp)) # crop LEMMA GLN data to the size of that polygon
LEMMA_LNP <- mask(LEMMA_LNP, lnp) # fit the cropped LEMMA data to the shape of the polygon
plot(LEMMA_LNP@data$, add=T)
length(LEMMA_LNP)

# Use area of LNP to calculate dead biomass density 
area(lnp)
LNP_DBM_kgha <- LNP_D_BM_sum_kg/area(lnp)
LNP_DBM_kgha
LNP_DBM_Mgha <- LNP_D_BM_sum_kg/area(lnp)/1000

LNP_1415_DBM_Mgha <- LNP_1415_D_BM_sum_kg/area(lnp)/1000

# Check against drought mortality polygons
if( Sys.info()['sysname'] == "Windows" ) {
  +   setwd("C:/Users/Battles Lab/Box Sync/EPIC-Biomass/GIS Data/")
  + } else {
    +   setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
    + }
drought <- readOGR("tempdir", "drought")
plot(drought, add=T, col="green")


# To find biomass from LEMMA, need to repeat some of the steps from the original analysis
### Repeat for other units


### Open Results

# Crop and resave for faster opening in the future
result_16_crop <- crop(result_16, extent(units))
result_1215_crop <- crop(result_1215, extent(units))
writeOGR(obj=result_16_crop, dsn = "")
writeOGR(obj=spdf, dsn="Results_2012-2015",layer = "Results_2012-2015", driver="ESRI Shapefile")

### Crop and mask results once for each unit spdf

library(sp)
results_1215_MH <- crop(results_1215, extent(MH))
results_1215_MH <- spTransform(results_1215_MH, crs(Mtn_hm))

results_1215_FS <- crop(results_1215, extent(FS))

results_1215_kc <- crop(results_1215, extent(kc))
results_1215_lnp <- crop(results_1215, extent(lnp))

### Trying with gIntersect

# First find which points in results fall within MH
MH.intersect <- gIntersection(Mtn_hm, results_1215_MH, byid=T)
plot(Mtn_hm, add=T, border="orange")
MH.pts.intersect <- strsplit(dimnames(MH.intersect@coords)[[1]], " ")
MH.pts.intersect.id <- as.numeric(sapply(MH.pts.intersect,"[[",2))
MH.pts.extract <- results_1215_MH[MH.pts.intersect.id, ]
results_1215_MH_ex <- subset(results_1215_MH, results_1215_MH$key %in% MH.pts.intersect.id)

plot(results_1215_MH_ex)
plot(Mtn_hm, add=T, border="orange")

# Repeat for st_p
results_1215_SP <- crop(results_1215, extent(st_p))
results_1215_SP <- spTransform(results_1215_SP, crs(st_p))

### Divide into the two parks
CSP <- st_p[1,]
ESP <- st_p[2,]

### Calculate separately for each park
CSP.intersect <- gIntersection(CSP, results_1215_SP, byid=T)
CSP.pts.intersect <- strsplit(dimnames(CSP.intersect@coords)[[1]], " ")
CSP.pts.intersect.id <- as.numeric(sapply(CSP.pts.intersect,"[[",2))
CSP.pts.extract <- results_1215_CSP[CSP.pts.intersect.id, ]
results_1215_CSP <- subset(results_1215_SP, results_1215_SP$key %in% CSP.pts.intersect.id)
plot(results_1215_CSP)
plot(st_p, add=T, border = "orange")