Mortality Biomass Estimation README
================
Carmen Tubbesing
February 3, 2017

-   [Assumptions](#assumptions)
-   [Projection](#projection)
-   [File Organization](#file-organization)
-   [Sources](#sources)
    -   [Datasets](#datasets)
    -   [References](#references)
-   [Process and Scripts Order](#process-and-scripts-order)
    -   [Setup for both analyses](#setup-for-both-analyses)
    -   [Setup specific to whole-state analysis](#setup-specific-to-whole-state-analysis)
    -   [Setup specific to management units analysis](#setup-specific-to-management-units-analysis)
    -   [Dead biomass calculations](#dead-biomass-calculations)
-   [Output Variables](#output-variables)

Assumptions
===========

1.  Aerial detection surveys (ADS) accurately assess the number of dead trees > 25 cm diameter in each polygon and the size of each polygon.
2.  LEMMA GNN accurately estimates the Component Ratio Method biomass and dominant species of trees in each 30 x 30 m pixel.
3.  The number of dead trees in a polygon are distributed across pixels in that polygon according to the proportion of total polygon live trees (sum of all `TPH_GE_25`) in each pixel 
4.  All dead trees in a given LEMMA GNN pixel are of the most common tree species in that pixel
5.  Dead trees smaller than 25 cm in diameter are not detected by ADS

Projection
==========

All results should be projected in the coordinate reference system EPSG: 5070.

File Organization
=================

-   R code assumes the user has the following located in their home directory:
    -   Box Sync folder "EPIC-Biomass" with all GIS data
    -   Clone of the cec\_apl git repository
-   Source data is located in *Box Sync/EPIC-Biomass/GIS Data*
-   The *cec\_apl/Biomass/R\_scripts* folder contains all relevant scripts to perform the calculations, most importantly:
    -   calculate dead tree biomass for the **whole state** from LEMMA and drought mortality data: *wholestate\_CRM.R*
    -   calculate dead tree biomass for **individual management units**: *units\_calc\_CRM\_25.R*
    -   calculate **live biomass** from LEMMA GNN (representing 2012 remote sensing data): *LEMMA\_live\_units\_step1.R* and *LEMMA\_live\_units\_step2.R*

Sources
=======

### Datasets

1.  `LEMMA`: GNN species-size raster data (*LEMMA\_gnn\_sppsz\_2014\_08\_28*)
    -   Download and variable descriptions can be found [here](http://lemma.forestry.oregonstate.edu/data/structure-maps)
    -   State-wide estimates of tree species composition, size, biomass, etc.
    -   Methods described in LEMMA\_readme.pdf in the same Box Sync folder as LEMMA data
    -   Empirical FIA plot data was assigned to every 30 x 30 m pixel in California based on similaries between remote sensing results for that pixel and the FIA plot
    -   Each raster value is an FIA plot ID
        -   each plot ID has many corresponding pixels
        -   characteristics of plot IDs are described in the attribute table

2.  `drought`: Drought mortality polygons (*DroughtTreeMortality.gdb*)
    -   Aerial detection survey results from manually recording tree mortality from aircraft
    -   Methods described [here](http://www.fs.usda.gov/detail/r5/forest-grasslandhealth/?cid=fsbdev3_046721)

### References

1.  Jenkins, J. C., D. C. Chojnacky, L. S. Heath, and R. A. Birdsey. "National-scale biomass estimators for United States tree species." For. Sci., vol. 49, no. 1, pp. 12-35, 2003.
    -   Includes equations predicting biomass based on diameter at breast height for major classes of tree species
    -   These equations were used to estimate biomass in drought mortality polygons

Process and Scripts Order
=========================

Data from LEMMA and drought mortality polygons were combined to estimate dead tree biomass. The steps can be summarized as follows, with the script performing each task in parentheses:

Setup for both analyses
-----------------------

1.  Crop `LEMMA` data to include only California (*1\_crop\_LEMMA.R*)
2.  Transform ADS data to the same crs as `LEMMA` and save it as .Rdata for easier loading (*2\_transform\_ADS.R*)

Setup specific to whole-state analysis
--------------------------------------

1.  Trim `drought` to exclude polygons that are 2 acres or smaller and/or have only 1 dead tree in them

Setup specific to management units analysis
-------------------------------------------

1.  Crop FS management unit boundaries to include only units of interest and transform to same crs as `LEMMA` (*crop\_FS.R*)
2.  Crop NPS boundaries to Lassen and save (*crop\_lnp.R*)
3.  Combine unit layers that can be combined and save (*units\_overlay.R*)
4.  Calculate live biomass from LEMMA GNN data by averaging component ratio method biomass of trees &gt; 2.5 cm dbh across all LEMMA GNN pixels with &gt;0 biomass (*LEMMA\_live\_units\_step1* and *LEMMA\_live\_units\_step2*)

Dead biomass calculations
-------------------------

1.  Create vectors of parameters for diameter -&gt; biomass equations for each tree class based on Jenkins equations
2.  For each polygon
    1.  crop `LEMMA` to the size and shape of the polygon
    2.  extract coordinates of each `LEMMA` pixel that falls within the polygon
    3.  extract corresponding FIA plot IDs for each `LEMMA` pixel in the polygon
    4.  for each pixel within the polygon
        1.  assign a diameter -&gt; biomass equation based on the most common tree species in that pixel
        2.  calculate average per-tree biomass using the above equation and the quadratic mean diameter of dominant and codominant trees (from `LEMMA`)

    5.  combine these results into a data frame with one row
    6.  bind the data frame to that of other polygons

3.  Create a unique key for each pixel
4.  Write results to .csv file

Output Variables
================

| Code | Description | Source(s) of data |
| :-- | :-- | :-- |
| `key` | Unique pixel ID | Analysis |
| `PlotID` | Corresponding FIA plot ID | `LEMMA` |
| `x` | X coordinate of pixel center | `LEMMA` |
| `y` | Y coordinate of pixel center | `LEMMA` |
| `n` | Number of pixels with this pixel's PlotID in the polygon | `LEMMA` |
| `freq` | Proportion of pixels in polygon with this pixel's PlotID | `LEMMA` |
| `TPH_GE_3` | Number of live trees per hectare over 2.5 cm dbh | `LEMMA` |
| `TPH_GE_25` | Number of live trees per hectare over 25 cm dbh | `LEMMA` |
| `TPH_GE_50` | Number of live trees per hectare over 50 cm dbh | `LEMMA` |
| `BPH_GE_3_CRM` | Biomass per hectare of live trees over 2.5 cm (kg/ha) | `LEMMA` |
| `BPH_GE_25_CRM` | Biomass per hectare of live trees over 25 cm (kg/ha) | `LEMMA` |
| `BPH_GE_50_CRM` | Biomass per hectare of live trees over 50 cm (kg/ha) | `LEMMA` |
| `FORTYPBA` | Forest type according to basal area | `LEMMA` |
| `ESLF_NAME` | Land use category | `LEMMA` |
| `TREEPLBA` | Most common tree species in the pixel according to basal area | `LEMMA` |
| `QMD_DOM` | Quadratic mean diameter in cm of dominant and codominant trees | `LEMMA` |
| `VPH_GE_25` | Volume of live trees >= 25 cm dbh in m^3/ha | `LEMMA` |
| `live_ratio` | Proportion of live trees >25 cm dbh of the entire polgyon that are in this pixel | `LEMMA` |
| `relNO` | Estimated number of dead trees in pixel | Number of dead trees from `drought` (`Pol.NO_TREE`), divied up based on `live_ratio` |
| `BPH_abs` | Biomass of live trees >25 cm in the pixel (kg) | BPH_GE_25_CRM multiplied by .09 |
| `VPT` | Average volume per live tree >25 cm in that pixel (m^3/tree) | VPH_GE_25 divided by TPH_GE_25|
| `BM_tree_kg` | Estimated biomass per tree for trees >25 cm | BPH_GE_25_CRM divided by TPH_GE_25 |
| `D_BM_kg` | Estimated biomass of dead trees in the pixel in kg | `LEMMA` & `drought` |
| `trunc` | 1 if estimated dead biomass equals live biomass (truncated), 0 if dead biomass is less than live biomass | `LEMMA` & `drought` |
| `Pol.x` | X coordinate of polygon centroid | `drought` |
| `Pol.y` | Y coordinate of polygon centroid | `drought` |
| `Pol.ID` | Polygon ID | Analysis |
| `D_Pol_BM_kg` | Polygon dead biomass in kg, sum of `D_BM_kg` of all pixels in the polygon | `LEMMA` & `drought` |
| `RPT_YR` | Year mortality was reported | `drought` |
| `Pol.NO_TREES1` | Number of dead trees in the polygon | `drought` |
| `Pol.Shap_Ar` | Area of polygon in square meters | `drought` |
| `Pol.Pixels` | Number of pixels in the polygon | `LEMMA` & `drought` |
| `D_BM_kgha` | Estimated biomass of dead trees in the pixel in kg/ha | `LEMMA` & `drought` |