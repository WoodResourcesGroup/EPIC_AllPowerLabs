#########################################################################################################################
######## COMBINE ALL RESULTS INTO A NICE TABLE
#########################################################################################################################

library(rgdal)
library(raster)

### Define EPIC as the EPIC-Biomass folder for easier setwd later on
EPIC <- "C:/Users/Battles Lab/Box Sync/EPIC-Biomass" # for Turbo
### Define where the cec-apl folder is
CEC <- "~/cec_apl/"

setwd(paste(CEC, "/Biomass/Results", sep=""))
load(file="RESULTS_TABLE.Rdata")

# Add columns for other types of data

### Load .Rdata with BM results
unit.names <- c("LNP", "ENF","ESP","LTMU","CSP","SNF","SQNP","KCNP", "MH")
setwd(paste(EPIC, "/GIS Data/Results_2016/", sep=""))
for(i in 1:length(unit.names)){
  load(file=paste(unit.names[i], "_sum_D_BM_Mg_noBA.Rdata", sep=""))
  assign(paste("sum_BM_",unit.names[i],sep=""), sum_D_BM_Mg)
}
# Put summed BM into table
for(i in 1:length(unit.names)){
  df[unit.names==unit.names[i],"noBA_2016_BM_tot"]<- get(paste("sum_BM_", unit.names[i], sep=""))
}

df$BM_D_Mgha <- NULL
df$BM_D_tot <- NULL

### Do the same with 1415 results
setwd(paste(EPIC, "/GIS Data/Results_1415/", sep=""))
for(i in 1:length(unit.names)){
  load(file=paste(unit.names[i], "_1415_D_BM_Mg_noBA.Rdata", sep=""))
  assign(paste("sum_BM_1415_",unit.names[i],sep=""), sum_D_BM_Mg)
}
# Put summed BM into table
for(i in 1:length(unit.names)){
  df[unit.names==unit.names[i],"noBA_1415_BM_tot"]<- get(paste("sum_BM_1415_", unit.names[i], sep=""))
}

# And with 2012-2013 results
setwd(paste(EPIC, "/GIS Data/Results/", sep=""))
for(i in 1:length(unit.names)){
  load(file=paste(unit.names[i], "_1213_BM_Mg_noBA.Rdata", sep=""))
  assign(paste("sum_BM_1213_",unit.names[i],sep=""), sum_D_BM_Mg)
}
# Put summed BM into table
for(i in 1:length(unit.names)){
  df[unit.names==unit.names[i],"noBA_1213_BM_tot"]<- get(paste("sum_BM_1213_", unit.names[i], sep=""))
}

# Calculate Mg/ha and percent change

df$noBA_BM_D_Mgha <- df$noBA_BM_D_tot/as.numeric(paste(df$L.area.ha))
df$noBA_BM_D_Mgha_1415 <-df$noBA_1415_BM_D_tot/as.numeric(paste(df$L.area.ha))
df$noBA_tot_D_Mgha <- df$noBA_BM_D_Mgha+df$noBA_BM_D_Mgha_1415
df$noBA_Perc_Ch <- df$noBA_tot_D_Mgha/as.numeric(paste(df$live.BM))

setwd(paste(CEC, "/Biomass/Results", sep=""))
save(df, file = "RESULTS_TABLE_FULL.Rdata")
write.csv(df, "results_table.csv", row.names = T)
