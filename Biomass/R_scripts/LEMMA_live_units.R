#########################################################################################################################
######## CALCULATE TOTAL LIVE BIOMASS IN EACH MANAGEMENT UNIT FROM LEMMA DATA
#########################################################################################################################
library(rgdal)

if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
}
units <- readOGR(dsn = "units", layer="units_nokc")

### SETWD based on whether it's Carmen's computer or Jose's computer)
if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Battles Lab/Box Sync/EPIC-Biomass/GIS Data/LEMMA_gnn_sppsz_2014_08_28/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/LEMMA_gnn_sppsz_2014_08_28/")
}

### Open GNN LEMMA data (see script crop_LEMMA.R for where LEMMA.gri comes from)
LEMMA <- raster("LEMMA.gri")
units <- spTransform(units, crs(LEMMA))

### Set up parallel cores for faster runs
library(doParallel)
library(foreach)
detectCores()
no_cores <- detectCores() - 1 # Use all but one core on your computer
c1 <- makeCluster(no_cores)
registerDoParallel(c1)

### function that does the bulk of the analysis

inputs = 1:nrow(units)
# start timer
strt<-Sys.time()
# foreach loop
LEMMA.units <- foreach(i=inputs, .combine = rbind, .packages = c('raster','rgeos'), .errorhandling="remove") %dopar% {
  single <- units[i,] # select one polygon
  clip1 <- crop(LEMMA, extent(single)) # crop LEMMA GLN data to the size of that polygon
  clip2 <- mask(clip1, single) # fit the cropped LEMMA data to the shape of the polygon
  pcoords <- cbind(clip2@data@values, coordinates(clip2)) # save the coordinates of each pixel
  pcoords <- as.data.frame(pcoords)
  pcoords <- na.omit(pcoords) # get rid of NAs in coordinates table (NAs are from empty cells in box around polygon)
  Pol.ID <- rep(i, nrow(pcoords)) # create a Polygon ID
  ext <- extract(clip2, single) # extracts data from the raster - each extracted value is the FIA plot # of the raster cell, which corresponds to detailed data in the attribute table of LEMMA
  tab <- lapply(ext, table) # creates a table that counts how many of each raster value there are in the polygon
  s <- sum(tab[[1]]) # Counts total raster cells the polygon - this is different from length(clip2tg) because it doesn't include NAs
  mat <- as.data.frame(tab)
  mat2 <- as.data.frame(tab[[1]]/s) # gives fraction of polygon occupied by each plot type. Adds up to 1 for each polygon.
  mat2 <- merge(mat, mat2, by="Var1") # creates table with FIA plot IDs in polygon, number of each, and relative frequency of each
  
  # extract attribute information from LEMMA for each plot number contained in the polygon:
  L.in.mat <- subset(LEMMA@data@attributes[[1]], LEMMA@data@attributes[[1]][,"ID"] %in% 
                       mat[,1])[,c("ID","BA_GE_3","BPH_GE_3_CRM","TPH_GE_3","QMD_DOM","TREEPLBA")]
  
  ### Attribute meanings from LEMMA GLN:
  ### BA_GE_3 = basal area of live trees >= 2.5 cm dbh (m^2/ha)
  ### BPH_GE_3_CRM = Component Ratio Method biomass of all live trees >=2.5 cm dbh (kg/ha)
  ### TPH_GE_3 = Density of live trees >=2.5 cm dbh (trees/ha)
  ### QMD_DOM = 	Quadratic mean diameter of all dominant and codominant trees (cm)
  ### TREEPLBA = Tree species with plurality of basal area
  
  merge <- merge(L.in.mat, mat2, by.y = "Var1", by.x = "ID") # merge LEMMA data with polygon data into one table
   # Find biomass per pixel using biomass per tree and estimated number of trees
  pmerge <- merge(pcoords, merge, by.x ="V1", by.y = "ID") # pmerge has a line for every pixel
  # problem here
  pmerge$relBA <- pmerge$BA_GE_3/sum(pmerge$BA_GE_3) # Create column for % of polygon BA in that pixel. 
   # Create vectors that are the same length as pmerge to combine into final table:
  QMD_DOM <- pmerge$QMD_DOM # Find the average of the pixels' quadratic mean diameters 
  TREEPL <-  pmerge$TREEPLBA # Find the tree species that has a plurality in the most pixels
  Pol.x <- rep(gCentroid(single)@coords[1], nrow(pmerge)) # Find coordinates of center of polygon
  Pol.y <- rep(gCentroid(single)@coords[2], nrow(pmerge))
  Pol.Pixels <- rep(s, nrow(pmerge)) # number of pixels
  # Estimate biomass of live AND dead trees based on LEMMA values of biomass per pixel:
  All_BM_kgha <- pmerge$BPH_GE_3_CRM 
  All_Pol_BM_kgha <- rep(mean(pmerge$BPH_GE_3_CRM),nrow(pmerge)) # Average across pixels
  THA <- pmerge$TPH_GE_3 
  
  # Bring it all together
  final <- cbind(pmerge$x, pmerge$y,pmerge$relBA, pmerge$V1, Pol.x, Pol.y, 
                All_BM_kgha,All_Pol_BM_kgha,THA, QMD_DOM,Pol.ID,TREEPL) 
  final <- as.data.frame(final)
  final$All_Pol_NO <- (area(single)/10000)*THA # Estimate total number of trees in the polygon
  final$All_Pol_BM <- (area(single)/10000)*900*All_Pol_BM_kgha # Estimate total tree biomass in the polygon
  return(final)
}

