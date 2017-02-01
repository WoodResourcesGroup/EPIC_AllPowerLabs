
##### ***THINGS YOU NEED TO CHANGE BETWEEN RUNS*** #########
EPIC <- "C:/Users/Battles Lab/Box Sync/EPIC-Biomass" # Define where your EPIC-BIOMASS folder is located in Box Sync
UNIT <- "ENF"  ## Define which unit you're doing. Options are: MH  CSP  ESP  SQNP SNF  ENF  LNP  KCNP  LTMU
#########################################################################################################################

library(rgdal)  
library(raster)  
options(digits = 5)

### Open GNN LEMMA data (see script crop_LEMMA.R for where LEMMA.gri comes from)
setwd(paste(EPIC, "/GIS Data/LEMMA_gnn_sppsz_2014_08_28/", sep=""))
LEMMA <- raster("LEMMA.gri")

### OPEN DROUGHT MORTALITY POLYGONS (see script transform_ADS.R for where "drought" comes from)
setwd(paste(EPIC, "/GIS Data/", sep=""))
drought <- readOGR("tempdir", "drought16")
drought <- spTransform(drought, crs(LEMMA))
drought_bu <- drought # backup so that I don't need to re-read if I accidentally override drought

### Open unit perimeters - all are in the layer "units" besides KCNP and LTMU -- do these steps every 
### time no matter which one you're running
units <- readOGR(dsn = "units", layer = "units_nokc")
units <- spTransform(units, crs(LEMMA))
KCNP <- readOGR(dsn = "Boundary_KingsNP_20100209", layer = "Boundary_KingsNP_20100209")
KCNP <- spTransform(KCNP, crs(LEMMA))
LTMU <- readOGR(dsn = "tempdir", layer = "FS_LTMU")
LTMU <- spTransform(LTMU, crs(LEMMA))
plot(units)
plot(KCNP, add=T)
plot(LTMU, add=T)

### Single out the unit of interest
if(UNIT %in% units$UNIT){
  unit <- units[units$UNIT==UNIT,]
} else if (UNIT=="KCNP"){
  unit <- KCNP
} else
  unit <- LTMU

drought <- crop(drought, extent(unit)) # *****comment out this step for running on the entire drought data set*****
writeOGR(drought, dsn="drought_byunit", layer=paste("drought_", UNIT, sep=""), driver="ESRI Shapefile", overwrite_layer = T)

### Identify species in LEMMA
spp <- LEMMA@data@attributes[[1]][,"TREEPLBA"]
spp.names <- sort(unique(spp))

### Group conifers by genus based on plants.usda.gov
Cedars_Larch <- c("CADE27", "THPL", "CHLA", "CHNO", "LALY", "LAOC", "SEGI2", "SESE3") 
Dougfirs <- c("PSMA", "PSME") 
Firs <- c("ABAM", "ABBR", "ABGRC", "ABLA", "ABPRSH", "TSHE", "TSME")
Pines <- c("PIAL", "PIAR", "PIAT", "PIBA", "PICO", "PICO3", "PIFL2", "PIJE", "PILA", "PILO", "PIMO", "PIMO3", "PIMU", "PIPO", "PIRA2", "PISA2") 
Spruces <- c("PIEN", "PISI") 

### Group hardwoods and junipers by Jenkins species group based on Jenkins et al 2003 and plants.usda.gov
hardwood.names <- subset(spp.names, !spp.names %in% c(Cedars_Larch, Dougfirs, Firs, Pines, Spruces))
mh <- c("JUHI", "AECA", "ARME", "CHCH7", "CONU4", "FRLA", "LIDE3", "PLRA", "PRVI", "UMCA")
wo <- c("JUCA7", "JUOC", "ACGL", "CELE3", "CUSA3", "JUOS", "OLTE", "PREM", "PRGLT", "PRPU")
mb <- c("ACMA3", "BEPA", "BEPAC", "")
aa <- c("ALRH2", "ALRU2", "POBAT", "POFR2", "POTR5", "SAAL2", "SALIX", "SANI")
mo <- c("QUAG", "QUDO", "QUEN", "QUERC", "QUGA4", "QUKE", "QULO", "QUWI2", "QUCH2")

### Create table of dia -> biomass conversion parameters based on Jenkins paper - for now only broken down by broad genus category, but could do it by individual species later if we want
# Source: J. C. Jenkins, D. C. Chojnacky, L. S. Heath, and R. A. Birdsey, "National-scale biomass estimators for United States tree species," For. Sci., vol. 49, no. 1, pp. 12-35, 2003.
# biomass = exp(B0 + B1*ln(dbh))
types <- c("Cedars_Larch", "Dougfirs", "Firs", "Pines", "Spruces", "mh", "wo", "mb", "aa", "mo")
B0 <- as.numeric(c(-2.0336, -2.2304, -2.5384, -2.5356, -2.0773, -2.4800, -.7152, -1.9123, -2.2094, -2.0127))
B1 <- as.numeric(c(2.2592, 2.4435, 2.4814, 2.4349, 2.3323, 2.4835, 1.7029, 2.3651, 2.3867, 2.4342))
BM_eqns <- cbind(types, B0, B1)

