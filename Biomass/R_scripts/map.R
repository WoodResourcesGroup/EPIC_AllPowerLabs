### Open raster files, unit boundaries, and LEMMA_unit live biomass 

library(rgdal)
library(raster)

#EPIC <- "C:/Users/Battles Lab/Box Sync/EPIC-Biomass" # Define where your EPIC-BIOMASS folder is located in Box Sync
EPIC <- "C:/Users/Carmen/Box Sync/EPIC-Biomass"
YEARS <- c("1215","2016")
##YEARS <- "2016"

### OPEN LIVE BIOMASS
setwd(paste(EPIC, "/GIS Data/LEMMA_units", sep=""))
load(file="LEMMA_units.Rdata")
load(file='LEMMA_KCNP.Rdata')
load(file='LEMMA_LTMU.Rdata')
load(file='LEMMA_SNF.Rdata')

### Crop LEMMA live biomass to individual units 
unit.names <- c("MH","CSP", "ESP", "SQNP", "ENF", "LNP")
for(i in 1:length(unit.names)) {
  subset <- subset(LEMMA_units, LEMMA_units$UNIT==unit.names[i])
  assign(paste("LEMMA_",unit.names[i],sep=""), subset)
}

### LOAD MGMT UNIT BOUNDARIES
setwd(paste(EPIC, "/GIS Data/units", sep=""))
load(file="units.Rdata")
units <- spTransform(units, crs(LEMMA_units))
load(file="KCNP.Rdata")
kc <- spTransform(KCNP, crs(LEMMA_units))
setwd(paste(EPIC, "/GIS Data/tempdir", sep=""))
load(file="FS_LTMU.Rdata")
ltmu <- spTransform(FS_LTMU, crs(LEMMA_units))

units@data$id = rownames(units@data)
units.points = fortify(units, region="id")
units.bound = join(units.points, units@data, by="id")

kc@data$id = rownames(kc@data)
kc.points = fortify(kc, region="id")
kc.bound = join(kc.points, kc@data, by="id")

ltmu@data$id = rownames(ltmu@data)
ltmu.points = fortify(ltmu, region="id")
ltmu.bound = join(ltmu.points, ltmu@data, by="id")

### LOAD RESULTS AND RENAME BY MGMT UNIT
unit.names <- c("LNP", "ENF","ESP","LTMU","CSP","SNF","SQNP","KCNP", "MH")
setwd(paste(EPIC, "/GIS Data/Results/Results_CRM", sep=""))
for(j in 1:2){
  for(i in 1:length(unit.names)) {
    YEAR <- YEARS[j]
    UNIT <- unit.names[i]
    #load(file=paste(UNIT,"_raster_25_",YEAR,".Rdata",sep=""))
    #assign(paste(UNIT,"_raster_",YEAR,sep=""), raster.mask)
    load(file=paste("Table_",YEAR,"_",UNIT,"_25_CRM.Rdata",sep=""))
    #xy <- results[,c("x","y")]
    #spdf <- SpatialPointsDataFrame(coords=xy, data = results, proj4string = crs(LEMMA_units))
    #assign(paste(UNIT,"_spdf_",YEAR,sep=""), spdf)
    assign(paste(UNIT,"_table_",YEAR,sep=""),results)
  }
}
remove(results)
### MERGE RESULTS WITH LEMMA BIOMASS
# Turn LEMMA_units data into data frameS
for (i in 1:length(unit.names)){
  UNIT <- unit.names[i]
  df <-  as.data.frame(get(paste("LEMMA_",UNIT,sep="")))
  table16 <- get(paste(UNIT,"_table_2016",sep=""))
  merge <- merge(df,table16,by=c("x","y"), all.x=T, all.y=F)
  merge$BPH_GE_25_CRM <- merge$BPH_GE_25_CRM.x
  # Change NA's to 0
  merge$D_BM_kgha[is.na(merge$D_BM_kgha)] <- 0
  # Simplify
  merge <- merge[,c("x","y","BPH_GE_25_CRM","D_BM_kgha")]
  # Add 2012-2015 data
  table1215 <- get(paste(UNIT,"_table_1215",sep=""))
  merge <- merge(merge, table1215,by=c("x","y"), all.x=T, all.y=F)
  merge$D_BM_kgha.y[is.na(merge$D_BM_kgha.y)] <- 0
  # Add up dead biomass from all years
  merge$D_BM_kgha <- merge$D_BM_kgha.x+merge$D_BM_kgha.y
  # Calculate Percent change
  merge$BPH_GE_25_CRM <- merge$BPH_GE_25_CRM.x
  merge <- merge[,c("x","y","BPH_GE_25_CRM","D_BM_kgha")]
  merge$Perc_D <- merge$D_BM_kgha/merge$BPH_GE_25_CRM
  assign(paste(UNIT),merge)
}

### Open CA boundary shapefile
library(maptools)
library(plyr)
setwd(paste(EPIC, "/GIS Data", sep=""))
CA = readOGR(dsn="CA_boundary", layer="CA_Boundary")
crs(CA)
CA <- spTransform(CA, crs(LEMMA_CSP)) 
CA@data$id = rownames(CA@data)
CA.points = fortify(CA, region="id")
CA.bound = join(CA.points, CA@data, by="id")

library(RColorBrewer)
library(ggplot2)
library(extrafont)

unit.names <- c("LNP", "ENF","ESP","LTMU","CSP","SNF","SQNP","KCNP", "MH")

