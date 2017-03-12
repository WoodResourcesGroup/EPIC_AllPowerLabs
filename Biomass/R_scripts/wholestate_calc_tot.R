library(rgdal)
library(raster)

EPIC <- "C:/Users/Carmen/Box Sync/EPIC-Biomass"

setwd("C:/Users/Carmen/Desktop/Biomass_Results")
load("Results_1215_WS_25_CRM.Rdata")
spdf1215 <- spdf
remove(spdf)
#crop
load("Table_1215_WS_25_CRM.Rdata")
results1215 <- results
load("Table_2016_WS_25_CRM.Rdata")
results16 <- results
remove(results)

### TEST WHETHER RESULTS MATCH UNIT RESULTS

setwd(paste(EPIC, "/GIS Data/units", sep=""))
load(file="units.Rdata")
units <- spTransform(units, crs(spdf1215))

LNP <- units[12,]
plot(LNP)
results_LNP <- crop(spdf1215, extent(LNP)) 
plot(results_LNP, add=T)
xyz <- as.data.frame(cbind(results_LNP@data$x, results_LNP@data$y, results_LNP@data$D_BM_kg))
try.raster <- rasterFromXYZ(xyz, crs = crs(spdf1215))
#strt<-Sys.time()
raster.mask <- mask(try.raster, LNP)
test_sum_D_BM_Mg <- sum(subset(raster.mask@data@values, raster.mask@data@values>0))/1000
setwd(paste(EPIC, "/GIS Data/Results/Results_CRM", sep=""))
load("LNP_1215_25_BM_Mg_CRM.Rdata")

### COMPARE THESE TWO, THEY SHOULD BE THE SAME
test_sum_D_BM_Mg
sum_D_BM_Mg

### YAY IT WORKS!

### NOW JUST ADD UP ALL THE VALUES ON THE TABLES FOR THE WHOLE STATE, BY YEAR
sum12 <- sum(results1215$D_BM_kg[results1215$RPT_YR=="2012"])
sum13 <-sum(results1215$D_BM_kg[results1215$RPT_YR=="2013"])
sum14 <-sum(results1215$D_BM_kg[results1215$RPT_YR=="2014"])
sum15 <-sum(results1215$D_BM_kg[results1215$RPT_YR=="2015"])
sum16 <- sum(results16$D_BM_kg)
sums <- c(sum12,sum13,sum14,sum15,sum16)
sumsMg <- sums/1000
df <- as.data.frame(sumsMg)
df$Year <- c(2012,2013,2014,2015,2016)
totsum <- sum12+sum13+sum14+sum15+sum16
totsum
library(ggplot2)
ggplot(data=df)+
  geom_point(aes(x=Year, y=sumsMg/10000), size=2)+
  geom_line(aes(x=Year, y=sumsMg/10000))+
  ylab("10,000 Mg dead biomass")+
  labs(title="Biomass of tree mortality detected by ADS")

write.csv(df, file="statewide_table.csv")
  

