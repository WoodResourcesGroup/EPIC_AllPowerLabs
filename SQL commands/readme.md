# SQL commands for simulation of dead biomass harvesting

Although some of the queries could be executed in a single run, the results have been split in separate tables. Considering the large scale and the complexity of some calculations we have chosen to use the queries as checkpoints along the process for rationality checks. 

This files attempts to explain the different queries and proceedure followed to obtain the results. The documentation will grow along with the succesful implementation of each of the queries. 

### ```lemma_joins.pgsql``` 
This query joins the results from the aerial surverys for the years 2012 - 2015 and the 2016. These table will produce different biomass estimations for the same pixel for each year. In order to perfom the spatial analysis the information of these pixels needs to be added. 

Also, for each year the same pixel can appear in two separate polygons. The query also takes into consideration this and assigns the pixel to the polygon with the largest area, if the area is the same for two polygon id's it breaks the tie using the year of the suvery. The results show that there are 28,060,962 independent pixels. 6,511,279 of these pixels are repeated along the years and 21,549,683 only appear once. 

### ```cluster_number_calculation.pgsql``` 



### ```kmeans_clustering.pgsql``` 