# Create a key for each pixel (row)
key <- seq(1, nrow(LEMMA.units)) 
LEMMA.units <- cbind(key, LEMMA.units)
print(Sys.time()-strt)
# only takes 10 min on Carmen's dell

# Rename variables whose names were lost in the cbind
names(LEMMA.units)[names(LEMMA.units)=="V1"] <- "x"
names(LEMMA.units)[names(LEMMA.units)=="V2"] <- "y"
names(LEMMA.units)[names(LEMMA.units)=="V3"] <- "relBA"
names(LEMMA.units)[names(LEMMA.units)=="V4"] <- "FIA_ID"

### Convert to a spatial data frame
xy <- LEMMA.units[,c("x","y")]
spdf <- SpatialPointsDataFrame(coords=xy, data = LEMMA.units, proj4string = crs(LEMMA))
plot(spdf, pch=".")
plot(units, add=T, border="orange")
LEMMA.units <- spdf
LEMMA.units.bu <- LEMMA.units

### Save spatial data frame
if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Battles Lab/Box Sync/EPIC-Biomass/GIS Data/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
}
writeOGR(obj=spdf, dsn = "LEMMA_units", layer = "LEMMA_units_nokc", driver = "ESRI Shapefile")

### REPEAT WITH KC 
###############################################################################

if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
}
kc <- readOGR(dsn = "Boundary_KingsNP_20100209", layer = "Boundary_KingsNP_20100209")
kc <- spTransform(kc, crs(LEMMA))
plot(kc, col="green")

