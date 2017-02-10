#########################################################################################################################
######## CALCULATE TOTAL LIVE BIOMASS IN EACH MANAGEMENT UNIT FROM LEMMA DATA - STEP 2
#########################################################################################################################
library(rgdal)
library(raster)

### Define EPIC as the EPIC-Biomass folder for easier setwd later on
#EPIC <- "C:/Users/Battles Lab/Box Sync/EPIC-Biomass" # for Turbo
EPIC <- "C:/Users/Carmen/Box Sync/EPIC-Biomass"
### Define where the cec-apl folder is
CEC <- "~/cec_apl/"


# Load results of live biomass analysis and resave them as .Rdata for faster future loading

unit.names <- c("LNP", "ENF","ESP","LTMU","CSP","SNF","SQNP","KCNP", "MHSF")

for(i in 1:length(unit.names)){
  setwd(paste(EPIC, "/GIS Data", sep=""))
  spdf <- readOGR(dsn="LEMMA_units", layer = paste("LEMMA_",unit.names[i], sep=""))
  setwd(paste(EPIC, "/GIS Data/LEMMA_units", sep=""))
  save(spdf, file=paste("LEMMA_",unit.names[i],".Rdata", sep=""))
  assign(paste("LEMMA.",unit.names[i],sep=""),spdf)
  remove(spdf)
}

#####################################################################################
### Crop each unit's live LEMMA results to only include pixels with nonzero biomass, 
### then calculate mean live basal area and SAVE IT
#####################################################################################
sum_BM_MHSF <- sum_BM_MH
live.BM <- numeric()
L.area.ha <- numeric()

for(i in 1:length(unit.names)){
  full <- get(paste("LEMMA.",unit.names[i],sep=""))
  nz <- subset(full,full$All_BM_ >0)
  assign(paste("LEMMA.",unit.names[i],".nz",sep=""), nz)
  mean <- mean(nz$All_BM_)/1000
  live.BM <- append(live.BM, mean)
  area <- (length(nz)*900)/10000
  L.area.ha <- append(L.area.ha, area)
}
df <- as.data.frame(cbind(unit.names, live.BM, L.area.ha))
setwd(paste(CEC, "/Biomass/Results", sep=""))
save(df, file = "RESULTS_TABLE_CRM.Rdata")
