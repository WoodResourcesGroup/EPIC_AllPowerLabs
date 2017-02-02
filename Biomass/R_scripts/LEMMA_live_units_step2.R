#########################################################################################################################
######## CALCULATE TOTAL LIVE BIOMASS IN EACH MANAGEMENT UNIT FROM LEMMA DATA - STEP 2
#########################################################################################################################
library(rgdal)
library(raster)

### Define EPIC as the EPIC-Biomass folder for easier setwd later on
EPIC <- "C:/Users/Battles Lab/Box Sync/EPIC-Biomass" # for Turbo

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
setwd(paste(EPIC, "/R Results", sep=""))
save(df, file = "RESULTS_TABLE.Rdata")
load(file="RESULTS_TABLE.Rdata")

# Add columns for other types of data

df$BM_D_Mgha <- 0
df$BM_D_tot <- 0
df$noBA_BM_D_Mgha <- 0
df$noBA_BM_D_tot <- 0
df$noBA_Perc_Ch <- 0
df$noBA_BM_D_Mgha_1415 <- 0

# Load .Rdata with BM 
unit.names <- c("LNP", "ENF","ESP","LTMU","CSP","SNF","SQNP","KCNP", "MH")
setwd(paste(EPIC, "/GIS Data/Results_2016/", sep=""))
for(i in 1:length(unit.names)){
  load(file=paste(unit.names[i], "_sum_D_BM_Mg_noBA.Rdata", sep=""))
  assign(paste("sum_BM_",unit.names[i],sep=""), sum_D_BM_Mg)
}

# Put summed BM into table
for(i in 1:length(unit.names)){
  df[unit.names==unit.names[i],"noBA_BM_D_tot"]<- get(paste("sum_BM_", unit.names[i], sep=""))
}

# Do the same with 1415 results
setwd(paste(EPIC, "/GIS Data/Results_1415/", sep=""))
for(i in 1:length(unit.names)){
  load(file=paste(unit.names[i], "_1415_D_BM_Mg_noBA.Rdata", sep=""))
  assign(paste("sum_BM_1415_",unit.names[i],sep=""), sum_D_BM_Mg)
}

# Put summed BM into table
for(i in 1:length(unit.names)){
  df[unit.names==unit.names[i],"noBA_1415_BM_D_tot"]<- get(paste("sum_BM_1415_", unit.names[i], sep=""))
}


df[unit.names=="KCNP","BM_D_Mgha"] <- 28
df[unit.names=="KCNP","BM_D_tot"] <- 2106348
df[unit.names=="KCNP","noBA_BM_D_Mgha"] <- 19.3
df[unit.names=="KCNP","noBA_BM_D_tot"] <- 1452081

df$noBA_BM_D_Mgha <- df$noBA_BM_D_tot/as.numeric(paste(df$L.area.ha))
df$noBA_BM_D_Mgha_1415 <-df$noBA_1415_BM_D_tot/as.numeric(paste(df$L.area.ha))
df$noBA_tot_D_Mgha <- df$noBA_BM_D_Mgha+df$noBA_BM_D_Mgha_1415
df$noBA_Perc_Ch <- df$noBA_tot_D_Mgha/as.numeric(paste(df$live.BM))
names(df)
