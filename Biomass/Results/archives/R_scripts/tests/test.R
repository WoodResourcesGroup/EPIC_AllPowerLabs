### THESE TESTS VERIFY THAT RESULTS FROM BIOMASS CALCULATIONS MAKE SENSE
### ALL LINES OF CODE AT THE BOTTOM OF THIS SCRIPTS SHOULD RETURN "TRUE" IF THE RESULTS ARE OK
### *NOTE*: Must load drought data frame from LEMMA_ADS_AllSpp_AllYrs_Parall.R 

options(digits = 5)

### Load the results you're testing
if( Sys.info()['sysname'] == "Windows" ) {
  setwd("C:/Users/Carmen/Box Sync/EPIC-Biomass/R Results")
} else {
  setwd("~/Documents/Box Sync/EPIC-Biomass/R Results")
}
result.lemma.p <- read.csv(file = "LEMMA_ADS_AllSpp_AlYrs_011817.csv", header=T) # This takes a while! 


### Randomly sample a polygon from the drought mortality polygons
sam1 <- sample(nrow(drought), 1)

single <- drought[sam1,]
plot(single)

### Copy and paste the loop from LEMMA_ADS_AllSpp_AllYrs_Parall.R below, replacing result.lemma.p with test1

library(raster)
library(rgeos)