# *Note* Species groups (SG) include aspen/alder/cottonwood/willow (aa), hard maple/oak/hickory/beech (mo), mixed hardwood (mh), soft maple/birch (mb), cedar/larch (cl), Douglas-fir (df), true fir/hemlock (tf), pine (pi), spruce (sp), and woodland conifer and softwood (wo).

### Set up parallel cores for faster runs
library(doParallel)
detectCores()
no_cores <- detectCores() - 1 # Use all but one core on your computer
c1 <- makeCluster(no_cores)
registerDoParallel(c1)

### Check out which polygons will be skipped by the analysis - see script "find_skipped.R"
#setwd("~/cec_apl/Biomass/R_scripts")
#readRDS("zero_i_16_CR.Rdata") # for test
#readRDS("zero_i_16.Rdata")    # for final
###################################################################
# Function that does the bulk of the analysis

inputs = 1:nrow(drought)

results <- foreach(i=inputs, .combine = rbind, .packages = c('raster','rgeos'), .errorhandling="remove") %dopar% {
  single <- drought[i,] # select one polygon
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
  
  # The below for subloop calculates biomass per tree based on the average dbh of dominant and codominant trees for 
  # the most common species in each raster cell:
  merge$BM_tree_kg <- 0 # create biomass per tree variable
  merge$D_BM_kg <- 0 # create dead biomass variable
  merge$relNO <- 0 # create relative number of trees variable
  for (i in 1:nrow(merge)) {
    cell <- merge[i,]
    if (cell$TREEPLBA %in% Cedars_Larch) { 
      num <- (B0[1] + B1[1]*log(cell$QMD_DOM)) # apply formula for biomass, but w/o the exp. 
    } else if (cell$TREEPLBA %in% Dougfirs) {
      num <- (B0[2] + B1[2]*log(cell$QMD_DOM))
    } else if (cell$TREEPLBA %in% Firs) {
      num <- (B0[3] + B1[3]*log(cell$QMD_DOM))
    } else if (cell$TREEPLBA %in% Pines) {
      num <- (B0[4] + B1[4]*log(cell$QMD_DOM))
    } else if (cell$TREEPLBA %in% Spruces) {
      num <- (B0[5] + B1[5]*log(cell$QMD_DOM))
    } else if (cell$TREEPLBA %in% mh) {
      num <- (B0[6] + B1[6]*log(cell$QMD_DOM))  
    } else if (cell$TREEPLBA %in% wo) {
      num <- (B0[7] + B1[7]*log(cell$QMD_DOM))  
    } else if (cell$TREEPLBA %in% mb) {
      num <- (B0[8] + B1[8]*log(cell$QMD_DOM))
    } else if (cell$TREEPLBA %in% aa) {
      num <- (B0[9] + B1[9]*log(cell$QMD_DOM))
    } else if (cell$TREEPLBA %in% mo) {
      num <- (B0[10] + B1[10]*log(cell$QMD_DOM))
    } else {
      num <- 0
    }
    if (num == 0) {
      merge[i,]$BM_tree_kg <- 0 # assign 0 if no trees
    } else {
      merge[i,]$BM_tree_kg <- exp(num) # finish the formula to assign biomass per tree in that pixel
    }
  }
  
  # Find biomass per pixel using biomass per tree and estimated number of trees
  pmerge <- merge(pcoords, merge, by.x ="V1", by.y = "ID") # pmerge has a line for every pixel
  # problem here
  tot_NO <- single@data$NO_TREES1 # Total number of trees in the polygon
  pmerge$relNO <- ifelse(pmerge$BA_GE_3>0.1, tot_NO/length(subset(pmerge$BA_GE_3, pmerge$BA_GE_3>0.01)), 0)
  # and total number of trees in polygon
  pmerge$D_BM_kg <- pmerge$relNO*pmerge$BM_tree_kg # D_BM_kg is total dead biomass in that pixel, based on biomass per tree and estimated number of trees in pixel
  
  # Create vectors that are the same length as pmerge to combine into final table:
  D_Pol_BM_kg <- rep(sum(pmerge$D_BM_kg), nrow(pmerge)) # Sum biomass over the entire polygon 
  Av_BM_TR <- D_Pol_BM_kg/tot_NO # Calculate average biomass per tree based on total polygon biomass and number of trees in the polygon
  QMD_DOM <- pmerge$QMD_DOM # Find the average of the pixels' quadratic mean diameters 
  TREEPL <-  pmerge$TREEPLBA # Find the tree species that has a plurality in the most pixels
  Pol.x <- rep(gCentroid(single)@coords[1], nrow(pmerge)) # Find coordinates of center of polygon
  Pol.y <- rep(gCentroid(single)@coords[2], nrow(pmerge))
  RPT_YR <- rep(single@data$RPT_YR, nrow(pmerge)) # Create year vector
  Pol.NO_TREES1 <- rep(single@data$NO_TREES1, nrow(pmerge)) # Create number of dead trees vector
  Pol.Shap_Ar <- rep(single@data$Shap_Ar, nrow(pmerge)) # Create area vector
  Pol.Pixels <- rep(s, nrow(pmerge)) # number of pixels
  
  # Estimate biomass of live AND dead trees based on LEMMA values of biomass per pixel:
  All_BM_kgha <- pmerge$BPH_GE_3_CRM 
  All_Pol_BM_kgha <- rep(mean(pmerge$BPH_GE_3_CRM),nrow(pmerge)) # Average across polygons
  THA <- pmerge$TPH_GE_3 
  
  # Bring it all together
  final <- cbind(pmerge$x, pmerge$y, pmerge$D_BM_kg, pmerge$relNO,pmerge$relBA, pmerge$V1, Pol.x, Pol.y, RPT_YR,Pol.NO_TREES1, 
                 Pol.Shap_Ar,D_Pol_BM_kg,All_BM_kgha,All_Pol_BM_kgha,THA, QMD_DOM,Av_BM_TR, Pol.ID, TREEPL) #
  final <- as.data.frame(final)
  final$All_Pol_NO <- (single@data$Shap_Ar/10000*900)*THA # Estimate total number of trees in the polygon
  final$All_Pol_BM <- (single@data$Shap_Ar/10000*900)*All_Pol_BM_kgha # Estimate total tree biomass in the polygon
  final$D_BM_kgha <- final$V3/.09 # Find kg per ha of dead biomass
  return(final)
}

