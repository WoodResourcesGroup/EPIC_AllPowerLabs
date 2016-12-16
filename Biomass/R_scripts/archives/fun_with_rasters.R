library(rgdal)
library(raster)
library(rgeos)
library(stringr)
library(dplyr)
library(viridis)

### GONZALEZ DATA
setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/Gonzalez Data")
PG_biomass <- raster("California_above_biomass_2010.tif")
PG_analysis <- raster("California biomass 2010 analysis.tif")
library(viridis)
# plot(PG_biomass) #when plotted in Arc, there are large areas of the Sierra with ~600 Mg/ha, while the carbon figure in the paper is almost all below 
# 300 Mg/ha, so this is definitely biomass in Mg/ha, not carbon
# plot(PG_analysis)
crs(PG_biomass)
crs(PG_analysis) #EPSG 5070, same as LEMMA, in part because of what's in the PDF file in Gonzalez Data folder
extent(PG_biomass)

### LEMMA DATA
setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/LEMMA_gnn_sppsz_2014_08_28/")
#LEMMA <- raster("mr200_2012")
#crs(LEMMA) # 5070. based on what this guys says: http://gis.stackexchange.com/questions/128190/convert-srtext-to-proj4text
#plot(LEMMA) # This is just plotting alias for FCID, forest class identification number, as described here: http://lemma.forestry.oregonstate.edu/data/structure-maps
#extent(LEMMA)
#LEMMA <- crop(LEMMA, extent(-2362845, -1627605, 1232145, 2456985))
#writeRaster(LEMMA, filename = "LEMMA.tif", format = "GTiff", overwrite = TRUE) # save a backup
LEMMA <- raster("LEMMA.gri")

### DROUGHT MORTALITY POLYGONS
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

### RAMIREZ DATA
#setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/Ramirez Data/Copy of ENVI_FR.1754x4468x15x1000/")
#GDALinfo("FR_2016.01.13_167.bsq")
#CR_mort <- raster("FR_2016.01.13_167.bsq")
#crs(CR_mort)
# plot(CR_mort)
# CR_mort <- projectRaster(CR_mort, crs=crs(drought))
setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/tempdir")
#writeRaster(CR_mort, filename = "CR_mort.tif", format = "GTiff", overwrite = TRUE) # save a backup 
CR_mort <- raster("CR_mort.tif")

### Find biomass for drought mortality polygons using Gonzalez data 

### Gonzalez data

# Try it on extent of Ramirez data so that I can compare the data sources?
drought.s <- crop(drought, extent(CR_mort))
drought.s <- subset(drought.s, drought.s$ACRES >2)
plot(drought.s, add=T)
# These don't look like they overlap that well. NEED TO CHECK PROJECTION CONVERSIONS

result <- data.frame()
for (i in 1:nrow(drought)) {
  single <- drought.s[i,]
  clip1 <- crop(PG_biomass, extent(single))
  clip2 <- mask(clip1, single)
  ext <- extract(clip2, single) # extracts biomass values from the raster 
  ave.biomass <- mean(ext[[1]])
  final <- cbind(single@data$RPT_YR,single@data$TPA,single@data$NO_TREE,single@data$FOR_TYP,single@data$Shap_Ar,ave.biomass, gCentroid(single)@coords) 
  final <- as.data.frame(final)
  names(final)[names(final)=="V1"] <- "RPT_YR"
  names(final)[names(final)=="V2"] <- "TPA"
  names(final)[names(final)=="V3"] <- "NO_TREE"
  names(final)[names(final)=="V4"] <- "FOR_TYP"
  names(final)[names(final)=="V5"] <- "Shap_Ar"
  names(final)[names(final)=="x"] <- "Cent.x"
  names(final)[names(final)=="y"] <- "Cent.y"  
  result <- rbind(final, result)
}
head(result)
write.csv(result, file = "Trial_Biomass_Polygons.csv", row.names=F)
result.trial <- read.csv("Trial_Biomass_Polygons.csv")