# start timer
strt<-Sys.time()
inputs = 1:nrow(kc) # units[3:8] is all polygons in MH
LEMMA.kc <- foreach(i=inputs, .combine = rbind, .packages = c('raster','rgeos'), .errorhandling="remove") %dopar% {
  single <- kc[i,] # select one polygon
  clip1 <- crop(LEMMA, extent(single)) # crop LEMMA GLN data to the size of that polygon
  clip2 <- mask(clip1, single) # fit the cropped LEMMA data to the shape of the polygon
  pcoords <- cbind(clip2@data@values, coordinates(clip2)) # save the coordinates of each pixel
  pcoords <- as.data.frame(pcoords)
  pcoords <- na.omit(pcoords) # get rid of NAs in coordinates table (NAs are from empty cells in box around polygon)
  Pol.ID <- rep(i, nrow(pcoords)) # create a Polygon ID
  ext <- extract(clip2, single) # extracts data from the raster - each extracted value is the FIA plot # of the raster cell, which corresponds to detailed data in the attribute table of LEMMA
  tab <- lapply(ext, table) # creates a table that counts how many of each raster value there are in the polygon
  s <- sum(tab[[1]]) # Counts total raster cells the polygon - this is different from length(clip2tg) because it doesn't include NAs
  mat <- as.data.frame(tab)
  mat2 <- as.data.frame(tab[[1]]/s) # gives fraction of polygon occupied by each plot type. Adds up to 1 for each polygon.
  mat2 <- merge(mat, mat2, by="Var1") # creates table with FIA plot IDs in polygon, number of each, and relative frequency of each
  
  # extract attribute information from LEMMA for each plot number contained in the polygon:
  L.in.mat <- subset(LEMMA@data@attributes[[1]], LEMMA@data@attributes[[1]][,"ID"] %in% 
                       mat[,1])[,c("ID","BA_GE_3","BPH_GE_3_CRM","TPH_GE_3","QMD_DOM","TREEPLBA")]
  
  ### Attribute meanings from LEMMA GLN:
  ### BA_GE_3 = basal area of live trees >= 2.5 cm dbh (m^2/ha)
  ### BPH_GE_3_CRM = Component Ratio Method biomass of all live trees >=2.5 cm dbh (kg/ha)
  ### TPH_GE_3 = Density of live trees >=2.5 cm dbh (trees/ha)
  ### QMD_DOM = 	Quadratic mean diameter of all dominant and codominant trees (cm)
  ### TREEPLBA = Tree species with plurality of basal area
  
  merge <- merge(L.in.mat, mat2, by.y = "Var1", by.x = "ID") # merge LEMMA data with polygon data into one table
  # Find biomass per pixel using biomass per tree and estimated number of trees
  pmerge <- merge(pcoords, merge, by.x ="V1", by.y = "ID") # pmerge has a line for every pixel
  # problem here
  pmerge$relBA <- pmerge$BA_GE_3/sum(pmerge$BA_GE_3) # Create column for % of polygon BA in that pixel. 
  # Create vectors that are the same length as pmerge to combine into final table:
  QMD_DOM <- pmerge$QMD_DOM # Find the average of the pixels' quadratic mean diameters 
  TREEPL <-  pmerge$TREEPLBA # Find the tree species that has a plurality in the most pixels
  Pol.x <- rep(gCentroid(single)@coords[1], nrow(pmerge)) # Find coordinates of center of polygon
  Pol.y <- rep(gCentroid(single)@coords[2], nrow(pmerge))
  Pol.Pixels <- rep(s, nrow(pmerge)) # number of pixels
  # Estimate biomass of live AND dead trees based on LEMMA values of biomass per pixel:
  All_BM_kgha <- pmerge$BPH_GE_3_CRM 
  All_Pol_BM_kgha <- rep(mean(pmerge$BPH_GE_3_CRM),nrow(pmerge)) # Average across pixels
  THA <- pmerge$TPH_GE_3 
  
  # Bring it all together
  final <- cbind(pmerge$x, pmerge$y,pmerge$relBA, pmerge$V1, Pol.x, Pol.y, 
                 All_BM_kgha,All_Pol_BM_kgha,THA, QMD_DOM,Pol.ID, TREEPL) 
  final <- as.data.frame(final)
  final$All_Pol_NO <- (area(single)/10000)*THA # Estimate total number of trees in the polygon
  final$All_Pol_BM <- (area(single)/10000)*900*All_Pol_BM_kgha # Estimate total tree biomass in the polygon
  return(final)
}
print(Sys.time()-strt)

# Create a key for each pixel (row)
key <- seq(1, nrow(LEMMA.kc)) 
LEMMA.kc <- cbind(key, LEMMA.kc)

# Rename variables whose names were lost in the cbind
names(LEMMA.kc)[names(LEMMA.kc)=="V1"] <- "x"
names(LEMMA.kc)[names(LEMMA.kc)=="V2"] <- "y"
names(LEMMA.kc)[names(LEMMA.kc)=="V3"] <- "relBA"
names(LEMMA.kc)[names(LEMMA.kc)=="V4"] <- "FIA_ID"

### Convert to a spatial data frame
xy <- LEMMA.kc[,c("x","y")]
spdf <- SpatialPointsDataFrame(coords=xy, data = LEMMA.kc, proj4string = crs(LEMMA))
plot(spdf, pch=".")
plot(kc, add=T, border="orange")
LEMMA.kc <- spdf
LEMMA.kc_bu <- LEMMA.kc

### Save spatial data frame
writeOGR(obj=spdf, dsn = "LEMMA_units", layer = "LEMMA_kc", driver = "ESRI Shapefile")

LEMMA.kc.nonzero <- subset(LEMMA.kc, LEMMA.kc$All_BM_ > 0)
# over half of pixels have zero biomass!
plot(LEMMA.kc.nonzero, pch=".", add=T, col="orange")

mean(LEMMA.kc$All_BM_)/1000
mean(LEMMA.kc.nonzero$All_BM_)/1000

# Calculate area to divide dead biomass by this from results
area.kc.sqm <- length(LEMMA.kc.nonzero)*900

###############################################################################
### REPEAT WITH LTMU
###############################################################################
if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
}
FS_LTMU <- readOGR(dsn = "tempdir", layer = "FS_LTMU")
FS_LTMU <- spTransform(FS_LTMU, crs(LEMMA))

