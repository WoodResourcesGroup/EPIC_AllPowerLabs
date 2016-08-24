CEC\_APL Dead Tree Biomass Estimation
================
Carmen Tubbesing
August 24, 2016

Assumptions
===========

1.  All dead trees in recent drought mortality have been conifers
2.  Aerial detection surveys accurately assess the number of dead dominant and codiminant trees in each polygon and the size of each polygon
3.  LEMMA accurately estimates the average sizes, species, and densities of trees in each 30 x 30 m pixel of their raster.
4.  The ratio of dead trees in each pixel of a drought mortality polygon to the total number of dead trees in the polygon is proportional to the amount of conifer biomass in that pixel relative to other pixels. That is, more dead tree occur more where there is more conifer biomass.
5.  All dead trees in a given pixel are of the most common conifer species of the in that pixel.
6.  The diameter of every dead tree in a pixel is equal to the quadratic mean diameter of dominant and codominant conifers in that pixel. \# Projection All results are in x/y coordinates that should be projected in EPSG: 5070.

File Organization
=================

-   Within the *cec\_apl/Biomass* folder, code is located in *R\_scripts* and results are located in *Results*
-   Source data is located in *Box Sync/EPIC-Biomass/GIS Data*
-   R code assumes the user has a Box Sync folder located in their home directory

Sources
=======

### Datasets

1.  LEMMA GNN species-size raster data (*LEMMA\_gnn\_sppsz\_2014\_08\_28*)
    -   State-wide estimates of tree species composition, size, biomass, etc.
    -   Download and variable descriptions can be found [here](http://lemma.forestry.oregonstate.edu/data/structure-maps)
    -   Methods described in LEMMA\_readme.pdf in the same Box Sync folder as LEMMA data
    -   Empirical FIA plot data was assigned to every 30 x 30 m pixel in California based on similaries between remote sensing results for that pixel and the FIA plot
    -   Each raster value is an FIA plot ID
        -   each plot ID has many corresponding pixels
        -   characteristics of plot IDs are described in the attribute table

2.  Drought mortality polygons (*DroughtTreeMortality.gdb*)
    -   Aerial detection survey results from manually recording tree mortality from aircraft
    -   Methods described [here](http://www.fs.usda.gov/detail/r5/forest-grasslandhealth/?cid=fsbdev3_046721) \#\#\# References

3.  Jenkins, J. C., D. C. Chojnacky, L. S. Heath, and R. A. Birdsey, â€œNational-scale biomass estimators for United States tree species,â€ For. Sci., vol. 49, no. 1, pp. 12â€“35, 2003.
    -   Includes equations predicting biomass based on diameter at breast height for major classes of conifer species
    -   These equations were used to estimate biomass in drought mortality polygons

Process
=======

Data from LEMMA and drought mortality polygons were combined to estimate dead tree biomass in the file *R\_scripts/LEMMA\_droughtmortality\_pixels.R* . The steps can be summarized as follows:

1.  Crop `LEMMA` data to include only California
2.  Tranform drought mortality polygon data (`drought`) to the same CRS as `LEMMA`, namely EPSG 5070
3.  Trim `drought` to exclude polygons that are 2 acres or smaller and/or have only 1 dead tree in them
4.  Create vectors of parameters for diameter -&gt; biomass equations for each conifer class
5.  For each polygon
    1.  crop LEMMA data to the size and shape of the polygon
    2.  extract coordinates of each LEMMA pixel that falls within the polygon

    <!-- -->

    1.  extract corresponding FIA plot IDs for each LEMMA pixel in the polygon
    2.  for each pixel within the polygon
        1.  assign a diameter -&gt; biomass equation based on the most common conifer species in that pixel
        2.  calculate average per-tree biomass using the above equation and the quadratic mean diameter of dominant and codominant conifers (from LEMMA)

    3.  combine these results into a data frame with one row
    4.  bind the data frame to that of other polygons

6.  Create a unique key for each pixel
7.  Write results to .csv and raster files

Variables
=========

| Code         | Description                                  |
|:-------------|:---------------------------------------------|
| ID           | Corresponding FIA plot ID                    |
| D\_CONBM\_kg | biomass of dead conifers in that pixel in kg |
| Pol.ID       | Polygon ID                                   |
| Pol.x        | x coordinate of polygon centroid             |
| Pol.y        | y coordinate of polygon centroid             |
| etc.         | .....                                        |

Manipulation
============

There are a few components of the script that will most likely be altered in future runs. They are summarized below.

| Line Number | Step                                        |
|:------------|:--------------------------------------------|
| 60          | Specify min polygon size                    |
| 60          | Specify min number of dead tree per polygon |
| 176         | Select size of sample for testing the loop  |
| 199         | Name of results file                        |