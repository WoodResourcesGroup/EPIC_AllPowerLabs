# SQL commands for simulation of dead biomass harvesting

Although some of the queries could be executed in a single run, the results have been split in separate tables. Considering the large scale and the complexity of some calculations we have chosen to use the queries as checkpoints along the process for rationality checks. 

This files attempts to explain the different queries and proceedure followed to obtain the results. The documentation will grow along with the succesful implementation of each of the queries. 

### ```lemma_joins.pgsql``` 
**Resulting table: lemma_total**

This query joins the results from the aerial surverys for the years 2012 - 2015 and the 2016. These table will produce different biomass estimations for the same pixel for each year. In order to perfom the spatial analysis the information of these pixels needs to be added. The columns are an aggregate array of the polygon id's and areas to which the pixel belongs. In later queries the values are obtained using indexing i.e., ```[1]```.

Also, for each year the same pixel can appear in two separate polygons. The query also takes into consideration this and assigns the pixel to the polygon with the largest area, if the area is the same for two polygon id's it breaks the tie using the year of the suvery. The results show that there are 28,060,962 independent pixels. 6,511,279 of these pixels are repeated along the years and 21,549,683 only appear once. 

### ```cluster_number_calculation.pgsql``` 
**Resulting table: lemma_clusterquantity**

The query takes the area value of the each polygon and divides it in areas of roughly 25 acres, if the area of the polygon is below 25 acres the cluster number is 1. The implementation uses the following formula ```(floor(pol_area / 101171) + 1)```, the value 101,171 is the equivalent to 25 acres in square meters. The resulting table contain the polygon_id, number of clusters and the area. 

The results show that out of the 83,491 polygons only 24,173 are larger than 25 acres. 

### ```kmeans_clustering.pgsql``` 
**Resulting table: lemma_clusters**



