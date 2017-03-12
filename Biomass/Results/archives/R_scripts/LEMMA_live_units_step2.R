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

# Load results of live biomass analysis 
setwd(paste(EPIC, "/GIS Data/LEMMA_units", sep=""))
load(file="LEMMA_units.Rdata")
load(file='LEMMA_KCNP.Rdata')
load(file='LEMMA_LTMU.Rdata')
load(file='LEMMA_SNF.Rdata')

#####################################################################################
### Crop each unit's live LEMMA results 
### then calculate mean live basal area and SAVE IT
#####################################################################################

unit.names <- c("MH","CSP", "ESP", "SQNP", "ENF", "LNP")

### WITH NEW LEMMA.UNITS RDATA FILE

for(i in 1:length(unit.names)) {
  subset <- subset(LEMMA_units, LEMMA_units$UNIT==unit.names[i])
  assign(paste("LEMMA_",unit.names[i],sep=""), subset)
}
# Match KCNP and LTMU 
# Create Table
unit.names <- c("LNP", "ENF", "ESP","LTMU","CSP",  "SNF", "SQNP", "KCNP", "MH")
df <- 0
BM3 <- numeric()
BM25 <- numeric()
L.area.ha <- numeric()

for(i in 1:length(unit.names)){
  full <- get(paste("LEMMA_",unit.names[i],sep=""))
  BM25full <- mean(full$BPH_GE_25_CRM)/1000
  BM3full <- mean(full$BPH_GE_3_CRM)/1000
  BM25 <- append(BM25, BM25full)
  BM3 <- append(BM3, BM3full)
  area <- (nrow(full)*900)/10000
  L.area.ha <- append(L.area.ha, area)
}
df <- cbind.data.frame(BM25, BM3,L.area.ha)
df <- cbind(unit.names, df)
setwd(paste(CEC, "/Biomass/Results", sep=""))
save(df, file = "RESULTS_TABLE_CRM.Rdata")