cols <- c('#a1d99b','#feb24c','#fd8d3c','#fc4e2a','#e31a1c','#b10026') # define colors
ggplot()+
  geom_tile(data=MH,aes(x=x,y=y,fill = Perc_D, color=Perc_D))+
  geom_tile(data=LNP,aes(x=x,y=y,fill = Perc_D, color=Perc_D))+
  geom_tile(data=SQNP,aes(x=x,y=y,fill = Perc_D, color=Perc_D))+
  geom_tile(data=SNF,aes(x=x,y=y,fill = Perc_D, color=Perc_D))+
  geom_tile(data=KCNP,aes(x=x,y=y,fill = Perc_D, color=Perc_D))+
  geom_tile(data=LTMU,aes(x=x,y=y,fill = Perc_D, color=Perc_D))+
  geom_tile(data=ENF,aes(x=x,y=y,fill = Perc_D, color=Perc_D))+
  geom_tile(data=CSP,aes(x=x,y=y,fill = Perc_D, color=Perc_D))+
  scale_colour_gradientn(colours = cols,
                         breaks=c(0,.05,.25,.5,.75,1),
                         labels=c("","5%","25%","50%","75%","100%"),
                         limits=c(0,1),
                         na.value="white")+
  scale_fill_gradientn(colours = cols,
                       limits=c(0,1),
                       breaks=c(0,.05,.25,.5,.75,1),
                       labels=c("","5%","25%","50%","75%","100%"),
                       na.value="white")+
  theme(axis.line=element_blank(),
    axis.text.x=element_blank(), axis.text.y=element_blank(),
    axis.ticks=element_blank(),
    axis.title.x=element_blank(), axis.title.y=element_blank(),
    panel.background=element_blank(),
    panel.grid.major=element_blank(), panel.grid.minor=element_blank(),
    plot.background=element_blank(),
    legend.title=element_blank(),
    plot.margin=unit(c(.5,.5,.5,.5), "cm"),
    plot.title = element_text(family = "Garamond", size = 14), 
    legend.position = c(.85, .85),  
    legend.text = element_text(family = "Garamond"),
    panel.border = element_rect(colour = "black", fill=NA, size=1))+
  labs(title="Percent loss of live adult tree\naboveground biomass, 2012-2016")+
  #
  geom_path(data=CA.bound,aes(x=long,y=lat,group=group), color="black")+
  geom_path(data=units.bound, aes(x=long,y=lat,group=group),color="black")+
  geom_path(data=kc.bound, aes(x=long,y=lat,group=group),color="black")+
  geom_path(data=ltmu.bound, aes(x=long,y=lat,group=group),color="black")+
  coord_fixed(xlim=c(-2352845, -1900000), ylim=c(1700000, 2356985))

### Smaller plots for just MH and CSP

extent(LEMMA_MH)
extent(LEMMA_CSP)

### MH
ggplot()+
  geom_tile(data=MH,aes(x=x,y=y,fill = Perc_D, color=Perc_D))+
  scale_colour_gradientn(colours = cols,
                         breaks=c(0,.05,.25,.5,.75,1),
                         guide='none',
                         limits=c(0,1),
                         na.value="white")+
  scale_fill_gradientn(colours = cols,
                       limits=c(0,1),
                       breaks=c(0,.05,.25,.5,.75,1),
                       guide='none',
                       na.value="white")+
  theme(axis.line=element_blank(),
        axis.text.x=element_blank(), axis.text.y=element_blank(),
        axis.ticks=element_blank(),
        axis.title.x=element_blank(), axis.title.y=element_blank(),
        panel.background=element_blank(),
        panel.grid.major=element_blank(), panel.grid.minor=element_blank(),
        plot.background=element_blank(),
        legend.title=element_blank(),
        plot.margin=unit(c(.5,.5,.5,.5), "cm"),
        plot.title = element_text(family = "Garamond", size = 14), 
        legend.position = c(.85, .85),  
        legend.text = element_text(family = "Garamond"),
        panel.border = element_rect(colour = "black", fill=NA, size=1))+
  labs(title="Mountain Home State Forest")+
  geom_path(data=units.bound, aes(x=long,y=lat,group=group),color="black")+
  coord_fixed(xlim=c(-2004900, -1995690), ylim=c(1701500, 1708890))


### CSP
ggplot()+
  geom_tile(data=CSP,aes(x=x,y=y,fill = Perc_D, color=Perc_D))+
  scale_colour_gradientn(colours = cols,
                         breaks=c(0,.05,.25,.5,.75,1),
                         guide='none',
                         limits=c(0,1),
                         na.value="white")+
  scale_fill_gradientn(colours = cols,
                       limits=c(0,1),
                       breaks=c(0,.05,.25,.5,.75,1),
                       guide='none',
                       na.value="white")+
  theme(axis.line=element_blank(),
        axis.text.x=element_blank(), axis.text.y=element_blank(),
        axis.ticks=element_blank(),
        axis.title.x=element_blank(), axis.title.y=element_blank(),
        panel.background=element_blank(),
        panel.grid.major=element_blank(), panel.grid.minor=element_blank(),
        plot.background=element_blank(),
        legend.title=element_blank(),
        plot.margin=unit(c(.5,.5,.5,.5), "cm"),
        plot.title = element_text(family = "Garamond", size = 14), 
        legend.position = c(.85, .85),  
        legend.text = element_text(family = "Garamond"),
        panel.border = element_rect(colour = "black", fill=NA, size=1))+
  labs(title="Calaveras Big Trees State Park")+
  geom_path(data=units.bound, aes(x=long,y=lat,group=group),color="black")+
  coord_fixed(xlim=c(-2084900, -2075910), ylim=c(1955910, 1963080))

