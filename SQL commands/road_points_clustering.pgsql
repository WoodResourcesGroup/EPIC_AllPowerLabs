
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

-- Calculate the distances and lines to the landing points 

update lemmav2.lemma_kmeanscenters set clustered_landing_point = geom, clus_row_number = row_number from 
road_cluster_test where ST_within(landing_point,circle);

update lemmav2.lemma_kmeansclustering set linear_distance_to_road=temp.distance, line_to_road = temp.line from 
(select lemma_kmeansclustering.*, 
lemma_kmeanscenters.clustered_landing_point,
ST_MakeLine(lemma_kmeansclustering.geom,lemma_kmeanscenters.clustered_landing_point) as line, 
st_distance(lemma_kmeansclustering.geom,lemma_kmeanscenters.clustered_landing_point) as distance  
from lemma_kmeansclustering inner join lemma_kmeanscenters using (cluster_no,kmeans_cluster_no)) as temp 
where lemma_kmeansclustering.key = temp.key and lemma_kmeansclustering.pol_id=temp.pol_id;  


update road_cluster_test set row_number =  temp.row_no from 
(select ctid, row_number() over (partition by landing_point) as row_no from road_cluster_test) as TEMP
where road_cluster_test.ctid = temp.ctid