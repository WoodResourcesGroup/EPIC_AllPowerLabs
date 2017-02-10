#########################################################################################################################
###  THIS SCRIPT CALCULATES BM OF DEAD TREES BY UNIT FOR 2012-2016, NON-BASAL AREA METHOD
#########################################################################################################################

##### ***THINGS YOU NEED TO CHANGE BETWEEN RUNS*** #########
#EPIC <- "C:/Users/Battles Lab/Box Sync/EPIC-Biomass" # Define where your EPIC-BIOMASS folder is located in Box Sync
EPIC <- "C:/Users/Carmen/Box Sync/EPIC-Biomass"
#YEARS <- "1213"
#YEARS <- "1415"
YEARS <- "1215"
#YEARS <- "2016"
#########################################################################################################################

library(rgdal)  
library(raster)  
options(digits = 5)

### Open GNN LEMMA data (see script crop_LEMMA.R for where LEMMA.gri comes from)
setwd(paste(EPIC, "/GIS Data/LEMMA_gnn_sppsz_2014_08_28/", sep=""))
LEMMA <- raster("LEMMA.gri")

### Open LEMMA PLOT data
setwd(paste(EPIC))
plots <- read.csv("SPPSZ_ATTR_LIVE.csv")
land_types <- unique(plots$ESLF_NAME)
for_types <- unique(plots$FORTYPBA)[2:932]

### OPEN DROUGHT MORTALITY POLYGONS (see script transform_ADS.R for where "drought" comes from)
setwd(paste(EPIC, "/GIS Data/tempdir", sep=""))
load("drought.Rdata")
drought_bu <- drought
load("drought16.Rdata")
drought16_bu <- drought16

if(YEARS=="1213"){
  drought <- subset(drought, drought$RPT_YR %in% c(2012,2013))
} else if(YEARS=="1415") {
  drought <- subset(drought, drought$RPT_YR %in% c(2014,2015))  
} else if(YEARS=="1215") {
  drought <- subset(drought, drought$RPT_YR %in% c(2012,2013,2014,2015))
} else 
  drought <- drought16

drought_bu <- drought # backup so that I don't need to re-read if I accidentally override drought

### Open unit perimeters - all are in the layer "units" besides KCNP and LTMU -- do these steps every 
### time no matter which one you're running
setwd(paste(EPIC, "/GIS Data/units", sep=""))
load(file="units.Rdata")
units <- spTransform(units, crs(LEMMA))
load(file="KCNP.Rdata")
KCNP <- spTransform(KCNP, crs(LEMMA))
setwd(paste(EPIC, "/GIS Data/tempdir", sep=""))
load(file="FS_LTMU.Rdata")
LTMU <- spTransform(FS_LTMU, crs(LEMMA))

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

