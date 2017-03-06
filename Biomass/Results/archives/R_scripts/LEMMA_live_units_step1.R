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
# Make plots smaller 
plots <- plots[,c("VALUE","TPH_GE_3","TPH_GE_25", 
"BPH_GE_3_CRM","BPH_GE_25_CRM", "FORTYPBA", "ESLF_NAME", 
"TREEPLBA","QMDC_DOM")]

### Open units perimeters
setwd(paste(EPIC, "/GIS Data", sep=""))
units <- readOGR(dsn = "units", layer="units_nokc")
units <- spTransform(units, crs(LEMMA))

# Open kc
setwd(paste(EPIC, "/GIS Data", sep=""))
kc <- readOGR(dsn = "Boundary_KingsNP_20100209", layer = "Boundary_KingsNP_20100209")
kc <- spTransform(kc, crs(LEMMA))

# Open LTMU
setwd(paste(EPIC, "/GIS Data", sep=""))
FS_LTMU <- readOGR(dsn = "tempdir", layer = "FS_LTMU")
FS_LTMU <- spTransform(FS_LTMU, crs(LEMMA))


# crop LEMMA to make it more manageable
LEMMA <- crop(LEMMA, extent(units)) # takes a few moments

###############################################################################
### FOR ALL UNITS EXCEPT KCNP AND LTMU 
###############################################################################

### Set up parallel cores for faster runs
library(doParallel)
library(foreach)
detectCores()
no_cores <- detectCores() - 1 # Use all but one core on your computer
c1 <- makeCluster(no_cores)
registerDoParallel(c1)

### Function that does the bulk of the analysis
inputs = 1:nrow(units)
strt<-Sys.time()
# foreach loop
i <- 10
LEMMA.units <- foreach(i=inputs, .combine = rbind, .packages = c('raster','rgeos','dplyr'), .errorhandling="remove") %dopar% {
  single <- units[i,] # select one polygon
  clip1 <- crop(LEMMA, extent(single)) # crop LEMMA GLN data to the size of that polygon
  # fit the cropped LEMMA data to the shape of the polygon, unless the polygon is too small to do so
  clip2 <- mask(clip1, single) #takes a long time for SNF for some reason
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
  pmerge <- subset(pmerge, pmerge$FORTYPBA %in% for_types)
   # Create vectors that are the same length as pmerge to combine into final table:
  Pol.Pixels <- rep(nrow(pmerge), nrow(pmerge)) # number of pixels
  Pol.ID <- rep(i, nrow(pmerge))
  # Estimate biomass of live AND dead trees based on LEMMA values of biomass per pixel:
  UNIT <- rep(single@data$UNIT, nrow(pmerge))
  pmerge <- pmerge[,c("V1","x", "y", "TPH_GE_3","TPH_GE_25", 
                      "BPH_GE_3_CRM","BPH_GE_25_CRM","FORTYPBA", "ESLF_NAME", 
                      "TREEPLBA","QMDC_DOM")]
  final <- cbind(pmerge, Pol.Pixels,Pol.ID, UNIT)
  return(final)
}
print(Sys.time()-strt)

# Create a key for each pixel (row)
key <- seq(1, nrow(LEMMA.units)) 
LEMMA.units <- cbind(key, LEMMA.units)

# Rename variables whose names were lost in the cbind
names(LEMMA.units)[names(LEMMA.units)=="V1"] <- "FIA_ID"

### Convert to a spatial data frame
xy <- LEMMA.units[,c("x","y")]
spdf <- SpatialPointsDataFrame(coords=xy, data = LEMMA.units, proj4string = crs(LEMMA))
plot(spdf, pch=".")
plot(units, add=T, border="orange")

### Save spatial data frame
LEMMA_units <- spdf
setwd(paste(EPIC, "/GIS Data/LEMMA_units", sep=""))
save(LEMMA_units, file="LEMMA_units.Rdata")

###*****Workaround: did SNF separately. Saved it below:
# Create a key for each pixel (row)
LEMMA.units <- final
key <- seq(1, nrow(LEMMA.units)) 
LEMMA.units <- cbind(key, LEMMA.units)

# Rename variables whose names were lost in the cbind
names(LEMMA.units)[names(LEMMA.units)=="V1"] <- "FIA_ID"

### Convert to a spatial data frame
xy <- LEMMA.units[,c("x","y")]
spdf <- SpatialPointsDataFrame(coords=xy, data = LEMMA.units, proj4string = crs(LEMMA))
plot(spdf, pch=".")
plot(units, add=T, border="orange")

### Save spatial data frame
LEMMA_SNF <- spdf
setwd(paste(EPIC, "/GIS Data/LEMMA_units", sep=""))
save(LEMMA_SNF, file="LEMMA_SNF.Rdata")

