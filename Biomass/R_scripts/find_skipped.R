#################################################################################################
###### USE THIS SCRIPT TO FIND WHICH PLOTS ARE LEFT OUT BY THE ANALYSIS IN LEMMA_ADS_AllSpp_2016_Turbo.R
#################################################################################################
EPIC <- "C:/Users/Carmen/Box Sync/EPIC-Biomass"
library(rgdal)  
library(raster)  

options(digits = 5)

### Open GNN LEMMA data (see script crop_LEMMA.R for where LEMMA.gri comes from)
setwd(paste(EPIC, "/GIS Data/LEMMA_gnn_sppsz_2014_08_28/", sep=""))
LEMMA <- raster("LEMMA.gri")

### OPEN DROUGHT MORTALITY POLYGONS (see script transform_ADS.R for where "drought" comes from)
setwd(paste(EPIC, "/GIS Data/tempdir", sep=""))
load("drought.Rdata")
drought_bu <- drought
load("drought16.Rdata")
drought16_bu <- drought16

### Set up parallel cores for faster runs
library(doParallel)
detectCores()
no_cores <- detectCores() - 1 # Use all but one core on your computer
c1 <- makeCluster(no_cores)
registerDoParallel(c1)

### OPEN RAMIREZ DATA (see script transform_CRmort.R for where "CR_mort.tif" comes from)
### NOTE: We didn't end up analysing Ramirez data, so this step is only for cropping the data down for editing code in a manageably sized chunk
CR_mort <- raster("CR_mort.tif")

### Crop drought data to extent of Ramirez data 
drought <- crop(drought, extent(CR_mort)) # *****comment out this step for running on the entire drought data set*****
drought16 <- crop(drought16, extent(CR_mort))

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
# 25 min for the whole 2016 data set

zeros <- subset(no.go, no.go == 0)
zeros <- as.data.frame(zeros)
zero.i <- row.names(zeros)
zero.i <- as.integer(gsub("result.", "", zero.i))

setwd("~/cec_apl/Biomass/R_scripts")
saveRDS(zero.i,file="zero_i_16.Rdata")
