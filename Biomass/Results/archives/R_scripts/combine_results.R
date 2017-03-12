#########################################################################################################################
######## COMBINE ALL RESULTS INTO A NICE TABLE
#########################################################################################################################

library(rgdal)
library(raster)

### Define EPIC as the EPIC-Biomass folder for easier setwd later on
#EPIC <- "C:/Users/Battles Lab/Box Sync/EPIC-Biomass" # for Turbo
EPIC <- "C:/Users/Carmen/Box Sync/EPIC-Biomass" 
### Define where the cec-apl folder is
CEC <- "~/cec_apl/"

setwd(paste(CEC, "/Biomass/Results", sep=""))
load(file="RESULTS_TABLE_CRM.Rdata")

# Add columns for other types of data

### Load .Rdata with BM results
unit.names <- c("LNP", "ENF","ESP","LTMU","CSP","SNF","SQNP","KCNP", "MH")
YEARS <- c("1215","2016")
setwd(paste(EPIC, "/GIS Data/Results/Results_CRM", sep=""))

for(i in 1:length(unit.names)){
  for(j in 1:length(YEARS)){
    load(file=paste(unit.names[i],"_", YEARS[j],"_25_BM_Mg_CRM.Rdata", sep=""))
    assign(paste(unit.names[i],"_25_sum_BM_",YEARS[j],sep=""), sum_D_BM_Mg)
  }
}

# Put summed BM into table
for(i in 1:length(unit.names)){
  df[unit.names==unit.names[i],"BM_25_2016_tot"]<- get(paste(unit.names[i],"_25_sum_BM_", "2016", sep=""))
}

for(i in 1:length(unit.names)){
  df[unit.names==unit.names[i],"BM_25_1215_tot"]<- get(paste(unit.names[i],"_25_sum_BM_", "1215", sep=""))
}

# Calculate Mg/ha and percent change

df$BM_25_Mgha_1215 <- df$BM_25_1215_tot/df$L.area.ha
df$BM_25_Mgha_2016 <- df$BM_25_2016_tot/df$L.area.ha
df$BM_25_Mhga <- df$BM_25_Mgha_1215+df$BM_25_Mgha_2016
df$Perc_D_25 <- df$BM_25_Mhga/df$BM25 

# 
# for(i in 1:length(unit.names)){
#   for(j in 1:length(YEARS)){
#     load(file=paste(unit.names[i], "_",YEARS[j],"_3_BM_Mg_CRM.Rdata", sep=""))
#     assign(paste(unit.names[i],"_3_sum_BM_",YEARS[j],sep=""), sum_D_BM_Mg)
#   }
# }

# # Put summed BM into table
# for(i in 1:length(unit.names)){
#   df[unit.names==unit.names[i],"BM_3_2016_tot"]<- get(paste(unit.names[i],"_3_sum_BM_", "2016", sep=""))
# }
# 
# for(i in 1:length(unit.names)){
#   df[unit.names==unit.names[i],"BM_3_1215_tot"]<- get(paste(unit.names[i],"_3_sum_BM_", "1215", sep=""))
# }

# Calculate Mg/ha and percent change

# df$BM_3_Mgha_1215 <- df$BM_3_1215_tot/df$L.area.ha
# df$BM_3_Mgha_2016 <- df$BM_3_2016_tot/df$L.area.ha
# df$BM_3_Mhga <- df$BM_3_Mgha_1215+df$BM_3_Mgha_2016
# df$Perc_D_3 <- df$BM_3_Mhga/df$BM3 

setwd(paste(CEC, "/Biomass/Results", sep=""))
save(df, file = "RESULTS_TABLE_FULL_CRM.Rdata")
write.csv(df, "results_table_full_CRM.csv", row.names = T)
