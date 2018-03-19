#########################################################################################################################
###  THIS SCRIPT CALCULATES BM OF DEAD TREES BY IN THE WHOLE STATE FOR 2012-2016, CRM METHOD
#########################################################################################################################

### CURRENTLY SET TO CALCULATE DEAD TREES AS >25CM

##### ***THINGS YOU NEED TO CHANGE BETWEEN RUNS*** #########
#EPIC <- "C:/Users/Battles Lab/Box Sync/EPIC-Biomass" # Define where your EPIC-BIOMASS folder is located in Box Sync
EPIC <- "C:/Users/Jose Daniel/Box Sync/EPIC-Biomass"

### FOR JOSE'S MAC
#EPIC <- "~/Documents/Box Sync/EPIC-Biomass/"
#########################################################################################################################

library(rgdal)  
library(raster)  
library(tidyverse)
options(digits = 5)

### Open GNN LEMMA data (see script crop_LEMMA.R for where LEMMA.gri comes from)
setwd(paste(EPIC, "/GIS Data/LEMMA_gnn_sppsz_2014_08_28/", sep=""))
LEMMA <- raster("LEMMA.gri")

### Open LEMMA PLOT data
setwd(paste(EPIC))
plots <- read.csv("SPPSZ_ATTR_LIVE.csv")
land_types <- unique(plots$ESLF_NAME)
for_types <- unique(plots$FORTYPBA)[2:932]
plots <- plots[,c("VALUE",
                  "TPH_GE_3",
                  "TPH_GE_25", 
                  "BPH_GE_3_CRM",
                  "BPH_GE_25_CRM", 
                  "FORTYPBA", 
                  "ESLF_NAME", 
                  "TREEPLBA", 
                  "VPH_GE_25", 
                  "BPH_GE_3_JENK", 
                  "BPH_GE_25_JENK"
)]

### OPEN DROUGHT MORTALITY POLYGONS (see script transform_ADS.R for where "drought" comes from)
setwd(paste(EPIC, "/GIS Data/tempdir", sep=""))
load("drought.Rdata")
drought1215 <- drought
drought1215_bu <- drought
load("drought16.Rdata")
drought16_bu <- drought16
load("drought17.Rdata")


### Check out which polygons will be skipped by the analysis - see script "find_skipped.R"
#setwd("~/cec_apl/Biomass/R_scripts")
#readRDS("zero_i_16_CR.Rdata") # for test
#readRDS("zero_i_16.Rdata")    # for final
###################################################################
# Function that does the bulk of the analysis

### Single out the unit of interest

YEARS <- c("1215","2016", "2017")

