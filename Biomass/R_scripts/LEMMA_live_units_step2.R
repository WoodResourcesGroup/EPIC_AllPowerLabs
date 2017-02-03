#########################################################################################################################
######## CALCULATE TOTAL LIVE BIOMASS IN EACH MANAGEMENT UNIT FROM LEMMA DATA - STEP 2
#########################################################################################################################
library(rgdal)
library(raster)

### Define EPIC as the EPIC-Biomass folder for easier setwd later on
EPIC <- "C:/Users/Battles Lab/Box Sync/EPIC-Biomass" # for Turbo
### Define where the cec-apl folder is
CEC <- "~/cec_apl/"

### STEP NOT INCLUDED: OPENING EACH UNIT'S LEMMA LIVE RESULTS - "GIS Data/LEMMA_units/LEMMA.[unit name]"
# Example
setwd(paste(EPIC, "/GIS Data", sep=""))
LEMMA.LTMU <- readOGR(dsn="LEMMA_units", layer="LEMMA_LTMU")
# takes about 20 min per unit
LEMMA.KCNP <- readOGR(dsn="LEMMA_units", layer = "LEMMA_kc")
LEMMA.MHSF <- readOGR(dsn="LEMMA_units", layer = "LEMMA_MH")


#####################################################################################
### Crop each unit's live LEMMA results to only include pixels with nonzero biomass, 
### then calculate mean live basal area and SAVE IT
#####################################################################################
unit.names <- c("LNP", "ENF","ESP","LTMU","CSP","SNF","SQNP","KCNP", "MHSF")
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
save(df, file = "RESULTS_TABLE.Rdata")
