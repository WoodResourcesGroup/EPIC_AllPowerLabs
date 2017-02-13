# Open raster file

YEARS <- c("1215","2016")
##YEARS <- "2016"

setwd(paste(EPIC, "/GIS Data/LEMMA_units", sep=""))
load(file="LEMMA_units.Rdata")
load(file='LEMMA_KCNP.Rdata')
load(file='LEMMA_LTMU.Rdata')
load(file='LEMMA_SNF.Rdata')


unit.names <- c("MH","CSP", "ESP", "SQNP", "ENF", "LNP")
for(i in 1:length(unit.names)) {
  subset <- subset(LEMMA_units, LEMMA_units$UNIT==unit.names[i])
  assign(paste("LEMMA_",unit.names[i],sep=""), subset)
}

j <- 1

EPIC <- "C:/Users/Carmen/Box Sync/EPIC-Biomass"
unit.names <- c("LNP", "ENF","ESP","LTMU","CSP","SNF","SQNP","KCNP", "MH")
setwd(paste(EPIC, "/GIS Data/Results/Results_CRM", sep=""))
for(j in 1:2){
  for(i in 1:length(unit.names)) {
    YEAR <- YEARS[j]
    UNIT <- unit.names[i]
    load(file=paste(UNIT,"_raster_25_",YEAR,".Rdata",sep=""))
    assign(paste(UNIT,"_raster_",YEAR,sep=""), raster.mask)
    load(file=paste("Table_",YEAR,"_",UNIT,"_25_CRM.Rdata",sep=""))
    assign(paste(UNIT,"_table_",YEAR,sep=""),results)
  }
}

setwd(paste(EPIC, "/GIS Data/units", sep=""))
load(file="units.Rdata")
units <- spTransform(units, crs(raster.mask))
load(file="KCNP.Rdata")
KCNP <- spTransform(KCNP, crs(raster.mask))
setwd(paste(EPIC, "/GIS Data/tempdir", sep=""))
load(file="FS_LTMU.Rdata")
LTMU <- spTransform(FS_LTMU, crs(raster.mask))

### PLOT STUFF TOGETHER
for(i in 1:length(units)){
  UNIT <- unit.names[i]
  raster <- get(paste(UNIT,"_raster_2016",sep=""))
  print(max((na.omit(raster@data@values)/1000)*(10000/900)))
}
breakpoints <- c(0,50,100,200,400,800)
colors <- c("yellow","orange","red","brown","black")
plot(units)
plot(LTMU, add=T)
plot(KCNP, add=T)
plot((ENF_raster_2016/1000)*(10000/900),breaks=breakpoints,col=colors, add=T, main="2016 Drought Mortality Biomass Loss, Mg/ha", 
     legend.shrink=1, legend.width=2, zlim=c(0, 1),
     legend.args=list(text='Dead biomass, Mg/ha', side=4, font=2, line=2.3))
plot((SNF_raster_2016/1000)*(10000/900),breaks=breakpoints,col=colors, add=T, legend=F)
plot((SQNP_raster_2016/1000)*(10000/900),breaks=breakpoints,col=colors, add=T, legend=F)
plot(((KCNP_raster_2016/1000)*(10000/900)),breaks=breakpoints,col=colors, add=T, legend=F)
plot((LNP_raster_2016/1000)*(10000/900),breaks=breakpoints,col=colors, add=T, legend=F)
plot((LTMU_raster_2016/1000)*(10000/900),breaks=breakpoints,col=colors, add=T, legend=F)
plot((MH_raster_2016/1000)*(10000/900),breaks=breakpoints,col=colors, add=T, legend=F)

plot(r, legend.only=TRUE, legend.shrink=1, legend.width=2, zlim=c(0, 1),
     axis.args=list(at=pretty(0:1), labels=pretty(0:1)),
     legend.args=list(text='Whatever', side=4, font=2, line=2.3))
### TRY MERGING TABLES

MH_merge <- merge(MH_table_1215, LEMMA_MH, by=c("x","y"), all.x=T,all.y=T)
MH_merge <- merge(MH_merge, MH_)
names(MH_merge)
MH_merge$sumBMkgha <- MH_merge$D_BM_kgha.x+MH_merge$D_BM_kgha.y
sum(na.omit(MH_merge$sumBMkgha))
sum(na.omit(MH_table_1215$D_BM_kgha)) + sum(na.omit(MH_table_2016$D_BM_kgha))-sum(na.omit(MH_merge$sumBMkgha))