for(j in 1:3){
  YEAR <- YEARS[j]
  strt<-Sys.time()
  if(YEAR=="1215") {
    drought <- subset(drought1215, drought1215$RPT_YR %in% c(2012,2013,2014,2015))
  } else if(YEAR == "2016"){
    drought <- drought16
  } else
    drought <- drought17
  drought_bu <- drought
  inputs=1:nrow(drought)
  library(doParallel)
  detectCores()
  no_cores <- detectCores() - 1 # Use all but one core on your computer
  c1 <- makeCluster(no_cores)
  registerDoParallel(c1)
  results <- foreach(i=inputs, .combine = rbind, .packages = c('raster','rgeos','tidyr','dplyr'), .errorhandling="remove") %dopar% {
    single <- drought[i,] # select one polygon
    clip1 <- crop(LEMMA, extent(single)) # crop LEMMA GLN data to the size of that polygon
    # fit the cropped LEMMA data to the shape of the polygon, unless the polygon is too small to do so
    if(length(clip1) >= 4){
      clip2 <- mask(clip1, single)
    } else 
      clip2 <- clip1
    pcoords <- cbind(clip2@data@values, coordinates(clip2)) # save the coordinates of each pixel
    pcoords <- as.data.frame(pcoords)
    pcoords <- na.omit(pcoords) # get rid of NAs in coordinates table (NAs are from empty cells in box around polygon)
    counted <- pcoords %>% count(V1)
    mat <- as.data.frame(counted)
    s <- sum(mat[2]) # Counts total raster cells the polygon - this is different from length(clip2tg) because it doesn't include NAs
    freq <- (mat[2]/s) # gives fraction of polygon occupied by each plot type. Adds up to 1 for each polygon.
    mat2 <- cbind(mat, freq) # creates table with FIA plot IDs in polygon, number of each, and relative frequency of each
    colnames(mat2)[3] <- "freq"
    merge <- merge(mat2, plots, by.x = "V1", by.y="VALUE")
    pmerge <- merge(pcoords, merge, by ="V1") # pmerge has a line for every pixel
    tot_NO <- as.numeric(single@data$NO_TREES1) # Total number of trees in the polygon
    pmerge <- subset(pmerge, pmerge$FORTYPBA %in% for_types)
    # Assign biomass per tree for each of the 4 calculations
    pmerge <- pmerge %>% 
      mutate(live.ratio25 = TPH_GE_25/sum(pmerge$TPH_GE_25, na.rm = T)) %>% 
      mutate(live.ratio3 = TPH_GE_3/sum(pmerge$TPH_GE_3, na.rm = T)) %>% 
      mutate(relNO25 = tot_NO*live.ratio25) %>% 
      mutate(relNO3 = tot_NO*live.ratio3) %>% 
      mutate(bm_liveCRM_25_kg = BPH_GE_25_CRM*(900/10000)) %>% 
      mutate(bm_liveCRM_3_kg = BPH_GE_3_CRM*(900/10000)) %>% 
      mutate(bm_liveJ_25_kg = BPH_GE_25_JENK*(900/10000)) %>% 
      mutate(bm_liveJ_3_kg = BPH_GE_3_JENK*(900/10000)) %>% 
      mutate(VPT = VPH_GE_25/TPH_GE_25,
             BM_tree25kgCRM = BPH_GE_25_CRM/TPH_GE_25,
             BM_tree3kgCRM = BPH_GE_3_CRM/TPH_GE_3,
             BM_tree25kgJ = BPH_GE_25_JENK/TPH_GE_25,
             BM_tree3kgJ = BPH_GE_3_JENK/TPH_GE_3)
    # Replace NAs with 0 for later  calculations
    pmerge <- replace_na(pmerge, list(BM_tree25kgCRM = 0, BM_tree3kgCRM = 0, BM_tree25kgJ = 0, BM_tree3kgJ = 0))
    # Calculate total dead biomass by multiplying per-tree dead biomass by relative number of trees
    pmerge <- pmerge %>% 
      mutate(D_BM_kg25CRM = ifelse(TPH_GE_25*0.09 < relNO25, bm_liveCRM_25_kg, relNO25*BM_tree25kgCRM)) %>% 
      mutate(D_BM_kg3CRM = ifelse(TPH_GE_3*0.09 < relNO3, bm_liveCRM_3_kg, relNO3*BM_tree3kgCRM)) %>% 
      mutate(D_BM_kg25J = ifelse(TPH_GE_25*0.09 < relNO25, bm_liveJ_25_kg, relNO25*BM_tree25kgCRM)) %>% 
      mutate(D_BM_kg3J = ifelse(TPH_GE_3*0.09 < relNO3, bm_liveJ_3_kg, relNO3*BM_tree3kgCRM))
    # Add trunc columns to mark whether dead biomass was capped at live biomass
    pmerge$trunc25CRM <- ifelse(pmerge$D_BM_kg25CRM == pmerge$BPH_GE_25_CRM*(900/10000) & pmerge$D_BM_kg25CRM!=0, 1,0)
    pmerge$trunc3CRM <- ifelse(pmerge$D_BM_kg3CRM==pmerge$BPH_GE_3_CRM*(900/10000) & pmerge$D_BM_kg3CRM!=0, 1,0)
    pmerge$trunc25J <- ifelse(pmerge$D_BM_kg25J ==pmerge$BPH_GE_25_JENK*(900/10000) & pmerge$D_BM_kg25J!=0, 1,0)
    pmerge$trunc3J <- ifelse(pmerge$D_BM_kg3J ==pmerge$BPH_GE_3_JENK*(900/10000) & pmerge$D_BM_kg3J!=0, 1,0)
    
    # Create vectors that are the same length as pmerge to combine into final table:
    Pol.ID <- rep(i, nrow(pmerge)) # create a Polygon ID
    RPT_YR <- rep(single@data$RPT_YR, nrow(pmerge)) # Create year vector
    host <- rep(single@data$HOST1, nrow(pmerge)) # Create tree species vector
    Pol.Shap_Ar <- rep(single@data[,as.numeric(length(single@data))], nrow(pmerge)) # Create area vector
    Pol.Pixels <- rep(s, nrow(pmerge)) # number of pixels
    # Bring it all together
    final <- cbind(pmerge, Pol.ID, RPT_YR, host, 
                   Pol.Shap_Ar,Pol.Pixels) #    
    return(final)
  }
  # Create a key for each pixel (row)
  key <- seq(1, nrow(results)) 
  results <- cbind(key, results)
  # Rename variables whose names were lost in the cbind
  names(results)[names(results)=="V1"] <- "PlotID"
  setwd(paste(EPIC, "/GIS Data/Results/Results_wholestate", sep=""))
  write.csv(results, file=paste("Results_", YEAR,"_WS_25_3_CRM_J.csv",sep=""), row.names = F)
  print(Sys.time()-strt)
}


### For editing only: clear variables in loop
# remove(cell, final, L.in.mat, mat, mat2, merge, pcoords, pmerge, zeros, All_BM_kgha, All_Pol_BM_kgha, Av_BM_TR, D_Pol_BM_kg, 
#        ext, i, num, Pol.ID, Pol.NO_TREES1, Pol.Pixels, Pol.Shap_Ar, Pol.x, Pol.y, QMD_DOM, RPT_YR, s)
# remove(clip1, clip2, single, spp, spp.names, THA, tot_NO, TREEPL, types)
# remove(no.pixels, QMD_DOM, tab, results)
# remove(raster.mask, try.raster, spdf, spdf_ESP, key,j,l)