# Create a key for each pixel (row)
key <- seq(1, nrow(results)) 
results <- cbind(key, results)
# Rename variables whose names were lost in the cbind
names(results)[names(results)=="V1"] <- "x"
names(results)[names(results)=="V2"] <- "y"
names(results)[names(results)=="V3"] <- "D_BM_kg"
names(results)[names(results)=="V4"] <- "relNO"
names(results)[names(results)=="V5"] <- "PlotID"

### Convert to a spatial data frame
xy <- results[,c("x","y")]
spdf <- SpatialPointsDataFrame(coords=xy, data = results, proj4string = crs(LEMMA))

### Plot to make sure results match unit perimeter matches drought polygons
plot(spdf, pch=".")
plot(drought, add=T, border="blue")
plot(unit, add=T, border="orange")

### Save spatial data frame
writeOGR(obj=spdf, dsn = "Results_2016", layer = paste("Results_2016_",UNIT,"_noBA", sep=""), driver = "ESRI Shapefile", overwrite_layer = T)
setwd(paste(EPIC, "/GIS Data/Results_2016", sep=""))
save(spdf, file=paste("Results_2016_",UNIT,"_noBA.Rdata", sep=""))
load(file=paste("Results_2016_",UNIT,"_noBA.Rdata", sep=""))

### Save version masked to just the management unit

## try converting to raster for this part
try.raster <- rasterFromXYZ(spdf[,c("x","y","D_BM_kgh")], crs = crs(spdf))
plot(try.raster)
raster.small <- mask(try.raster, unit)
  
  crop(LEMMA, extent(single)) # crop LEMMA GLN data to the size of that polygon
clip2 <- mask(clip1, single) # fit the cropped LEMMA data to the shape of the polygon


library(rgeos)
unit <- spTransform(unit, crs(spdf))
strt<-Sys.time()
intersect <- gIntersects(spdf, unit, byid=T) 
intersect.df <- as.data.frame(intersect)
length(subset(intersect.df, intersect.df=="TRUE"))

testspdf <- subset(spdf, spdf$key %in% intersect)
print(Sys.time()-strt)
# Takes 30 min on Turbo!

KCNP.pts.intersect.id <- as.numeric(sapply(KCNP.pts.intersect,"[[",2))
KCNP.pts.extract <- KCNP_16[KCNP.pts.intersect.id, ]
KCNP_16 <- subset(KCNP_16, KCNP_16$key %in% KCNP.pts.intersect.id)
plot(KCNP_16, add=T, col="pink", pch=".")
plot(drought_KCNP, add=T)