test<- function(sam) {
    single <- drought[sam,] # select one polygon
    clip1 <- crop(LEMMA, extent(single)) # crop LEMMA GLN data to the size of that polygon
    clip2 <- mask(clip1, single) # fit the cropped LEMMA data to the shape of the polygon
    pcoords <- cbind(clip2@data@values, coordinates(clip2)) # save the coordinates of each pixel
    pcoords <- as.data.frame(pcoords)
    pcoords <- na.omit(pcoords) # get rid of NAs in coordinates table (NAs are from empty cells in box around polygon)
    Pol.ID <- rep(sam, nrow(pcoords)) # create a Polygon ID
    ext <- extract(clip2, single) # extracts data from the raster - each extracted value is the FIA plot # of the raster cell, which corresponds to detailed data in the attribute table of LEMMA
    tab <- lapply(ext, table) # creates a table that counts how many of each raster value there are in the polygon
    s <- sum(tab[[1]]) # Counts total raster cells the polygon - this is different from length(clip2tg) because it doesn't include NAs
    mat <- as.data.frame(tab)
    mat2 <- as.data.frame(tab[[1]]/s) # gives fraction of polygon occupied by each plot type. Adds up to 1 for each polygon.
    mat2 <- merge(mat, mat2, by="Var1") # creates table with FIA plot IDs in polygon, number of each, and relative frequency of each
    
    # extract attribute information from LEMMA for each plot number contained in the polygon:
    L.in.mat <- subset(LEMMA@data@attributes[[1]], LEMMA@data@attributes[[1]][,"ID"] %in% 
                         mat[,1])[,c("ID","BA_GE_3","BPH_GE_3_CRM","TPH_GE_3","QMD_DOM","TREEPLBA")]
    
    ### Attribute meanings from LEMMA GLN:
    ### BA_GE_3 = basal area of live trees >= 2.5 cm dbh (m^2/ha)
    ### BPH_GE_3_CRM = Component Ratio Method biomass of all live trees >=2.5 cm dbh (kg/ha)
    ### TPH_GE_3 = Density of live trees >=2.5 cm dbh (trees/ha)
    ### QMD_DOM = 	Quadratic mean diameter of all dominant and codominant trees (cm)
    ### TREEPLBA = Tree species with plurality of basal area
    
    merge <- merge(L.in.mat, mat2, by.y = "Var1", by.x = "ID") # merge LEMMA data with polygon data into one table
    
    # The below for subloop calculates biomass per tree based on the average dbh of dominant and codominant trees for 
    # the most common species in each raster cell:
    merge$BM_tree_kg <- 0 # create biomass variable
    merge$D_BM_kg <- 0 # create dead biomass variable
    merge$relNO <- 0 # create relative number of trees variable
    for (i in 1:nrow(merge)) {
      cell <- merge[i,]
      if (cell$TREEPLBA %in% Cedars_Larch) { 
        num <- (B0[1] + B1[1]*log(cell$QMD_DOM)) # apply formula for biomass, but w/o the exp. 
      } else if (cell$TREEPLBA %in% Dougfirs) {
        num <- (B0[2] + B1[2]*log(cell$QMD_DOM))
      } else if (cell$TREEPLBA %in% Firs) {
        num <- (B0[3] + B1[3]*log(cell$QMD_DOM))
      } else if (cell$TREEPLBA %in% Pines) {
        num <- (B0[4] + B1[4]*log(cell$QMD_DOM))
      } else if (cell$TREEPLBA %in% Spruces) {
        num <- (B0[5] + B1[5]*log(cell$QMD_DOM))
      } else if (cell$TREEPLBA %in% mh) {
        num <- (B0[6] + B1[6]*log(cell$QMD_DOM))  
      } else if (cell$TREEPLBA %in% wo) {
        num <- (B0[7] + B1[7]*log(cell$QMD_DOM))  
      } else if (cell$TREEPLBA %in% mb) {
        num <- (B0[8] + B1[8]*log(cell$QMD_DOM))
      } else if (cell$TREEPLBA %in% aa) {
        num <- (B0[9] + B1[9]*log(cell$QMD_DOM))
      } else if (cell$TREEPLBA %in% mo) {
        num <- (B0[10] + B1[10]*log(cell$QMD_DOM))
      } else {
        num <- 0
      }
      if (num == 0) {
        merge[i,]$BM_tree_kg <- 0 # assign 0 if no trees
      } else {
        merge[i,]$BM_tree_kg <- exp(num) # finish the formula to assign biomass per tree in that pixel
      }
    }
    
    # Find biomass per pixel using biomass per tree and estimated number of trees
    pmerge <- merge(pcoords, merge, by.x ="V1", by.y = "ID") # pmerge has a line for every pixel
    # problem here
    pmerge$relBA <- pmerge$BA_GE_3/sum(pmerge$BA_GE_3) # Create column for % of polygon BA in that pixel. 
    tot_NO <- single@data$NO_TREE # Total number of trees in the polygon
    pmerge$relNO <- tot_NO*pmerge$relBA # Assign approximate number of trees in that pixel based on proportion of BA in the pixel 
    # and total number of trees in polygon
    pmerge$D_BM_kg <- pmerge$relNO*pmerge$BM_tree_kg # D_BM_kg is total dead biomass in that pixel, based on biomass per tree and estimated number of trees in pixel
    
    # Create vectors that are the same length as pmerge to combine into final table:
    D_Pol_BM_kg <- rep(sum(pmerge$D_BM_kg), nrow(pmerge)) # Sum biomass over the entire polygon 
    Av_BM_TR <- D_Pol_BM_kg/tot_NO # Calculate average biomass per tree based on total polygon biomass and number of trees in the polygon
    QMD_DOM <- pmerge$QMD_DOM # Find the average of the pixels' quadratic mean diameters 
    TREEPL <-  pmerge$TREEPLBA # Find the tree species that has a plurality in the most pixels
    Pol.x <- rep(gCentroid(single)@coords[1], nrow(pmerge)) # Find coordinates of center of polygon
    Pol.y <- rep(gCentroid(single)@coords[2], nrow(pmerge))
    RPT_YR <- rep(single@data$RPT_YR, nrow(pmerge)) # Create year vector
    Pol.NO_TREE <- rep(single@data$NO_TREE, nrow(pmerge)) # Create number of dead trees vector
    Pol.Shap_Ar <- rep(single@data$Shap_Ar, nrow(pmerge)) # Create area vector
    Pol.Pixels <- rep(s, nrow(pmerge)) # number of pixels
    
    # Estimate biomass of live AND dead trees based on LEMMA values of biomass per pixel:
    All_BM_kgha <- pmerge$BPH_GE_3_CRM 
    All_Pol_BM_kgha <- rep(mean(pmerge$BPH_GE_3_CRM),nrow(pmerge)) # Average across polygons
    THA <- pmerge$TPH_GE_3 
    
    # Bring it all together
    final <- cbind(pmerge$x, pmerge$y, pmerge$D_BM_kg, pmerge$relNO,pmerge$relBA, pmerge$V1, Pol.x, Pol.y, RPT_YR,Pol.NO_TREE, 
                   Pol.Shap_Ar,D_Pol_BM_kg,All_BM_kgha,All_Pol_BM_kgha,THA, QMD_DOM,Av_BM_TR, Pol.ID) #
    final <- as.data.frame(final)
    final$All_Pol_NO <- (single@data$Shap_Ar/10000*900)*THA # Estimate total number of trees in the polygon
    final$All_Pol_BM <- (single@data$Shap_Ar/10000*900)*All_Pol_BM_kgha # Estimate total tree biomass in the polygon
    final$D_BM_kgha <- final$V3/.09 # Find kg per ha of dead biomass
    return(final)
}
test1 <- test(sam1)
# Create a key for each pixel (row)
key <- seq(1, nrow(test1)) 
test1 <- cbind(key, test1)
# Rename variables whose names were lost in the cbind
names(test1)[names(test1)=="V1"] <- "x"
names(test1)[names(test1)=="V2"] <- "y"
names(test1)[names(test1)=="V3"] <- "D_BM_kg"
names(test1)[names(test1)=="V4"] <- "relNO"
names(test1)[names(test1)=="V5"] <- "relBA"
names(test1)[names(test1)=="V6"] <- "PlotID"


