#########################################################################################################################
######## CALCULATE TOTAL LIVE BIOMASS IN EACH MANAGEMENT UNIT FROM LEMMA DATA - STEP 1
#########################################################################################################################

## *NOTE: could save some time by saving each LEMMA_units result as .Rdata instead of spatial data

library(rgdal)
library(raster)

### Define EPIC as the EPIC-Biomass folder for easier setwd later on
#EPIC <- "C:/Users/Battles Lab/Box Sync/EPIC-Biomass" # for Turbo
EPIC <- "C:/Users/Carmen/Box Sync/EPIC-Biomass"

### Open GNN LEMMA data (see script crop_LEMMA.R for where LEMMA.gri comes from)
setwd(paste(EPIC, "/GIS Data/LEMMA_gnn_sppsz_2014_08_28/", sep=""))
LEMMA <- raster("LEMMA.gri")

### Open LEMMA PLOT data
setwd(paste(EPIC))
plots <- read.csv("SPPSZ_ATTR_LIVE.csv")
land_types <- unique(plots$ESLF_NAME)
for_types <- unique(plots$FORTYPBA)[2:932]

### Open units perimeters
setwd(paste(EPIC, "/GIS Data", sep=""))
units <- readOGR(dsn = "units", layer="units_nokc")
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
strt<-Sys.time()
# foreach loop
LEMMA.units <- foreach(i=inputs, .combine = rbind, .packages = c('raster','rgeos','dplyr'), .errorhandling="remove") %dopar% {
  single <- units[i,] # select one polygon
  clip1 <- crop(LEMMA, extent(single)) # crop LEMMA GLN data to the size of that polygon
  # fit the cropped LEMMA data to the shape of the polygon, unless the polygon is too small to do so
  if(length(clip1) >= 4){
    clip2 <- mask(clip1, single)
  } else 
    clip2 <- clip1
  pcoords <- cbind(clip2@data@values, coordinates(clip2)) # save the coordinates of each pixel
  pcoords <- as.data.frame(pcoords)
  pcoords <- na.omit(pcoords) # get rid of NAs in coordinates table (NAs are from empty cells in box around polygon)
  #ext <- extract(clip2, single) # extracts data from the raster - each extracted value is the FIA plot # of the raster cell, which corresponds to detailed data in the attribute table of LEMMA
  #tab <- lapply(ext, table) # creates a table that counts how many of each raster value there are in the polygon
  counted <- pcoords %>% count(V1)
  mat <- as.data.frame(counted)
  s <- sum(mat[2]) # Counts total raster cells the polygon - this is different from length(clip2tg) because it doesn't include NAs
  freq <- (mat[2]/s) # gives fraction of polygon occupied by each plot type. Adds up to 1 for each polygon.
  mat2 <- cbind(mat, freq) # creates table with FIA plot IDs in polygon, number of each, and relative frequency of each
  colnames(mat2)[3] <- "freq"
  merge <- merge(mat2, plots, by.x = "V1", by.y="VALUE")
  
  # Find biomass per pixel using biomass per tree and estimated number of trees
  pmerge <- merge(pcoords, merge, by ="V1") # pmerge has a line for every pixel
   # Create vectors that are the same length as pmerge to combine into final table:
  Pol.Pixels <- rep(nrow(pmerge), nrow(pmerge)) # number of pixels
  # Estimate biomass of live AND dead trees based on LEMMA values of biomass per pixel:
  pmerge <- subset(pmerge, pmerge$FORTYPBA %in% for_types)
  pmerge <- pmerge[,c("V1","x", "y", "TPH_GE_3","TPH_GE_25", "TPH_GE_50","TPH_GE_75",
                      "BPH_GE_3_CRM","BPHC_GE_25_CRM","BPH_GE_50_CRM", "FORTYPBA", "ESLF_NAME", 
                      "TREEPLBA","QMDC_DOM")]
  final <- pmerge
  return(final)
}
print(Sys.time()-strt)

# Create a key for each pixel (row)
key <- seq(1, nrow(LEMMA.units)) 
LEMMA.units <- cbind(key, LEMMA.units)

# only takes 10 min on Carmen's dell