writeOGR(obj=KCNP_16, dsn = "Results_2016", layer = "Results_2016_KCNP_mask", driver = "ESRI Shapefile")

### For editing: clear variables in loop
remove(cell, final, L.in.mat, mat, mat2, merge, pcoords, pmerge, zeros, All_BM_kgha, All_Pol_BM_kgha, Av_BM_TR, D_Pol_BM_kg, 
       ext, i, num, Pol.ID, Pol.NO_TREES1, Pol.Pixels, Pol.Shap_Ar, Pol.x, Pol.y, QMDC_DOM, RPT_YR, s)
remove(clip1, clip2, single, spp, spp.names, THA, tot_NO, TREEPL, types)
remove(no.pixels, QMD_DOM, tab)

# Use area of KCNP to calculate dead biomass density 
KCNP_16 <- readOGR(dsn = "Results_2016", layer = "Results_2016_KCNP_mask")
KCNP_16_D_BM_sum_Mg <- sum(KCNP_16$D_BM_kg)/1000                                                               
KCNP_16_D_BM_sum_Mg
area(kc) # area in square meters
area.KCNP.ha <- sum(area(kc))/10000
area.KCNP.live.ha <- 752969700/10000 # from script LEMMA_live_units
KCNP_DBM_Mgha_16 <- KCNP_16_D_BM_sum_Mg/area.KCNP.ha
KCNP_DBM_Mgha_16

KCNP_DBM_Mgha_16_Liveonly <- KCNP_16_D_BM_sum_Mg/area.KCNP.live.ha
KCNP_DBM_Mgha_16_Liveonly


### Check stuff out 

##### NEED TO GO THROUGH THESE FOR SQNP, NAMES ARE DIFFERENT AFTER READING SPATIAL FILE AND I HAVEN'T CHECKED THESE TESTS

# Define Mg/ha
KCNP_16$D_BM_Mgh <- KCNP_16$D_BM_kgh/1000
plot(sort(KCNP_16$D_BM_Mgh))
plot(sort(KCNP_16$D_BM_Mgh), ylim=c(0,500)) # There's an inflection point at around 500 Mgh and I 
## want to figure out what's going on there. Plot results in ArcMap with diff color for < and 
## > 200 Mgh
max(KCNP_16$D_BM_Mgh)

# Max Mg per pixel of dead biomass is 100,000. That's way too high! Investigate further below.
hist(KCNP_16$D_BM_Mgh, breaks=100)
length(subset(KCNP_16$D_BM_Mgh, KCNP_16$D_BM_Mgh<0))
nrow(KCNP_16)
# How do dead trees per polygon and relative number of dead trees per pixel look?
hist(KCNP_16$relNO)
plot(sort(KCNP_16$relNO))
plot(sort(KCNP_16$relNO), ylim=c(0,100))
## There's a stark inflection point at 20 dead trees per pixel. I might need to change the way I assign
## relative number of dead trees
max(KCNP_16$relNO)
# It looks like my results are showing relNO of trees per pixel as high as 84, which seems reasonable
# Investigate how high that is by comparing to THA
hist(KCNP_16$THA*.09)
max(KCNP_16$THA*.09) # higher than relNO, as it should be, because it includes live trees
max(KCNP_16$Pol.NO_TREES1/(KCNP_16$Pol.Shap_Ar/10000)) # average dead trees per acre across polygon is close to relNO. Good!
LEMMA_KCNP <- crop(LEMMA, extent(units[9,])) # crop LEMMA GLN data to the size of that polygon
LEMMA_KCNP <- mask(LEMMA_KCNP, units[9,]) # fit the cropped LEMMA data to the shape of the polygon
hist(LEMMA_KCNP@data@attributes[[1]]$TPH_GE_3) # total TPH should not exceed 10,000, so I'm good
hist(KCNP_16$THA)
hist((LEMMA_KCNP@data@attributes[[1]]$BPH_GE_3_CRM/1000)) # total biomass per hectare goes up to 1000 Mg, so above max of 
max((LEMMA_KCNP@data@attributes[[1]]$BPH_GE_3_CRM/1000))
# dead biomass per hectare of 1000 seems ok

### Compare LEMMA total biomass per hectare to results estimates
hist(KCNP_16$All_BM_kgha/1000)

# Check average dead biomass per pixel averaged across all pixels in each polygon to see if they look ok
plot(unique(KCNP_16$Pol.NO_TREES1/KCNP_16$Pol.Shap_Ar), main="number of dead trees per sq m in polygon")
# Compare to that of the original drought polygon layer
points(drought_KCNP$NO_TREES1/drought_KCNP$Shap_Ar, main="number of dead trees per sq m in polygon from original drought data", col="pink")
### THESE TWO PLOTS ARE IDENTICAL, AS THEY SHOULD BE



