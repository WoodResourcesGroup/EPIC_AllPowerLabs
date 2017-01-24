install.packages("rgdal")
install.packages("raster") 

library(rgdal)  
library(raster)  

options(digits = 5)

### SETWD based on whether it's Carmen's computer or Jose's computer)
if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Battles Lab/Box Sync/EPIC-Biomass/GIS Data/LEMMA_gnn_sppsz_2014_08_28/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/LEMMA_gnn_sppsz_2014_08_28/")
}

### Open GNN LEMMA data (see script crop_LEMMA.R for where LEMMA.gri comes from)
LEMMA <- raster("LEMMA.gri")

### OPEN DROUGHT MORTALITY POLYGONS (see script transform_ADS.R for where "drought" comes from)
if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Battles Lab/Box Sync/EPIC-Biomass/GIS Data/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/")
}
drought <- readOGR("tempdir", "drought16")
drought_bu <- drought # backup so that I don't need to re-read if I accidentally override drought

### OPEN RAMIREZ DATA (see script transform_CRmort.R for where "CR_mort.tif" comes from)
### NOTE: We didn't end up analysing Ramirez data, so this step is only for cropping the data down for editing code in a manageably sized chunk
if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Battles Lab/Box Sync/EPIC-Biomass/GIS Data/tempdir/")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/GIS Data/tempdir")
}
CR_mort <- raster("CR_mort.tif")

### SKIP THIS SECTION FOR BATTLES RUNS 

  ### Narrow drought down to large-ish polygons (>2 ac) and those with more than one tree
  ### Might want to change these filters later
#  drought <- subset(drought, drought$ACRES > 2 & drought$NO_TREES1 > 1)
  ## print how much area this excludes: ~10,500 ACRES (out of ~33,000,000)
#  sum(subset(drought_bu, drought_bu$ACRES <= 2 | drought_bu$NO_TREES1 == 1)$ACRES)
#  sum(drought_bu$ACRES)
  ## print how many trees this excludes: ~50,000 trees (out of ~60,000,000)
#  sum(subset(drought_bu, drought_bu$ACRES <= 2 | drought_bu$NO_TREES1 == 1)$NO_TREES1)
#  sum(na.omit(drought_bu$NO_TREES1))

### Crop drought data to extent of Ramirez data 
drought <- crop(drought, extent(CR_mort)) # *****comment out this step for running on the entire drought data set*****

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

### Check that no species remain - this step is important when using new years of drought polygon data
remaining <- subset(spp.names, !spp.names %in% c(Cedars_Larch, Dougfirs, Firs, Pines, Spruces, mh, wo, mb, aa, mo))

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

########### Find which polygons aren't going to work - these will automatically be left out of the foreach() loop ###########
########### Skip this step if there is already a working "zero_i.Rdata" file in the Biomass -> R_scripts folder   ###########

# start timer - this process takes a while
strt<-Sys.time()

inputs = 1:nrow(drought)
no.go <- foreach(i = inputs, .combine = rbind, .packages = c('raster', 'rgeos'), .errorhandling = "stop") %dopar% {
  single <- drought[i,]
  clip1 <- crop(LEMMA, extent(single))
  clip2 <- mask(clip1, single)
  ext <- extract(clip2, single)
  no.pixels <- length(subset(ext[[1]], !is.na(ext[[1]])))
  return(no.pixels)
} 
# end timer
print(Sys.time()-strt)
# 3 min for CR_mort subset of drought - will take longer for whole drought dataset 

zeros <- subset(no.go, no.go == 0)
zeros <- as.data.frame(zeros)
zero.i <- row.names(zeros)
zero.i <- as.integer(gsub("result.", "", zero.i))

setwd("~/cec_apl/Biomass/R_scripts")
saveRDS(zero.i,file="zero_i_16.Rdata")

########### JUMP HERE IF SKIPPING THE ABOVE STEP

setwd("~/cec_apl/Biomass/R_scripts")
readRDS("zero_i_16_CR.Rdata") # for test
readRDS("zero_i_16.Rdata")    # for final
###################################################################
# start timer
strt<-Sys.time()

# function that does the bulk of the analysis

inputs = 1:nrow(drought)

result.lemma.p <- foreach(i=inputs, .combine = rbind, .packages = c('raster','rgeos'), .errorhandling="remove") %dopar% {
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
  merge$BM_tree_kg <- 0 # create biomass variable
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
  pmerge$relBA <- pmerge$BA_GE_3/sum(pmerge$BA_GE_3) # Create column for % of polygon BA in that pixel. 
  tot_NO <- single@data$NO_TREES1 # Total number of trees in the polygon
  pmerge$relNO <- tot_NO*pmerge$relBA # Assign approximate number of trees in that pixel based on proportion of BA in the pixel 
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
                 Pol.Shap_Ar,D_Pol_BM_kg,All_BM_kgha,All_Pol_BM_kgha,THA, QMD_DOM,Av_BM_TR, Pol.ID) #
  final <- as.data.frame(final)
  final$All_Pol_NO <- (single@data$Shap_Ar/10000*900)*THA # Estimate total number of trees in the polygon
  final$All_Pol_BM <- (single@data$Shap_Ar/10000*900)*All_Pol_BM_kgha # Estimate total tree biomass in the polygon
  final$D_BM_kgha <- final$V3/.09 # Find kg per ha of dead biomass
  return(final)
}
# Create a key for each pixel (row)
key <- seq(1, nrow(result.lemma.p)) 
result.lemma.p <- cbind(key, result.lemma.p)
# Rename variables whose names were lost in the cbind
names(result.lemma.p)[names(result.lemma.p)=="V1"] <- "x"
names(result.lemma.p)[names(result.lemma.p)=="V2"] <- "y"
names(result.lemma.p)[names(result.lemma.p)=="V3"] <- "D_BM_kg"
names(result.lemma.p)[names(result.lemma.p)=="V4"] <- "relNO"
names(result.lemma.p)[names(result.lemma.p)=="V5"] <- "relBA"
names(result.lemma.p)[names(result.lemma.p)=="V6"] <- "PlotID"

# end timer
print(Sys.time()-strt)
###################################################################
# 9 minutes for CRMORT-sized area

### Save results
if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Battles Lab/Box Sync/EPIC-Biomass/R Results")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/R Results")
}
write.csv(result.lemma.p, file = "LEMMA_ADS_AllSpp_2016_Turbo_01242016.csv", row.names=F)

# Look at histograms of results
library(ggplot2)
qplot(result.lemma.p$D_BM_kg, geom = "histogram")

qplot(result.lemma.p$D_BM_kgha,
      geom="histogram",
      binwidth = 2000,  
      main = "Histogram of 2016 Mortality Biomass", 
      xlab = "Biomass (kg/ha)",  
      ylab = "Pixel Count",
      fill=I("blue"), 
      col=I("black"), 
      alpha=I(.2),
      xlim=c(0,200000),
      ylim=c(0,2000000))

### For editing: clear variables in loop
remove(cell, final, L.in.mat, mat, mat2, merge, pcoords, pmerge, zeros, All_BM_kgha, All_Pol_BM_kgha, Av_BM_TR, D_Pol_BM_kg, 
       ext, i, num, Pol.ID, Pol.NO_TREES1, Pol.Pixels, Pol.Shap_Ar, Pol.x, Pol.y, QMDC_DOM, result.lemma.p, RPT_YR, s)
remove(clip1, clip2, single, spp, spp.names, THA, tot_NO, TREEPL, types)
remove(no.pixels, QMD_DOM, tab)
