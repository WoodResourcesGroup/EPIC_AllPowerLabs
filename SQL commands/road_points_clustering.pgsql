
-- using cluster within A

drop table lemmav2.road_cluster_test;
create table lemmav2.road_cluster_test as (
select row_number() over (), landing_road,
unnest(ST_ClusterWithin(landing_point,100)) as geom_collection,
ST_GeometryN(unnest(ST_ClusterWithin(landing_point,100)),1) as geom,
ST_MinimumBoundingCircle(unnest(ST_ClusterWithin(landing_point,100))) AS circle
from lemma_kmeanscenters 
group by landing_road);
update road_cluster_test set row_number =  temp.row_no from 
(select ctid, row_number() over (partition by landing_road) as row_no from road_cluster_test) as TEMP
where road_cluster_test.ctid = temp.ctid


update lemmav2.lemma_kmeanscenters set clustered_landing_point = geom, clus_row_number = row_number from 
road_cluster_test where ST_within(landing_point,circle);

drop table lemmav2.road_cluster_test;
create table lemmav2.road_cluster_test as (
select landing_road, landing_point,
ST_ClusterDBSCAN(landing_point,100,1) over (partition by landing_road) as cluster_id
from lemma_kmeanscenters);


alter table lemma_kmeansclustering add column yarding_distance numeric;
update lemma_kmeansclustering set yarding_distance = temp.distance FROM
(select lemma_kmeansclustering.pol_id, 
lemma_kmeansclustering.key, 
lemma_kmeansclustering.linear_distance_to_road,
lemma_slope.slope,
lemma_kmeansclustering.linear_distance_to_road*sqrt(1+(lemma_slope.slope/100)^2) as distance
from lemma_kmeansclustering inner join lemma_slope using (key,pol_id)) as temp 
where lemma_kmeansclustering.key = temp.key and lemma_kmeansclustering.pol_id=temp.pol_id;  


-- Calculate the distances and lines to the landing points 

update lemmav2.lemma_kmeanscenters set clustered_landing_point = geom, clus_row_number = row_number from 
road_cluster_test where ST_within(landing_point,circle);

alter table lemma_kmeansclustering add colum landing_no INTEGER;
update lemmav2.lemma_kmeansclustering set landing_no=temp.landing_point from 
(select lemma_kmeansclustering.*, 
(lemma_kmeanscenters.landing_road*1000 + lemma_kmeanscenters.clus_row_number) as landing_point
from lemma_kmeansclustering inner join lemma_kmeanscenters using (cluster_no,kmeans_cluster_no)) as temp 
where lemma_kmeansclustering.key = temp.key and lemma_kmeansclustering.pol_id=temp.pol_id;  

update lemma_kmeansclustering set yarding_distance = temp.ayd from 
(select lemma_kmeansclustering.key, lemma_kmeansclustering.pol_id,
lemma_kmeansclustering.linear_distance_to_road,
(lemma_kmeansclustering.linear_distance_to_road)*lemma_slope.ayd_corr_factor as ayd from lemma_kmeansclustering 
inner join lemma_slope using (key,pol_id) ) as temp 
where lemma_kmeansclustering.key = temp.key and lemma_kmeansclustering.pol_id=temp.pol_id;  


update road_cluster_test set row_number =  temp.row_no from 
(select ctid, row_number() over (partition by landing_point) as row_no from road_cluster_test) as TEMP
where road_cluster_test.ctid = temp.ctid


-- Make the correction for yarding distances in the distance tables 

update lemma_kmeansclustering set yarding_distance = temp.ayd from 
(select lemma_kmeansclustering.key, lemma_kmeansclustering.pol_id,
lemma_kmeansclustering.linear_distance_to_road,
(lemma_kmeansclustering.linear_distance_to_road)*lemma_slope.ayd_corr_factor as ayd from lemma_kmeansclustering 
inner join lemma_slope using (key,pol_id) ) as temp 
where lemma_kmeansclustering.key = temp.key and lemma_kmeansclustering.pol_id=temp.pol_id;  

select * from substation_routes where (landing_road, landing_point) 
not in (select landing_road, clus_row_number from lemma_kmeanscenters where count is not null group by landing_road, clus_row_number) limi 10;

update substation_routes set center_ok = -1 where (landing_road, landing_point) 
not in (select landing_road, clus_row_number from lemma_kmeanscenters where count is not null group by landing_road, clus_row_number);