###  LEMMA data 

### FIND A RANDOM SAMPLE OF DROUGHT TO FIND MOST COMMON TREE SPECIES
sample <- sample(nrow(drought), 500, replace =F)
plot(drought[sample,]) #?
result.sample <- data.frame()
# Use this for loop to figure out what the species are in the sample
for (i in sample) {
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

# Create table based on Jenkins paper - for now only broken down by broad category, but I could do it by individual species later if we want
types <- c("Cedar", "Dougfir", "Fir", "Pine", "Spruce")
B0 <- as.numeric(c(-2.0336, -2.2304, -2.5384, -2.5356, -2.0773))
B1 <- as.numeric(c(2.2592, 2.4435, 2.4814, 2.4349, 2.3323))
BM_eqns <- cbind(types, B0, B1)
all.species <- sort(levels(unique(result.sample$CONPLBA))) # Use this to assign species to genera

Cedars <- c("CADE27", "THPL", "CHLA", "CHNO") # all have been checked for genus
Dougfirs <- c("PSMA", "PSMA") # all have been checked for genus
Firs <- c("ABAM", "ABBR", "ABGRC", "ABLA", "ABPRSH", "TSHE", "TSME")
Pines <- c("PIAL", "PIAR", "PIAT", "PIBA", "PICO", "PICO3", "PIFL2", "PIJE", "PILA", "PILO", "PIMO", "PIMO3", "PIMU", "PIPO", "PIRA2", "PISA2") # all have been checked for genus
Spruces <- c("PIEN", "PISI") # all have been checked for genus

result.lemma <- data.frame()
for (i in 1:2) {
  single <- drought[7,]
  clip1 <- crop(LEMMA, extent(single))
  clip2 <- mask(clip1, single)
  ext <- extract(clip2, single) # extracts data from the raster
  tab <- lapply(ext, table) # creates a table that counts how many of each raster value there are 
  s <- sum(tab[[1]]) # Counts raster cells in clip2 - This is different from length(clip2tg) because it doesn't include NAs
  mat <- as.data.frame(tab)
  mat2 <- as.data.frame(tab[[1]]/s) # Gives fraction of polygon occupied by each plot type. Adds up to 1 for each polygon.
  L.in.mat <- subset(LEMMA@data@attributes[[1]], LEMMA@data@attributes[[1]][,"ID"] %in% mat[,1])[,c("ID","BA_GE_3","BPHC_GE_3_CRM","TPHC_GE_3","QMDC_DOM","CONPLBA","TREEPLBA")]
  # Calculate biomass per tree for average tree size of dom and codom, for most common species, for each raster cell
  L.in.mat$BA_tree_kg <- 0
  
  # NEED TO LOOK AT CONPLBA FOR A SUBSET OF POLYGONS AND THEN SELECT TREEPLBA FOR THE MOST COMMON ONES, THEN CALCULATE BIOMASS BASED ON FRACTION OF EACH
  if (is.na(L.in.mat[1,1])) {
      next
  }
  merge <- merge(L.in.mat, mat2, by.y = "Var1", by.x = "ID")
  BA <- mean(merge$BA_GE_3) # average basal area
  BM <- sum(merge$BPHC_GE_3_CRM*merge$Freq)
  THA <- sum(merge$TPHC_GE_3*merge$Freq)
  TREEPL <- names(tail(sort(summary(merge$TREEPLBA)), n=1)) # most common tree
  TREEPLR <- as.numeric(tail(sort(summary(merge$TREEPLBA)), n=1))/nrow(merge) # Proportion of cells with most common tree
  CONPL <- names(tail(sort(summary(merge$CONPLBA)), n=1))
  CONPLR <- as.numeric(tail(sort(summary(merge$CONPLBA)), n=1))/nrow(merge) # Proportion of cells with most common conifer
  numcon <- length(tail(sort(summary(merge$CONPLBA))))
  CONPL2 <- names(tail(sort(summary(merge$CONPLBA))))[numcon-1]
  CONPLR2 <- as.numeric(tail(sort(summary(merge$CONPLBA))))[numcon-1]/nrow(merge) # Proportion of cells with 2nd most common conifer
  CONPL3 <- names(tail(sort(summary(merge$CONPLBA))))[numcon-2]
  CONPLR3 <- as.numeric(tail(sort(summary(merge$CONPLBA))))[numcon-2]/nrow(merge) # Proportion of cells with 3rd most common conifer
  final <- cbind(single@data$RPT_YR,single@data$TPA,single@data$NO_TREE,single@data$FOR_TYP,single@data$Shap_Ar,BM, THA, TREEPL, TREEPLR, 
                 CONPL,CONPLR, CONPL2, CONPLR2, CONPL3, CONPLR3,gCentroid(single)@coords)
  final <- as.data.frame(final)
  result.lemma <- rbind(final, result.lemma)
}
names(result.lemma)[names(result.lemma)=="V1"] <- "RPT_YR"
names(result.lemma)[names(result.lemma)=="V2"] <- "TPA"
names(result.lemma)[names(result.lemma)=="V3"] <- "NO_TREE"
names(result.lemma)[names(result.lemma)=="V4"] <- "FOR_TYP"
names(result.lemma)[names(result.lemma)=="V5"] <- "Shap_Ar"
names(result.lemma)[names(result.lemma)=="x"] <- "Cent.x"
names(result.lemma)[names(result.lemma)=="y"] <- "Cent.y"  
result.lemma$est.tot.trees <- ((result.lemma$Shap_Ar)/1000)*result.lemma$THA
result.lemma$est.perc.dead <- result.lemma$NO_TREE/result.lemma$est.tot.trees
result.lemma$est.dead.BM <- result.lemma$est.perc.dead * result.lemma$BM
head(result.lemma)

for (i in 1:nrow(L.in.mat)) {
  cell <- L.in.mat[i,]
  if (cell$CONPLBA %in% Cedars) {
    num <- (B0[1] + B1[1]*log(cell$QMDC_DOM))
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
  L.in.mat[i,]$CONBA_tree_kg <- exp(num)
}



result.lemma.drought.s <- result.lemma #  Error in fix.by(by.y, y) : 'by' must specify a uniquely valid column (at row 879)
write.csv(result.lemma.drought.s, file = "result.lemma.drought.s_1-879.csv", row.names=F)
result.lemma.drought.s.1.879 <- read.csv("result.lemma.drought.s_1-879.csv")
# For some reason, rows 880 and 1182 are wacky, so I'm leaving it out and running it in chunks
result.lemma.drought.s.881.1181 <- result.lemma
write.csv(result.lemma.drought.s.881.1181, file = "result.lemma.drought.s_881.1181.csv", row.names=F)
result.lemma.drought.s.881.1181 <- read.csv("result.lemma.drought.s_881.1181.csv")
result.lemma.drought.s.1183.1452 <- result.lemma
result.lemma.drought.s.1181.end <- result.lemma
result.drought.s <- rbind(result.lemma.drought.s.1.879, result.lemma.drought.s.881.1181,result.lemma.drought.s.1181.end)
write.csv(result.lemma.drought.s, file = "Trial_Biomass_Polygons_LEMMA.csv", row.names=F)

## PROBLEM: THE METHOD ABOVE DOESN'T TAKE INTO ACCOUNT THAT MANY OF THE TPH AREN'T DETECTABLE FROM AIR
## ANOTHER APPROACH: USE THE "QMDC_DOM" VARIABLE, WHICH IS MEAN DIA OF DOM AND CODOM CONIFERS
##### THEN CALCULATE BIOMASS, MAYBE BASED ON "TREEPLBA" WHICH TELLS WHICH SPECIES IS MOST COMMON

##### OR BY INDIVIDUAL BASAL AREA METRICS

detach("package:raster", unload=TRUE)

### TESTING ###