# By hand 
clip1 <- crop(LEMMA, extent(single))
clip2 <- mask(clip1, single)
plot(clip2, add=T, colNA = "blue")

# Find random FIA plot within single
plot <- sample(na.omit(clip2@data@values), 1)
testplot <- subset(test1, test1$PlotID == plot)
reps <- length(subset(clip2@data@values, clip2@data@values == plot))
attributes <- subset(LEMMA@data@attributes[[1]], LEMMA@data@attributes[[1]][,"ID"] == plot)
attributes$TREEPLBA
attributes$QMD_DOM 
### *NOTE* If the above equals 0, move on to another test polygon
npixels <- length(na.omit(clip2@data@values))
ntrees <- single@data$NO_TREE

# Find totBA based on frequency of each plot type
ext <- extract(clip2, single)
tab <- lapply(ext, table) # creates a table that counts how many of each raster value there are in the polygon
mat <- as.data.frame(tab)
mat$BA <- 0
for(i in 1:nrow(mat)) {
  row <- mat[i,]
  mat[i,3] <- subset(LEMMA@data@attributes[[1]], LEMMA@data@attributes[[1]][,"ID"] == row$Var1)$BA_GE_3*row$Freq
}

# Check the above loop by hand:   
plotBA <- subset(LEMMA@data@attributes[[1]], LEMMA@data@attributes[[1]][,"ID"] == plot)$BA_GE_3
plotreps <- length(subset(ext[[1]], ext[[1]] == plot))  
plotBA <- plotBA*plotreps
plotBA == mat[mat$Var1 == plot,3] # THIS SHOULD BE TRUE

# Compare loop and by-hand BA results
relBA <- attributes$BA_GE_3/sum(mat$BA)
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
tinytest <- subset(test1, as.numeric(paste(test1$x)) > tinyxmin & as.numeric(paste(test1$x)) < tinyxmax & as.numeric(paste(test1$y)) 
                   > tinyymin & as.numeric(paste(test1$y)) < tinyymax)
tinytest$PlotID %in% tiny@data@values # SHOULD BE TRUE

# Test dead biomass calculations
attributes$TREEPLBA
treeBM <- -2.5356 + 2.4349*log(attributes$QMD_DOM) # ONLY IF THE ABOVE IS A PINE
treeBM <- exp(treeBM) # Checked this against graph in Jenkins paper
pixelBM <- treeBM*relNO
testplot$D_BM_kg == pixelBM

# Test Pol.x and Pol.y
as.factor(unique(testplot$Pol.x)) == as.factor(coordinates(single)[1])
as.factor(unique(testplot$Pol.y)) == as.factor(coordinates(single)[2])

# Test NO_TREES
a <- unique(testplot$Pol.NO_TREE)[1] 
b <- sum(as.numeric(paste((test1$relNO)))) 
as.factor(a)==as.factor(b) # Should be true

# Test All_Pol_NO - NEED TO WORK ON THIS ONE
# Make data frame with FIA plot ID and density of live trees from LEMMA
##All_TPH <- as.data.frame(cbind(clip2@data@attributes[[1]]$ID, clip2@data@attributes[[1]]$TPH_GE_3))
##All_TPH <- subset(All_TPH, All_TPH$V1 %in% mat$Var1)
##mat <- merge(mat, All_TPH, by.x = "Var1", by.y = "V1")
##mat$NO <- mat$V2/10000*900
##All_T <- sum(mat$NO*mat$Freq)
##All_T == testplot$All_Pol_NO

### FINAL TESTS: ALL OF THE FOLLOWING SHOULD RETURN TRUE
plotBA == mat[mat$Var1 == plot,3] # THIS SHOULD BE TRUE
relBA == unique(testplot$relBA) # THIS SHOULD BE TRUE
unique(testplot$relNO) == relBA*ntrees # THIS SHOULD BE TRUE
tinytest$PlotID %in% tiny@data@values # THIS SHOULD BE TRUE
testplot$D_BM_kg == pixelBM# THIS SHOULD BE TRUE
testplot$All_BM_kgha == subset(LEMMA@data@attributes[[1]], LEMMA@data@attributes[[1]][,"ID"] == plot)$BPH_GE_3_CRM
#mean(as.numeric(paste(test1$All_BM_kgha))) == unique(test1$All_Pol_BM_kgha) # NEED TO WORK ON THIS ONE
as.factor(unique(testplot$Pol.x)) == as.factor(coordinates(single)[1])
as.factor(unique(testplot$Pol.y)) == as.factor(coordinates(single)[2])
as.factor(unique(testplot$Pol.NO_TREE)) == as.factor(sum(as.numeric(paste((test1$relNO))))) # THIS SHOULD BE TRUE
# All_T == testplot$All_Pol_NO # need to edit this