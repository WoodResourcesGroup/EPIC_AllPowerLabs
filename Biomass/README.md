Mortality Biomass Estimation README
================
Carmen Tubbesing
August 26, 2016

-   [Assumptions](#assumptions)
-   [Projection](#projection)
-   [File Organization](#file-organization)
-   [Sources](#sources)
    -   [Datasets](#datasets)
    -   [References](#references)
-   [Process](#process)
-   [Output Variables](#output-variables)
-   [Tests](#tests)
-   [Further Manipulation](#further-manipulation)

Assumptions
===========

1.  All dead trees in recent drought mortality have been conifers.
2.  Aerial detection surveys accurately assess the number of dead dominant and codiminant trees in each polygon and the size of each polygon.
3.  LEMMA accurately estimates the average sizes, species, and densities of trees in each 30 x 30 m pixel.
4.  The ratio of dead trees in each pixel of a drought mortality polygon to the total number of dead trees in the polygon is proportional to conifer basal area in that pixel relative to other pixels. That is, more dead tree occur more where there is more conifer basal area.
5.  All dead trees in a given pixel are of the most common conifer species in that pixel.
6.  The diameter of every dead tree in a pixel is equal to the quadratic mean diameter of dominant and codominant conifers in that pixel, as calculated by LEMMA.

Projection
==========

All results are in X/Y coordinates that should be projected in EPSG: 5070.

File Organization
=================

-   R code assumes the user has the following located in their home directory:
    -   Box Sync folder
    -   Clone of the cec\_apl git repository
-   Source data is located in *Box Sync/EPIC-Biomass/GIS Data*
-   The *cec\_apl/Biomass* folder contains:
    -   *R\_scripts*:
        -   *LEMMA\_droughtmortality\_pixel.R*: code to calculate biomass from LEMMA and drought mortality data
        -   *parallelization.R*: same as above but using multiple cores for speed
        -  *test.R*: test the accuracy of the above results
    -   *Results*:
        -   *Trial\_Biomass\_Pixels\_LEMMA\_6.csv*: results for the subset of drought mortality polygons that fall within the extent Carlos Ramirez' analysis (chosen as an arbitrary sub-area for testing the code)

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
    1.  crop `LEMMA` to the size and shape of the polygon
    2.  extract coordinates of each `LEMMA` pixel that falls within the polygon

    <!-- -->

    1.  extract corresponding FIA plot IDs for each `LEMMA` pixel in the polygon
    2.  for each pixel within the polygon
        1.  assign a diameter -&gt; biomass equation based on the most common conifer species in that pixel
        2.  calculate average per-tree biomass using the above equation and the quadratic mean diameter of dominant and codominant conifers (from `LEMMA`)

    3.  combine these results into a data frame with one row
    4.  bind the data frame to that of other polygons

6.  Create a unique key for each pixel
7.  Write results to .csv file

Output Variables
================

<table>
<colgroup>
<col width="22%" />
<col width="29%" />
<col width="48%" />
</colgroup>
<thead>
<tr class="header">
<th align="left">Code</th>
<th align="left">Description</th>
<th align="left">Source(s) of data</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left"><code>key</code></td>
<td align="left">Unique pixel ID</td>
<td align="left">Analysis</td>
</tr>
<tr class="even">
<td align="left"><code>x</code></td>
<td align="left">X coordinate of pixel center</td>
<td align="left"><code>LEMMA</code></td>
</tr>
<tr class="odd">
<td align="left"><code>y</code></td>
<td align="left">Y coordinate of pixel center</td>
<td align="left"><code>LEMMA</code></td>
</tr>
<tr class="even">
<td align="left"><code>D_CONBM_kg</code></td>
<td align="left">Estimated biomass of dead conifers n the pixel in kg</td>
<td align="left"><code>LEMMA</code> &amp; <code>drought</code></td>
</tr>
<tr class="odd">
<td align="left"><code>relNO</code></td>
<td align="left">Approximate number of dead trees in pixel</td>
<td align="left">Number of dead trees from <code>drought</code> (<code>Pol.NO_TREE</code>), divied up based on <code>relBA</code> (below)</td>
</tr>
<tr class="even">
<td align="left"><code>relBA</code></td>
<td align="left">Pixel basal area (<code>BAC_GE_3</code>) relative to sum of <code>BAC_GE_3</code> of all pixels in the polygon</td>
<td align="left"><code>LEMMA</code></td>
</tr>
<tr class="odd">
<td align="left"><code>PlotID</code></td>
<td align="left">Corresponding FIA plot ID</td>
<td align="left"><code>LEMMA</code></td>
</tr>
<tr class="even">
<td align="left"><code>Pol.ID</code></td>
<td align="left">Polygon ID</td>
<td align="left">Analysis</td>
</tr>
<tr class="odd">
<td align="left"><code>Pol.x</code></td>
<td align="left">X coordinate of polygon centroid</td>
<td align="left"><code>drought</code></td>
</tr>
<tr class="even">
<td align="left"><code>Pol.y</code></td>
<td align="left">Y coordinate of polygon centroid</td>
<td align="left"><code>drought</code></td>
</tr>
<tr class="odd">
<td align="left"><code>RPT_YR</code></td>
<td align="left">Year mortality was reported</td>
<td align="left"><code>drought</code></td>
</tr>
<tr class="even">
<td align="left"><code>Pol.NO_TREE</code></td>
<td align="left">Number of dead trees in the polygon</td>
<td align="left"><code>drought</code></td>
</tr>
<tr class="odd">
<td align="left"><code>Pol.Shap_Ar</code></td>
<td align="left">Area of polygon in square meters</td>
<td align="left"><code>drought</code></td>
</tr>
<tr class="even">
<td align="left"><code>D_Pol_CONBM_kg</code></td>
<td align="left">Polygon dead biomass in kg, sum of <code>D_CONBM_kg</code> of all pixels in the polygon</td>
<td align="left"><code>LEMMA</code> &amp; <code>drought</code></td>
</tr>
<tr class="odd">
<td align="left"><code>All_CONBM_kgha</code></td>
<td align="left">Biomass density of all conifers &gt;= 2.5 cm dbh, dead or alive (<code>BPHC_GE_3_CRM</code>)</td>
<td align="left"><code>LEMMA</code></td>
</tr>
<tr class="even">
<td align="left"><code>All_Pol_CONBM_kgha</code></td>
<td align="left">Average density of all conifers (mean <code>ALL_CONBM_kgha</code> of all pixels in polygon)</td>
<td align="left"><code>LEMMA</code></td>
</tr>
<tr class="odd">
<td align="left"><code>CON_THA</code></td>
<td align="left">Conifers &gt;=2.5 cm dbh per hectare, dead or alive (<code>TPHC_GE_3</code>)</td>
<td align="left"><code>LEMMA</code></td>
</tr>
<tr class="even">
<td align="left"><code>QMDC_DOM</code></td>
<td align="left">Quadratic mean diameter in cm of dominant and codominant conifers</td>
<td align="left"><code>LEMMA</code></td>
</tr>
<tr class="odd">
<td align="left"><code>CONPL</code></td>
<td align="left">Most common conifer species in the pixel</td>
<td align="left"><code>LEMMA</code></td>
</tr>
<tr class="even">
<td align="left"><code>Av_BM_TR</code></td>
<td align="left">Average per-tree biomass of dead trees, in kg (<code>D_Pol_CONBM_k</code>/<code>Pol.NO_TREE</code>)</td>
<td align="left"><code>LEMMA</code> &amp; <code>drought</code></td>
</tr>
<tr class="odd">
<td align="left"><code>All_Pol_CON_NO</code></td>
<td align="left">Total number of conifers in the polygon, from <code>Pol.Shap_Ar</code> and <code>CON_THA</code></td>
<td align="left"><code>LEMMA</code></td>
</tr>
<tr class="even">
<td align="left"><code>All_Pol_CON_BM</code></td>
<td align="left">Total conifer bioimass in the polygon, from <code>Pol.Shap.Ar</code> and <code>All_Pol_CONBM_kgha</code></td>
<td align="left"><code>LEMMA</code></td>
</tr>
</tbody>
</table>

Tests
=====

The following tests were performed on a randomly selected polygon within `drought` in the file *R\_scripts/test.R* to check for accuracy of the results. When *test.R* is run, lines 82-92 should all individually return `TRUE`.

1.  `relBA` calculated by hand outside the for loop for a randomly selected pixel within the polygon equals `relBA` from loop results
2.  `relNO` from loop results equals `relBA` \* number of dead trees in pixel calculated by hand
3.  Pixels within 50 m of the polygon's centroid have the same raster values and X and Y coordinates as those produced by the loop
4.  Biomass of dead conifers in the pixel calculated by hand matches loop results
5.  `All_CONBM_kgha` from results matches attribute data in LEMMA
6.  `All_Pol_CONBM_kgha` from results equals the mean of `All_CONBM_kgha` for all pixels in the polygon
7.  `Pol.x` and `Pol.y` from results match `coordinates()` of the polygon
8.  `Pol.NO_TREE` from results matches the sum of `relNO` for all pixels
9.  `All_Pol_CON_NO` from results matches the sum of conifers per pixel calculated by hand from `TPHC_GE_3`

Further Manipulation
====================

There are a few components of the script that will most likely be altered in future runs. They are summarized below.

| Line Number | Step                                        |
|:------------|:--------------------------------------------|
| 60          | Specify min polygon size                    |
| 60          | Specify min number of dead tree per polygon |
| 176         | Select size of sample for testing the loop  |
| 199         | Name of results file                        |
