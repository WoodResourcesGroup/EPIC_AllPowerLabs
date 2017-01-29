### Plot MH results and LEMMA, find biomass in MH


setwd("C:/Users/Battles Lab/Box Sync/EPIC-Biomass/R Results")

MH_1215 <- readOGR(dsn="Mtn_MH_1215", layer = "MH_1215")
plot(MH_1215, pch=".")
plot(Mtn_MH, add=T, border = "pink")
summary(MH_1215$D_BM_kg)
MH_1215$D_BM_kgha <- MH_1215$D_BM_kg/.09
MH_D_BM_sum_kg <- sum(MH_1215$D_BM_kg)
hist(MH_1215$D_BM_kg)

## Crop down to just 2014 and 2015
MH_1415 <- subset(MH_1215, MH_1215$RPT_YR > 2013)
summary(MH_1415$D_BM_kg)
MH_1415$D_BM_Mgha <- (MH_1415$D_BM_kg/1000)/.09
hist(MH_1415$D_BM_Mgha)

MH_1415_D_BM_sum_kg <- sum(MH_1415$D_BM_kg)

## Overlay with LEMMA
LEMMA_MH <- crop(LEMMA, extent(MH)) # crop LEMMA GLN data to the size of that polygon
LEMMA_MH <- mask(LEMMA_MH, MH) # fit the cropped LEMMA data to the shape of the polygon
plot(LEMMA_MH@data$, add=T)
length(LEMMA_MH)

# Use size of MH overlay to calculate dead biomass density 
MH_area <- sum(area(Mtn_hm))
MH_DBM_Mgha <- MH_1415_D_BM_sum_kg/MH_area/1000
MH_DBM_Mgha

# Check against drought mortality polygons
if( Sys.info()['sysname'] == "Windows" ) {
  +   setwd("C:/Users/Battles Lab/Box Sync/EPIC-Biomass/GIS Data/")
  + } else {
    +   setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
    + }
drought <- readOGR("tempdir", "drought")
plot(drought, add=T, col="green")