# start timer
strt<-Sys.time()
inputs = 1:nrow(FS_LTMU) # units[3:8] is all polygons in MH
LEMMA.LTMU <- foreach(i=inputs, .combine = rbind, .packages = c('raster','rgeos'), .errorhandling="remove") %dopar% {
  single <- FS_LTMU[i,] # select one polygon
  clip1 <- crop(LEMMA, extent(single)) # crop LEMMA GLN data to the size of that polygon
  clip2 <- mask(clip1, single) # fit the cropped LEMMA data to the shape of the polygon
  pcoords <- cbind(clip2@data@values, coordinates(clip2)) # save the coordinates of each pixel
  pcoords <- as.data.frame(pcoords)
  pcoords <- na.omit(pcoords) # get rid of NAs in coordinates table (NAs are from empty cells in box around polygon)
  Pol.ID <- rep(i, nrow(pcoords)) # create a Polygon ID
  ext <- extract(clip2, single) # extracts data from the raster - each extracted value is the FIA plot # of the raster cell, which corresponds to detailed data in the attribute table of LEMMA
  tab <- lapply(ext, table) # creates a table that counts how many of each raster value there are in the polygon
  s <- sum(tab[[1]]) # Counts total raster cells the polygon - this is different from length(clip2tg) because it doesn't include NAs
  mat <- as.data.frame(tab)
  mat2 <- as.data.frame(tab[[1]]/s) # gives fraction of polygon occupied by each plot type. Adds up to 1 for each polygon.
  mat2 <- merge(mat, mat2, by="Var1") # creates table with FIA plot IDs in polygon, number of each, and relative frequency of each
  
  # extract attribute information from LEMMA for each plot number contained in the polygon:
  L.in.mat <- subset(LEMMA@data@attributes[[1]], LEMMA@data@attributes[[1]][,"ID"] %in% 
                       mat[,1])[,c("ID","BA_GE_3","BPH_GE_3_CRM","TPH_GE_3","QMD_DOM","TREEPLBA")]
  
  ### Attribute meanings from LEMMA GLN:
  ### BA_GE_3 = basal area of live trees >= 2.5 cm dbh (m^2/ha)
  ### BPH_GE_3_CRM = Component Ratio Method biomass of all live trees >=2.5 cm dbh (kg/ha)
  ### TPH_GE_3 = Density of live trees >=2.5 cm dbh (trees/ha)
  ### QMD_DOM = 	Quadratic mean diameter of all dominant and codominant trees (cm)
  ### TREEPLBA = Tree species with plurality of basal area
  
  merge <- merge(L.in.mat, mat2, by.y = "Var1", by.x = "ID") # merge LEMMA data with polygon data into one table
  # Find biomass per pixel using biomass per tree and estimated number of trees
  pmerge <- merge(pcoords, merge, by.x ="V1", by.y = "ID") # pmerge has a line for every pixel
  # problem here
  pmerge$relBA <- pmerge$BA_GE_3/sum(pmerge$BA_GE_3) # Create column for % of polygon BA in that pixel. 
  # Create vectors that are the same length as pmerge to combine into final table:
  QMD_DOM <- pmerge$QMD_DOM # Find the average of the pixels' quadratic mean diameters 
  TREEPL <-  pmerge$TREEPLBA # Find the tree species that has a plurality in the most pixels
  Pol.x <- rep(gCentroid(single)@coords[1], nrow(pmerge)) # Find coordinates of center of polygon
  Pol.y <- rep(gCentroid(single)@coords[2], nrow(pmerge))
  Pol.Pixels <- rep(s, nrow(pmerge)) # number of pixels
  # Estimate biomass of live AND dead trees based on LEMMA values of biomass per pixel:
  All_BM_kgha <- pmerge$BPH_GE_3_CRM 
  All_Pol_BM_kgha <- rep(mean(pmerge$BPH_GE_3_CRM),nrow(pmerge)) # Average across pixels
  THA <- pmerge$TPH_GE_3 
  
  # Bring it all together
  final <- cbind(pmerge$x, pmerge$y,pmerge$relBA, pmerge$V1, Pol.x, Pol.y, 
                 All_BM_kgha,All_Pol_BM_kgha,THA, QMD_DOM,Pol.ID, TREEPL) 
  final <- as.data.frame(final)
  final$All_Pol_NO <- (area(single)/10000)*THA # Estimate total number of trees in the polygon
  final$All_Pol_BM <- (area(single)/10000)*900*All_Pol_BM_kgha # Estimate total tree biomass in the polygon
  return(final)
}
print(Sys.time()-strt)

# Create a key for each pixel (row)
key <- seq(1, nrow(LEMMA.LTMU)) 
LEMMA.LTMU <- cbind(key, LEMMA.LTMU)

