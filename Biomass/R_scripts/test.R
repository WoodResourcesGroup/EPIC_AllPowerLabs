# Random sample
testsample <- sample(nrow(drought), 5)

# Test with first polygon
single <- drought[testsample[1],]
plot(single)
# Loop
test1<- ploop(testsample[1],testsample[1])
# By hand 
clip1 <- crop(LEMMA, extent(single))
clip2 <- mask(clip1, single)
# Find random FIA plot as a test
plot <- sample(na.omit(clip2@data@values), 1)
reps <- length(subset(clip2@data@values, clip2@data@values == plot))
attributes <- subset(LEMMA@data@attributes[[1]], LEMMA@data@attributes[[1]][,"ID"] == plot)
attributes$QMDC_DOM # If this equals 0, move on to the next test polygon

i <- 2
single <- drought[testsample[i],]
plot(single)
# Loop
test1<- ploop(testsample[i],testsample[i])
# By hand 
clip1 <- crop(LEMMA, extent(single))
clip2 <- mask(clip1, single)
plot(clip2, add=T, colNA = "blue")
# Find random FIA plot as a test
plot <- sample(na.omit(clip2@data@values), 1)
testplot <- subset(test1, test1$PlotID == plot)
reps <- length(subset(clip2@data@values, clip2@data@values == plot))
attributes <- subset(LEMMA@data@attributes[[1]], LEMMA@data@attributes[[1]][,"ID"] == plot)
dia <- attributes$QMDC_DOM # If this equals 0, move on to the next test polygon
spp <- attributes$CONPLBA
npixels <- length(na.omit(clip2@data@values))
ntrees <- single@data$NO_TREE
# Find totBA based on frequency of each plot type
ext <- extract(clip2, single)
tab <- lapply(ext, table) # creates a table that counts how many of each raster value there are in the polygon
mat <- as.data.frame(tab)
mat$BA <- 0
for(i in 1:nrow(mat)) {
  row <- mat[i,]
  mat[i,3] <- subset(LEMMA@data@attributes[[1]], LEMMA@data@attributes[[1]][,"ID"] == row$Var1)$BAC_GE_3*row$Freq
}
# check by hand:   
plotBA <- subset(LEMMA@data@attributes[[1]], LEMMA@data@attributes[[1]][,"ID"] == plot)$BAC_GE_3
plotreps <- length(subset(ext[[1]], ext[[1]] == plot))  
plotBA <- plotBA*plotreps
plotBA == mat[mat$Var1 == plot,3] # THIS SHOULD BE TRUE
##################

relBA <- attributes$BAC_GE_3/sum(mat$BA)
relBA
relBA == unique(testplot$relBA) # THIS SHOULD BE TRUE

unique(testplot$relNO) == relBA*ntrees # THIS SHOULD BE TRUE

testplot$x == 