# Rename variables whose names were lost in the cbind
names(LEMMA.units)[names(LEMMA.units)=="V1"] <- "FIA_ID"

### Convert to a spatial data frame
xy <- LEMMA.units[,c("x","y")]
spdf <- SpatialPointsDataFrame(coords=xy, data = LEMMA.units, proj4string = crs(LEMMA))
plot(spdf, pch=".")
plot(units, add=T, border="orange")
LEMMA.units <- spdf
LEMMA.units.bu <- LEMMA.units

# Add field for live BM in Mg/ha
#LEMMA.units$BM_L_Mgha <- LEMMA.units$All_BM_/1000

### Save spatial data frame
setwd(paste(EPIC, "/GIS Data", sep=""))
writeOGR(obj=spdf, dsn = "LEMMA_units", layer = "LEMMA_units_nokc", driver = "ESRI Shapefile")
LEMMA_units <- spdf
save(spdf, file="LEMMA_units.Rdata") # HAVEN'T RUN THIS YET

## NEED TO MAKE SURE THE BELOW LOOP WORKS

### Separate out LEMMA.units by unit and save individual chunks for faster referencing 
# Start with units that are in the spdf units_nokc and have only one polygon per unit
unit.names <- c("CSP", "ESP", "SQNP", "SNF", "ENF", "LNP")
for(i in 1:length(unit.names)) {
  spdf <- subset(LEMMA.units, LEMMA.units$Pol_ID==(i+6))
  assign(paste("LEMMA.", unit.names[i], sep=""), spdf)
  writeOGR(obj=spdf, dsn = "LEMMA_units", layer = paste("LEMMA_",unit.names[i],sep=""), 
           driver = "ESRI Shapefile", overwrite_layer = T)
  setwd(paste(EPIC, "/GIS Data/LEMMA_units", sep=""))
  save(spdf, file=paste("LEMMA", unit.names[i]))
}
# This loop takes a few min

# Then do MH
LEMMA.MH <- subset(LEMMA.units, LEMMA.units$Pol_ID <7)
plot(LEMMA.MH)
writeOGR(obj=spdf, dsn = "LEMMA_units", layer = "LEMMA_MH", driver = "ESRI Shapefile", overwrite_layer = T)

###############################################################################
### REPEAT WITH KC 
###############################################################################

setwd(paste(EPIC, "/GIS Data", sep=""))
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
setwd(paste(EPIC, "/GIS Data", sep=""))
FS_LTMU <- readOGR(dsn = "tempdir", layer = "FS_LTMU")
FS_LTMU <- spTransform(FS_LTMU, crs(LEMMA))

# start timer
strt<-Sys.time()
inputs = 1:nrow(FS_LTMU) 
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
# Add field for live BM in Mg/ha
LEMMA.LTMU$BM_L_Mgha <- LEMMA.LTMU$All_BM_/1000

### Convert to a spatial data frame
xy <- LEMMA.LTMU[,c("x","y")]
spdf <- SpatialPointsDataFrame(coords=xy, data = LEMMA.LTMU, proj4string = crs(LEMMA))
plot(spdf, pch=".")
plot(FS_LTMU, add=T, border="orange")
LEMMA.LTMU_bu <- LEMMA.LTMU

### Save spatial data frame
writeOGR(obj=spdf, dsn = "LEMMA_units", layer = "LEMMA_LTMU", driver = "ESRI Shapefile")

### For editing only: clear variables in loop
remove(cell, final, L.in.mat, mat, mat2, merge, pcoords, pmerge, zeros, All_BM_kgha, All_Pol_BM_kgha, Av_BM_TR, D_Pol_BM_kg, 
       ext, i, num, Pol.ID, Pol.NO_TREES1, Pol.Pixels, Pol.Shap_Ar, Pol.x, Pol.y, QMDC_DOM, RPT_YR, s)
remove(clip1, clip2, single, spp, spp.names, THA, tot_NO, TREEPL, types)
remove(no.pixels, QMD_DOM, tab, results)
remove(raster.mask, try.raster, spdf, spdf_ESP, key, counted, freq, BPH_GE_3_CRM)