### Single out the unit of interest
unit.names <- c("LNP", "ENF","ESP","LTMU","CSP","SNF","SQNP","KCNP", "MH")
for(j in 1:length(unit.names)) {
  UNIT <- unit.names[j]  ### Single out the unit of interest
  strt<-Sys.time()
  if(UNIT %in% units$UNIT){
    unit <- units[units$UNIT==UNIT,]
  } else if (UNIT=="KCNP"){
    unit <- KCNP
  } else  ## assign polygon of interest
    unit <- LTMU
  drought <- crop(drought_bu, extent(unit)) 
  inputs =1:nrow(drought)
  #i <- 6
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
    #ext <- extract(clip2, single) # extracts data from the raster - each extracted value is the FIA plot # of the raster cell, which corresponds to detailed data in the attribute table of LEMMA
    #tab <- lapply(ext, table) # creates a table that counts how many of each raster value there are in the polygon
    counted <- pcoords %>% count(V1)
    mat <- as.data.frame(counted)
    s <- sum(mat[2]) # Counts total raster cells the polygon - this is different from length(clip2tg) because it doesn't include NAs
    freq <- (mat[2]/s) # gives fraction of polygon occupied by each plot type. Adds up to 1 for each polygon.
    mat2 <- cbind(mat, freq) # creates table with FIA plot IDs in polygon, number of each, and relative frequency of each
    colnames(mat2)[3] <- "freq"
    ### Attribute meanings from LEMMA GLN:
    ### BA_GE_3 = basal area of live trees >= 2.5 cm dbh (m^2/ha)
    ### BPH_GE_3_CRM = Component Ratio Method biomass of all live trees >=2.5 cm dbh (kg/ha)
    ### TPH_GE_3 = Density of live trees >=2.5 cm dbh (trees/ha)
    ### QMD_DOM = 	Quadratic mean diameter of all dominant and codominant trees (cm)
    ### TREEPLBA = Tree species with plurality of basal area
    
    merge <- merge(mat2, plots, by.x = "V1", by.y="VALUE")

    # Find biomass per pixel using biomass per tree and estimated number of trees
    pmerge <- merge(pcoords, merge, by ="V1") # pmerge has a line for every pixel
    # problem here
    tot_NO <- single@data$NO_TREES1 # Total number of trees in the polygon
    pmerge <- subset(pmerge, pmerge$FORTYPBA %in% for_types)
    pmerge$live <- pmerge$TPH_GE_25/sum(pmerge$TPH_GE_25, na.rm=T)
    pmerge$relNO <- tot_NO*pmerge$live
    pmerge$BM_tree_kg <- pmerge$BPH_GE_25_CRM/pmerge$TPH_GE_25
    pmerge$BM_tree_kg[is.na(pmerge$BM_tree_kg)] <- 0
    
    for(l in 1:nrow(pmerge)) {
      if(pmerge[l,"TPH_GE_25"]<pmerge[l,"relNO"]) {
        pmerge[l,"D_BM_kg"] <- pmerge[l,"BPH_GE_25_CRM"] # I add the 0.01 to make it easier to tell these plots later
      } else pmerge[l,"D_BM_kg"] <- pmerge[l,"relNO"]*pmerge[l,"BM_tree_kg"]
    }
    pmerge$trunc <- ifelse(pmerge$D_BM_kg==pmerge$BPH_GE_25_CRM & pmerge$D_BM_kg!=0, 1,0)
    # Create vectors that are the same length as pmerge to combine into final table:
    Pol.ID <- rep(i, nrow(pmerge)) # create a Polygon ID
    D_Pol_BM_kg <- rep(sum(pmerge$D_BM_kg), nrow(pmerge)) # Sum biomass over the entire polygon 
    QMD_DOM <- pmerge$QMD_DOM # Find the average of the pixels' quadratic mean diameters 
    TREEPL <-  as.character(pmerge$TREEPLBA) # Find the tree species that has a plurality in the most pixels
    Pol.x <- rep(gCentroid(single)@coords[1], nrow(pmerge)) # Find coordinates of center of polygon
    Pol.y <- rep(gCentroid(single)@coords[2], nrow(pmerge))
    RPT_YR <- rep(single@data$RPT_YR, nrow(pmerge)) # Create year vector
    Pol.NO_TREES1 <- rep(single@data$NO_TREES1, nrow(pmerge)) # Create number of dead trees vector
    Pol.Shap_Ar <- rep(single@data[,as.numeric(length(single@data))], nrow(pmerge)) # Create area vector
    Pol.Pixels <- rep(s, nrow(pmerge)) # number of pixels
    D_BM_kgha <- pmerge$D_BM_kg/.09
    # Estimate biomass of live AND dead trees based on LEMMA values of biomass per pixel:
    BPH_GE_3_CRM <- pmerge$BPH_GE_3_CRM 
    All_Pol_BM_kgha <- rep(mean(pmerge$BPH_GE_3_CRM),nrow(pmerge)) # Average across polygons
    THA <- pmerge$TPH_GE_3 
    THA_25 <- pmerge$TPH_GE_25
    BPH_GE_25_CRM <- pmerge$BPH_GE_25_CRM
    # Bring it all together
    #final <- cbind.data.frame(pmerge$x, pmerge$y, D_BM_kg)
    pmerge <- pmerge[,c("V1","x", "y", "D_BM_kg", "relNO","FORTYPBA", "ESLF_NAME", "trunc")]
    final <- cbind(pmerge, Pol.x, Pol.y, RPT_YR,Pol.NO_TREES1, 
                   Pol.Shap_Ar,D_Pol_BM_kg,BPH_GE_3_CRM,All_Pol_BM_kgha,THA, THA_25, BPH_GE_25_CRM, QMD_DOM,Pol.ID, TREEPL) #
    return(final)
  }
  # Create a key for each pixel (row)
  key <- seq(1, nrow(results)) 
  results <- cbind(key, results)
  # Rename variables whose names were lost in the cbind
  names(results)[names(results)=="V1"] <- "PlotID"
  # Find pixels with more dead biomass than live biomass
  # toohigh <- subset(results, results$D_BM_kg>results$BPH_GE_25_CRM)
  # toohigh
  # Test that stuff adds up
  # aggregate(results$relNO, by=list(Category=results$Pol.ID), FUN=sum)
  # drought$NO_TREES1
  # testresults <- results$BPH_GE_25_CRM/results$THA_25*results$relNO
  # test <- testresults - results$D_BM_kg
  # unique(test < 0.5 & test > -0.5) # these should all be true or NA. If they're not, make sure the appropriate rows have "trunc" = 1
  # (test < 0.5 & test > -0.5)
  ### Convert to a spatial data frame
  xy <- results[,c("x","y")]
  spdf <- SpatialPointsDataFrame(coords=xy, data = results, proj4string = crs(LEMMA))
  setwd(paste(EPIC, "/GIS Data/Results/Results_CRM", sep=""))
  save(spdf, file=paste("Results_",YEARS, "_",UNIT,"_CRM.Rdata", sep=""))
  load(file=paste("Results_",YEARS, "_",UNIT,"_CRM.Rdata", sep=""))
  assign(paste("spdf_",YEARS, "_",UNIT,sep=""), spdf)
  ### Save version masked to just the management unit
  ## Convert to raster to more easily crop and sum
  xyz <- as.data.frame(cbind(spdf@data$x, spdf@data$y, spdf@data$D_BM_kg))
  try.raster <- rasterFromXYZ(xyz, crs = crs(spdf))
  #strt<-Sys.time()
  raster.mask <- mask(try.raster, unit)
  sum_D_BM_Mg <- sum(subset(raster.mask@data@values, raster.mask@data@values>0))/1000
  setwd(paste(EPIC, "/GIS Data/Results/Results_CRM", sep=""))
  save(raster.mask, file=paste(UNIT,"_raster_",YEARS,".Rdata",sep=""))
  save(sum_D_BM_Mg, file=paste(UNIT,"_", YEARS,"_BM_Mg_CRM.Rdata", sep=""))
  remove(sum_D_BM_Mg)
  load(file=paste(UNIT,"_", YEARS,"_BM_Mg_CRM.Rdata", sep=""))
  assign(paste("sum_BM_",YEARS,"_",UNIT,sep=""), sum_D_BM_Mg)
  remove(sum_D_BM_Mg)
  remove(spdf)
  print(Sys.time()-strt)
}

### For editing only: clear variables in loop
remove(cell, final, L.in.mat, mat, mat2, merge, pcoords, pmerge, zeros, All_BM_kgha, All_Pol_BM_kgha, Av_BM_TR, D_Pol_BM_kg, 
       ext, i, num, Pol.ID, Pol.NO_TREES1, Pol.Pixels, Pol.Shap_Ar, Pol.x, Pol.y, QMDC_DOM, RPT_YR, s)
remove(clip1, clip2, single, spp, spp.names, THA, tot_NO, TREEPL, types)
remove(no.pixels, QMD_DOM, tab, results)
remove(raster.mask, try.raster, spdf, spdf_ESP, key)
