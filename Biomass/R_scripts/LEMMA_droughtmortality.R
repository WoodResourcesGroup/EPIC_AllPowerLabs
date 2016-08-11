library(rgdal)
library(raster)
library(rgeos)
library(stringr)
library(dplyr)
library(viridis)

### OPEN LEMMA DATA
setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/LEMMA_gnn_sppsz_2014_08_28/")
#LEMMA <- raster("mr200_2012")
#crs(LEMMA) # 5070. based on what this guys says: http://gis.stackexchange.com/questions/128190/convert-srtext-to-proj4text
#plot(LEMMA) # This is just plotting alias for FCID, forest class identification number, as described here: http://lemma.forestry.oregonstate.edu/data/structure-maps
#extent(LEMMA)
#LEMMA <- crop(LEMMA, extent(-2362845, -1627605, 1232145, 2456985))
#writeRaster(LEMMA, filename = "LEMMA.tif", format = "GTiff", overwrite = TRUE) # save a backup
LEMMA <- raster("LEMMA.gri")

### OPEN# DROUGHT MORTALITY POLYGONS
setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/")
#drought <- readOGR(dsn = "DroughtTreeMortality.gdb", layer = "DroughtTreeMortality") 
# plot(drought, add = TRUE) # only plot if necessary; takes a long ass time
# crs(drought)
# drought <- spTransform(drought, crs(LEMMA)) #change it to CRS of Gonzalez and LEMMA data - this takes a while
# crs(drought)
# writeOGR(obj=drought, dsn="tempdir",layer = "drought", driver="ESRI Shapefile")
drought <- readOGR("tempdir", "drought")
drought_bu <- drought # backup so that I don't need to re-read if I accidentally override drought
# take out areas not in high hazard zones
#highhaz <- readOGR(dsn = "HighHazardZones.gdb", layer = "HHZ_Tier2")
#crs(highhaz)
#highhaz <- spTransform(highhaz, crs(drought))

#drought.test <- gIntersection(drought.s, highhaz)
#drought.s.gIntersection <- drought.test
# Intersection is too hard for now - ask Jose to do it on QGIS

# narrow drought down to large-ish polygons
drought <- subset(drought, drought$ACRES > 2)

### FIND A RANDOM SAMPLE OF DROUGHT TO FIND MOST COMMON TREE SPECIES
sample <- sample(nrow(drought), 500, replace =F)
plot(drought[sample,]) # Make sure it's distributed throughout the state
# Use this for loop to figure out what the species are in the sample:
result.sample <- data.frame()
for (i in 1:length(sample)) {
  single <- drought[i,]
  clip1 <- crop(LEMMA, extent(single))
  clip2 <- mask(clip1, single)
  ext <- extract(clip2, single) # extracts data from the raster
  tab <- lapply(ext, table) # creates a table that counts how many of each raster value there are 
  s <- sum(tab[[1]]) # Counts raster cells in clip2 - This is different from length(clip2tg) because it doesn't include NAs
  mat <- as.data.frame(tab)
  L.in.mat <- subset(LEMMA@data@attributes[[1]], LEMMA@data@attributes[[1]][,"ID"] %in% mat[,1])[,c("ID","BA_GE_3","BPHC_GE_3_CRM","TPHC_GE_3","QMDC_DOM","CONPLBA","TREEPLBA")]
  if (is.na(L.in.mat[1,1])) {
    next
  }
  result.sample <- rbind(L.in.mat, result.sample)
}

## Create table of dia -> biomass parameters based on Jenkins paper - for now only broken down by broad genus category, but I could do it by individual species later if we want
## Source: J. C. Jenkins, D. C. Chojnacky, L. S. Heath, and R. A. Birdsey, "National-scale biomass estimators for United States tree species," For. Sci., vol. 49, no. 1, pp. 12-35, 2003.
## biomass = exp(B0 + B1*ln(dbh))
types <- c("Cedar", "Dougfir", "Fir", "Pine", "Spruce")
B0 <- as.numeric(c(-2.0336, -2.2304, -2.5384, -2.5356, -2.0773))
B1 <- as.numeric(c(2.2592, 2.4435, 2.4814, 2.4349, 2.3323))
BM_eqns <- cbind(types, B0, B1)
all.species <- sort(levels(unique(result.sample$CONPLBA))) # Use this to assign species to genera

Cedars <- c("CADE27", "THPL", "CHLA", "CHNO") # all have been checked for genus on plants.usda.gov
Dougfirs <- c("PSMA", "PSME") # all have been checked for genus plants.usda.gov
Firs <- c("ABAM", "ABBR", "ABGRC", "ABLA", "ABPRSH", "TSHE", "TSME")
Pines <- c("PIAL", "PIAR", "PIAT", "PIBA", "PICO", "PICO3", "PIFL2", "PIJE", "PILA", "PILO", "PIMO", "PIMO3", "PIMU", "PIPO", "PIRA2", "PISA2") # all have been checked for genus plants.usda.gov
Spruces <- c("PIEN", "PISI") # all have been checked for genus plants.usda.gov

