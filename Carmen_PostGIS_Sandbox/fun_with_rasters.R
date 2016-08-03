library(rgdal)
library(raster)
library(rgeos)
library(stringr)
library(dplyr)

### GONZALEZ DATA
setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/Gonzalez Data")
PG_biomass <- raster("California_above_biomass_2010.tif")
PG_analysis <- raster("California biomass 2010 analysis.tif")
plot(PG_biomass)
plot(PG_analysis)
crs(PG_biomass)
crs(PG_analysis) #EPSG 5070, same as LEMMA, in part because of what's in the PDF file in Gonzalez Data folder
extent(PG_biomass)

### LEMMA DATA
setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/LEMMA_gnn_sppsz_2014_08_28/")
LEMMA <- raster("mr200_2012")
crs(LEMMA) # 5070. based on what this guys says: http://gis.stackexchange.com/questions/128190/convert-srtext-to-proj4text
plot(LEMMA)
extent(LEMMA)
LEMMA <- crop(LEMMA, extent(-2362845, -1627605, 1232145, 2456985))
writeRaster(LEMMA, filename = "LEMMA.tif", format = "GTiff", overwrite = TRUE) # save a backup in case R crashes

### DROUGHT MORTALITY POLYGONS
setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/")
drought <- readOGR(dsn = "DroughtTreeMortality.gdb", layer = "DroughtTreeMortality") 
# plot(drought, add = TRUE) # only plot if necessary; takes a long ass time
crs(drought)
drought <- spTransform(drought, crs(LEMMA)) #change it to CRS of Gonzalez and LEMMA data
crs(drought)
writeOGR(obj=drought, dsn="tempdir",layer = "drought", driver="ESRI Shapefile")

### RAMIREZ DATA
setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/GIS Data/Ramirez Data/Copy of ENVI_FR.1754x4468x15x1000/")
GDALinfo("FR_2016.01.13_167.bsq")
CR_mort <- raster("FR_2016.01.13_167.bsq")
crs(CR_mort)
plot(CR_mort)
CR_mort <- projectRaster(CR_mort, crs=crs(drought))

### Find biomass for drought mortality polygons using Gonzalez data (based on raster_to_counties_FIRE_2014)

# Try with just one small area
hist(drought$ACRES, xlim=c(1000,22000), ylim=c(0,200)) # find a good subset of acreage
length(subset(drought, drought$ACRES >10000))
testdr <- subset(drought, drought$ACRES > 10000)
extent(testdr)
testdr <- crop(testdr, extent(extent(testdr)[1], extent(testdr)[2], extent(testdr)[3], 1727026))
testPG <- crop(PG_biomass, testdr)
plot(testPG)
plot(testdr, add = T) # looks good - no half polygons or anything
testPG <- as.data.frame(rasterToPoints(testPG))
coordinates(testPG) <- c("x","y") # Make it spatial
crs(testPG) <- crs(testdr)
o <- over(testPG, testdr)


States <- data.frame()
State.names <- unique(counties$STATEFP)
for(i in State.names[1:49]) {
  State <- counties[counties$STATEFP==i,]
  rState <- crop(r, State)
  rState <- as.data.frame(rasterToPoints(rState))
  coordinates(rState) <- c("x", "y")
  crs(rState) <- crs(State)
  o <- over(rState, State)
  d <- o %>%
    mutate(value = rState$whp2014_cls) %>% 
    group_by(GEOID) %>%
    summarize(mean_risk = mean(value),
              max_risk = max(value),
              risk_1 = length(value[value==1])/length(value),
              risk_2 = length(value[value==2])/length(value),
              risk_3 = length(value[value==3])/length(value),
              risk_4 = length(value[value==4])/length(value),
              risk_5 = length(value[value==5])/length(value),
              risk_6 = length(value[value==6])/length(value),
              risk_7 = length(value[value==7])/length(value))
  State@data <- left_join(State@data, d)
  States <- rbind(States, State@data)
}
names(States)[1] <- "state_fips"
names(States)[2] <- "county_fips"
Fire_Risk_by_County <- States
setwd("~/vortex/")
write.csv(Fire_Risk_by_County, "output/tidy_county_data/Fire_risk_2014.csv", row.names=F)