###############################################################################
### REPEAT WITH KC 
###############################################################################
units <- kc
inputs = 1:nrow(units)
strt<-Sys.time()
i <- 1
LEMMA.kc <- foreach(i=inputs, .combine = rbind, .packages = c('raster','rgeos','dplyr'), .errorhandling="remove") %dopar% {
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
  pmerge <- subset(pmerge, pmerge$FORTYPBA %in% for_types)
  # Create vectors that are the same length as pmerge to combine into final table:
  Pol.Pixels <- rep(nrow(pmerge), nrow(pmerge)) # number of pixels
  Pol.ID <- rep(i, nrow(pmerge))
  # Estimate biomass of live AND dead trees based on LEMMA values of biomass per pixel:
  pmerge <- pmerge[,c("V1","x", "y", "TPH_GE_3","TPH_GE_25", 
                      "BPH_GE_3_CRM","BPH_GE_25_CRM","FORTYPBA", "ESLF_NAME", 
                      "TREEPLBA","QMDC_DOM")]
  final <- cbind(pmerge, Pol.Pixels,Pol.ID)
  return(final)
}
print(Sys.time()-strt)

# Create a key for each pixel (row)
key <- seq(1, nrow(LEMMA.kc)) 
LEMMA.kc <- cbind(key, LEMMA.kc)

# Rename variables whose names were lost in the cbind
names(LEMMA.kc)[names(LEMMA.kc)=="V1"] <- "FIA_ID"

### Convert to a spatial data frame
xy <- LEMMA.kc[,c("x","y")]
spdf <- SpatialPointsDataFrame(coords=xy, data = LEMMA.kc, proj4string = crs(LEMMA))
plot(spdf, pch=".")
plot(units, add=T, border="orange")

### Save spatial data frame
LEMMA_KCNP <- spdf
setwd(paste(EPIC, "/GIS Data/LEMMA_units", sep=""))
save(LEMMA_KCNP, file="LEMMA_KCNP.Rdata")

###############################################################################
### REPEAT WITH LTMU
############################################################################### 
units <- FS_LTMU
inputs = 1:nrow(units)
strt<-Sys.time()
LEMMA.LTMU <- foreach(i=inputs, .combine = rbind, .packages = c('raster','rgeos','dplyr'), .errorhandling="remove") %dopar% {
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
  pmerge <- subset(pmerge, pmerge$FORTYPBA %in% for_types)
  # Create vectors that are the same length as pmerge to combine into final table:
  Pol.Pixels <- rep(nrow(pmerge), nrow(pmerge)) # number of pixels
  Pol.ID <- rep(i, nrow(pmerge))
  # Estimate biomass of live AND dead trees based on LEMMA values of biomass per pixel:
  pmerge <- pmerge[,c("V1","x", "y", "TPH_GE_3","TPH_GE_25", 
                      "BPH_GE_3_CRM","BPH_GE_25_CRM","FORTYPBA", "ESLF_NAME", 
                      "TREEPLBA","QMDC_DOM")]
  final <- cbind(pmerge, Pol.Pixels,Pol.ID)
  return(final)
}
print(Sys.time()-strt)

# Create a key for each pixel (row)
key <- seq(1, nrow(LEMMA.LTMU)) 
LEMMA.LTMU <- cbind(key, LEMMA.LTMU)

# Rename variables whose names were lost in the cbind
names(LEMMA.LTMU)[names(LEMMA.LTMU)=="V1"] <- "FIA_ID"

### Convert to a spatial data frame
xy <- LEMMA.LTMU[,c("x","y")]
spdf <- SpatialPointsDataFrame(coords=xy, data = LEMMA.LTMU, proj4string = crs(LEMMA))
plot(spdf, pch=".")
plot(units, add=T, border="orange")

### Save spatial data frame
LEMMA_LTMU <- spdf
setwd(paste(EPIC, "/GIS Data/LEMMA_units", sep=""))
save(LEMMA_LTMU, file="LEMMA_LTMU.Rdata")

### For editing only: clear variables in loop
remove(cell, final, L.in.mat, mat, mat2, merge, pcoords, pmerge, zeros, All_BM_kgha, All_Pol_BM_kgha, Av_BM_TR, D_Pol_BM_kg, 
       ext, i, num, Pol.ID, Pol.NO_TREES1, Pol.Pixels, Pol.Shap_Ar, Pol.x, Pol.y, QMDC_DOM, RPT_YR, s)
remove(clip1, clip2, single, spp, spp.names, THA, tot_NO, TREEPL, types)
remove(no.pixels, QMD_DOM, tab, results)
remove(raster.mask, try.raster, spdf, spdf_ESP, key, counted, freq, BPH_GE_3_CRM)