# Rename variables whose names were lost in the cbind
names(LEMMA.LTMU)[names(LEMMA.LTMU)=="V1"] <- "x"
names(LEMMA.LTMU)[names(LEMMA.LTMU)=="V2"] <- "y"
names(LEMMA.LTMU)[names(LEMMA.LTMU)=="V3"] <- "relBA"
names(LEMMA.LTMU)[names(LEMMA.LTMU)=="V4"] <- "FIA_ID"

### Convert to a spatial data frame
xy <- LEMMA.LTMU[,c("x","y")]
spdf <- SpatialPointsDataFrame(coords=xy, data = LEMMA.LTMU, proj4string = crs(LEMMA))
plot(spdf, pch=".")
plot(FS_LTMU, add=T, border="orange")
LEMMA.LTMU_bu <- LEMMA.LTMU

### Save spatial data frame
writeOGR(obj=spdf, dsn = "LEMMA_units", layer = "LEMMA_LTMU", driver = "ESRI Shapefile")

### Maybe delete pixels with zero biomass according to LEMMA
LEMMA.LTMU.nonzero <- subset(LEMMA.LTMU, LEMMA.LTMU$All_BM_kgha >0)
LEMMA.LTMU.spdf.nonzero <- subset(spdf, spdf$All_BM_kgha > 0)
plot(LEMMA.LTMU.spdf.nonzero, pch=".")
plot(FS_LTMU, add=T, border="orange")

### Find mean live biomas
mean(LEMMA.LTMU.spdf.nonzero$All_BM_kgha)/1000

#####################################################################################
### Calculate live biomass for each management unit
#####################################################################################

# Only need to do the below steps if you erased results above
if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
}
strt<-Sys.time()
LEMMA.units <- readOGR(dsn="LEMMA_units", layer = "LEMMA_units_nokc")
print(Sys.time()-strt)

# Add field for live BM in Mg/ha
LEMMA.units$BM_L_Mgha <- LEMMA.units$All_BM_/1000

# Average by management unit
LEMMA.units$UNIT <- 0

# this doesn't work yet
#for(i in 1:nrow(LEMMA.units)){
  if(LEMMA.units$Pol_ID %in% c(1,2,3,4,5,6)){
    LEMMA.units$UNIT <- "MH"
  } else {
    LEMMA.units$UNIT <- 0
  }
}
# Check using:
summary(as.factor(LEMMA.units$Pol_ID))
summary(as.factor(LEMMA.units$UNIT))

LEMMA.MH <- subset(LEMMA.units, LEMMA.units$Pol_ID <6)

unit.names <- c("CSP", "ESP", "SQNP", "SNF", "ENF", "LNP")

i <- 1

for(i in 1:length(unit.names)) {
  spdf <- subset(LEMMA.units, LEMMA.units$Pol_ID==(i+6))
  assign(paste("LEMMA.", unit.names[1], sep=""), spdf)
}
LEMMA.CSP <- subset(LEMMA.units, LEMMA.units$Pol_ID==7)
LEMMA.ESP <- LEMMA.units[,"Pol_ID"==8]
LEMMA.SQNP <- LEMMA.units[,"Pol_ID"==9]
LEMMA.SNF <- LEMMA.units[,"Pol_ID"==10]
LEMMA.ENF <- LEMMA.units[,"Pol_ID"==11]
LEMMA.LNP <- LEMMA.units[,"Pol_ID"==12]

save(LEMMA.CSP, file="LEMMA_units/LEMMA_CSP.Rdata")
LEMMA.CSP <-load(file="LEMMA_CSP.Rdata")
plot(LEMMA)

UNIT <- c(as.character(unit.names), "KCNP", "LTMU")
LEMMA.means <- as.data.frame(UNIT)
LEMMA.means$BM_L_Mgha <- 0
LEMMA.means$area.sqm <- 0
LEMMA.means$BM_D_Mgha <- 0
LEMMA.means$BM_D_tot <- 0
LEMMA.means$noBA_BM_D_Mgha <- 0
LEMMA.means$noBA_BM_D_tot <- 0
LEMMA.means$noBA_BM_D_tot <- 0
LEMMA.means$Perc_Ch <- 0
LEMMA.means$noBA_Perc_Ch <- 0
LEMMA.means[UNIT=="LTMU","BM_L_Mgha"] <- 153.2
LEMMA.means[UNIT=="KCNP","BM_L_Mgha"] <- 145.6
LEMMA.means[UNIT=="KCNP","BM_D_Mgha"] <- 28
LEMMA.means[UNIT=="KCNP","BM_D_tot"] <- 2106348
LEMMA.means[UNIT=="KCNP","noBA_BM_D_Mgha"] <- 19.3
LEMMA.means[UNIT=="KCNP","noBA_BM_D_tot"] <- 1452081
