
# Without taking out negative biomass values, there's one wacky pixel with negative bioamss and a non-integer key:
error <- subset(result.p, result.p$D_CONBM_kg<0)
errorpol <- subset(result.p, result.p$Pol.x == error$Pol.x)
errorpol
summary(result.p$key)

# Take a closer look at pixels with high bioamss:

result.p<- read.csv("Trial_Biomass_Pixels_LEMMA_cropped.csv")
hist(result.p$D_CONBM_kg, breaks = 500, xlim = c(-100000, 100000))
nrow(subset(result.p, result.p$pmerge.D_CONBM_kg >60000))/nrow(subset(result.p, result.p$pmerge.D_CONBM_kg >0))
## setting max at 60,000 retains 99% of the non-zero pixels
## CHECK Gonzalez paper to figure out what is an unreasonably large amount of biomass
result.p <- subset(result.p, result.p$pmerge.CONBM_kg < 60000)

# Look at an example polygon with pixels with very high biomass
result.p.test100 <- ploop(99,102)
big90 <- ploop(90,90)
hist(big90$relBA)
hist(big90$D_CONBM_kg)
length(subset(big90$relBA, big90$relBA == 0))
nrow(big90)

# Look closer at pixels with very high biomass estimations in result.p.small
hist(result.p.small$D_CONBM_kg)
hist(result.p.small$D_CONBM_kg, xlim = c(0,60000), breaks =60)
bigpixels <- subset(result.p.small$D_CONBM_kg, result.p.small$D_CONBM_kg > 60000)
sum(bigpixels)
length(result.p.small$D_CONBM_kg)
sum(bigpixels)/sum(na.omit((result.p.small$D_CONBM_kg)))
length(bigpixels)/length(result.p.small$D_CONBM_kg)
big <- subset(result.p.small, result.p.small$D_CONBM_kg > 60000)