result.lemma <- data.frame()
for (i in 1:nrow(drought.s)) { # final: nrow(drought)
  single <- drought[i,]
  clip1 <- crop(LEMMA, extent(single))
  clip2 <- mask(clip1, single)
  ext <- extract(clip2, single) # extracts data from the raster - this value is the plot # of the raster cell, which corresponds to detailed data in the attribute table
  tab <- lapply(ext, table) # creates a table that counts how many of each raster value there are in the polygon
  s <- sum(tab[[1]]) # Counts total raster cells the polygon - this is different from length(clip2tg) because it doesn't include NAs
  mat <- as.data.frame(tab)
  mat2 <- as.data.frame(tab[[1]]/s) # Gives fraction of polygon occupied by each plot type. Adds up to 1 for each polygon.
  mat2 <- merge(mat, mat2, by="Var1")
  # extract attribute information from LEMMA for each plot number contained in the polygon:
  L.in.mat <- subset(LEMMA@data@attributes[[1]], LEMMA@data@attributes[[1]][,"ID"] %in% mat[,1])[,c("ID","BAC_GE_3","BPHC_GE_3_CRM","TPHC_GE_3","QMDC_DOM","CONPLBA","TREEPLBA")]
  # SKIP POLYGONS WITH NO CORRESPONDING RASTER DATA
  if (is.na(L.in.mat[1,1])) {
    next
  }
  merge <- merge(L.in.mat, mat2, by.y = "Var1", by.x = "ID")
   # Use a for loop to calculate biomass per tree based on the average dbh of dominant and codominant trees for the most common species in each raster cell:
  merge$CONBM_tree_kg <- 0
  merge$CONBM_kg <- 0
  merge$relNO <- 0
  merge$sumBA <- 0
  for (i in 1:nrow(merge)) {
    cell <- merge[i,]
    if (cell$CONPLBA %in% Cedars) { #CONPLBA = Conifer tree species with plurality of basal area
      num <- (B0[1] + B1[1]*log(cell$QMDC_DOM)) # apply formula above, minus the exp. QMDC_DOM = Quadratic mean diameter of all dominant and codominant conifers
    } else if (cell$CONPLBA %in% Dougfirs) {
      num <- (B0[2] + B1[2]*log(cell$QMDC_DOM))
    } else if (cell$CONPLBA %in% Firs) {
      num <- (B0[3] + B1[3]*log(cell$QMDC_DOM))
    } else if (cell$CONPLBA %in% Pines) {
      num <- (B0[4] + B1[4]*log(cell$QMDC_DOM))
    } else if (cell$CONPLBA %in% Spruces) {
      num <- (B0[5] + B1[5]*log(cell$QMDC_DOM))
    } else {
      num <- 0
    }
    if (num == 0) {
      merge[i,]$CONBM_tree_kg <- 0 # assign 0 if no conifers
    } else {
      merge[i,]$CONBM_tree_kg <- exp(num) # finish the formula
    }
    merge[i,]$sumBA <- cell$BAC_GE_3*cell$Freq.x
  }
  totBA <- sum(merge$sumBA)
  merge$relBA <- merge$sumBA/totBA
  tot_NO <- single@data$NO_TREE
  merge$relNO <- tot_NO*merge$relBA
  merge$CONBM_kg <- merge$relNO*merge$CONBM_tree_kg
  CONBM_kg_pol <- sum(merge$CONBM_kg)
  Av_BM_TR <- CONBM_kg_pol/tot_NO
  QMDC_DOM <- mean(merge$QMDC_DOM)
  CONPL <-  names(tail(sort(summary(merge$CONPLBA)), n=1))
  TOT_CONBM_kgha <- sum(merge$BPHC_GE_3_CRM*merge$Freq.y) # BPHC_GE_3_CRM is estimated biomass of all conifers
  CON_THA <- sum(merge$TPHC_GE_3*merge$Freq.y)
  final <- cbind(single@data$RPT_YR,single@data$TPA,single@data$NO_TREE,single@data$FOR_TYP,single@data$Shap_Ar,TOT_CONBM_kgha, CON_THA, QMDC_DOM, CONPL, Av_BM_TR, CONBM_kg_pol,gCentroid(single)@coords)
  final <- as.data.frame(final)
  final$est.tot.con <- (single@data$Shap_Ar/10000)*CON_THA
  final$est.tot.con.BM <- (single@data$Shap_Ar/10000)*TOT_CONBM_kgha
  result.lemma <- rbind(final, result.lemma)
}
names(result.lemma)[names(result.lemma)=="V1"] <- "RPT_YR"
names(result.lemma)[names(result.lemma)=="V2"] <- "TPA"
names(result.lemma)[names(result.lemma)=="V3"] <- "NO_TREE"
names(result.lemma)[names(result.lemma)=="V4"] <- "FOR_TYP"
names(result.lemma)[names(result.lemma)=="V5"] <- "Shap_Ar"
names(result.lemma)[names(result.lemma)=="x"] <- "Cent.x"
names(result.lemma)[names(result.lemma)=="y"] <- "Cent.y"  
head(result.lemma)

# CLEAR EVERYTHING IN LOOPS
remove(cell, final, L.in.mat, mat, mat2, merge)
remove(BM_eqns, BA, BM, clip1, clip2, CONPL, CONPL2, CONPL3, CONPLR, CONPLR2, CONPLR3)
remove(num, numcon, s, ext, i, tab, single, THA, TREEPL, TREEPLR, QMDC_DOM, Av_BM_TR, CONBM_kgha, CONBM_kg_pol, relNO, NO)

result.lemma.drought.s <- result.lemma 
setwd("C:/Users/Carmen/cec_apl/Biomass/Results")
write.csv(result.lemma.drought.s, file = "Trial_Biomass_Polygons_LEMMA_3.csv", row.names=F)

detach("package:raster", unload=TRUE)

