#################################################################################################
###### USE THIS SCRIPT TO FIND WHICH PLOTS ARE LEFT OUT BY THE ANALYSIS IN LEMMA_ADS_AllSpp_2016_Turbo.R
#################################################################################################

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
#drought <- crop(drought, extent(CR_mort)) # *****comment out this step for running on the entire drought data set*****

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
# 25 min for the whole 2016 data set

zeros <- subset(no.go, no.go == 0)
zeros <- as.data.frame(zeros)
zero.i <- row.names(zeros)
zero.i <- as.integer(gsub("result.", "", zero.i))

setwd("~/cec_apl/Biomass/R_scripts")
saveRDS(zero.i,file="zero_i_16.Rdata")
