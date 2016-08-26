# Random sample
i <- sample(nrow(drought), 1)

single <- drought[i,]
plot(single)

# Loop results
test1<- ploop(i,i)

# By hand 
clip1 <- crop(LEMMA, extent(single))
clip2 <- mask(clip1, single)
plot(clip2, add=T, colNA = "blue")

# Find random FIA plot within single
plot <- sample(na.omit(clip2@data@values), 1)
testplot <- subset(test1, test1$PlotID == plot)
reps <- length(subset(clip2@data@values, clip2@data@values == plot))
attributes <- subset(LEMMA@data@attributes[[1]], LEMMA@data@attributes[[1]][,"ID"] == plot)
attributes$QMDC_DOM # If this equals 0, move on to another test polygon
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

# Check the above loop by hand:   
plotBA <- subset(LEMMA@data@attributes[[1]], LEMMA@data@attributes[[1]][,"ID"] == plot)$BAC_GE_3
plotreps <- length(subset(ext[[1]], ext[[1]] == plot))  
plotBA <- plotBA*plotreps
plotBA == mat[mat$Var1 == plot,3] # THIS SHOULD BE TRUE

# Compare loop and by-hand BA results
relBA <- attributes$BAC_GE_3/sum(mat$BA)
relBA
relBA == unique(testplot$relBA) # THIS SHOULD BE TRUE

# Compare loop and by-hand relNO results
relNO <- relBA*ntrees
unique(testplot$relNO) == relBA*ntrees # THIS SHOULD BE TRUE

# Test that coordinates for each pixel line up with values
tiny <- crop(clip2, extent(coordinates(single)[1],coordinates(single)[1]+50,coordinates(single)[2],coordinates(single)[2]+50))
plot(tiny)
tinyxmin <- as.numeric(extent(tiny)[1])
tinyxmax <- as.numeric(extent(tiny)[2])
tinyymin <- as.numeric(extent(tiny)[3])
tinyymax <- as.numeric(extent(tiny)[4])
tinytest <- subset(test1, as.numeric(paste(test1$x)) > tinyxmin & as.numeric(paste(test1$x)) < tinyxmax & as.numeric(paste(test1$y)) > tinyymin & as.numeric(paste(test1$y)) < tinyymax)
tinytest$PlotID %in% tiny@data@values # SHOULD BE TRUE

# Test dead biomass calculations
attributes$CONPLBA
treeBM <- -2.5356 + 2.4349*log(attributes$QMDC_DOM) # ONLY IF THE ABOVE IS A PINE
treeBM <- exp(treeBM) # Checked this against graph in Jenkins paper
pixelBM <- treeBM*relNO
testplot$D_CONBM_kg == pixelBM

# Test Pol.x and Pol.y
testplot$Pol.x == coordinates(single)[1]
testplot$Pol.y == coordinates(single)[2]

# Test NO_TREES
testplot$Pol.NO_TREE == sum(as.numeric(paste((test1$relNO)))) # Should be true

# Test All_Pol_CON_NO
All_TPH <- as.data.frame(cbind(clip2@data@attributes[[1]]$ID, clip2@data@attributes[[1]]$TPHC_GE_3))
All_TPH <- subset(All_TPH, All_TPH$V1 %in% mat$Var1)
mat <- merge(mat, All_TPH, by.x = "Var1", by.y = "V1")
mat$NO <- mat$V2/10000*900
All_T <- sum(mat$NO*mat$Freq)
All_T == testplot$All_Pol_CON_NO

### FINAL TESTS: ALL OF THE FOLLOWING SHOULD RETURN TRUE
plotBA == mat[mat$Var1 == plot,3] # THIS SHOULD BE TRUE
relBA == unique(testplot$relBA) # THIS SHOULD BE TRUE
unique(testplot$relNO) == relBA*ntrees # THIS SHOULD BE TRUE
tinytest$PlotID %in% tiny@data@values # THIS SHOULD BE TRUE
testplot$D_CONBM_kg == pixelBM# THIS SHOULD BE TRUE
testplot$All_CONBM_kgha == subset(LEMMA@data@attributes[[1]], LEMMA@data@attributes[[1]][,"ID"] == plot)$BPHC_GE_3_CRM
mean(as.numeric(paste(test1$All_CONBM_kgha))) == unique(test1$All_Pol_CONBM_kgha)
testplot$Pol.x == coordinates(single)[1] # THIS SHOULD BE TRUE
testplot$Pol.y == coordinates(single)[2] # THIS SHOULD BE TRUE
testplot$Pol.NO_TREE == sum(as.numeric(paste((test1$relNO)))) # THIS SHOULD BE TRUE
All_T == testplot$All_Pol_CON_NO