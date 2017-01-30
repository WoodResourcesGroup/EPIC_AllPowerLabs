#########################################################################################################################
######## CALCULATE TOTAL LIVE BIOMASS IN EACH MANAGEMENT UNIT FROM LEMMA DATA
#########################################################################################################################

if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
}

units <- readOGR(dsn = "units", layer="units_nokc")

if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/LEMMA_gnn_sppsz_2014_08_28/")
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

# start timer
strt<-Sys.time()

# function that does the bulk of the analysis

inputs = 1:nrow(units) # units[3:8] is all polygons in MH

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
                All_BM_kgha,All_Pol_BM_kgha,THA, QMD_DOM,Pol.ID) 
  final <- as.data.frame(final)
  final$All_Pol_NO <- (area(single)/10000)*THA # Estimate total number of trees in the polygon
  final$All_Pol_BM <- (area(single)/10000)*900*All_Pol_BM_kgha # Estimate total tree biomass in the polygon
  final$D_BM_kgha <- final$V3/.09 # Find kg per ha of dead biomass
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

# function that does the bulk of the analysis

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
                 All_BM_kgha,All_Pol_BM_kgha,THA, QMD_DOM,Pol.ID) 
  final <- as.data.frame(final)
  final$All_Pol_NO <- (area(single)/10000)*THA # Estimate total number of trees in the polygon
  final$All_Pol_BM <- (area(single)/10000)*900*All_Pol_BM_kgha # Estimate total tree biomass in the polygon
  final$D_BM_kgha <- final$V3/.09 # Find kg per ha of dead biomass
  return(final)
}

# Create a key for each pixel (row)
key <- seq(1, nrow(LEMMA.kc)) 
LEMMA.kc <- cbind(key, LEMMA.kc)
print(Sys.time()-strt)
# only takes 5 min on Carmen's dell 

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

### Save spatial data frame
writeOGR(obj=spdf, dsn = "LEMMA_units", layer = "LEMMA_kc", driver = "ESRI Shapefile")
