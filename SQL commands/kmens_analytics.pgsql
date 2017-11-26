
update lemma_kmeanscenters set biomass_total = temp.sum_biomass from 
(select cluster_no, kmeans_cluster_no, sum(d_bm_kg) as sum_biomass from lemma_kmeansclustering group by cluster_no, kmeans_cluster_no)
as temp where lemma_kmeanscenters.cluster_no = temp.cluster_no and lemma_kmeanscenters.kmeans_cluster_no = temp.kmeans_cluster_no


alter table lemma_kmeanscenters add column count_group INT;
UPDATE lemma_kmeanscenters SET count_group = ceil(count/112) where count is not null;
alter table lemma_kmeanscenters add column biomass_group INT;
UPDATE lemma_kmeanscenters SET biomass_group = 100*ceil((biomass_total/1000)/100) where count is not null;
alter table lemma_kmeanscenters add column convex_hull geometry;
update lemma_kmeanscenters set convex_hull = temp.geom from 
(select cluster_no, kmeans_cluster_no, ST_ConvexHull(st_collect(geom)) as geom from lemma_kmeansclustering group by cluster_no, kmeans_cluster_no) as temp 
where lemma_kmeanscenters.cluster_no = temp.cluster_no and lemma_kmeanscenters.kmeans_cluster_no = temp.kmeans_cluster_no and count is not null;
alter table lemma_kmeanscenters add column harvest_area numeric;
update lemma_kmeanscenters set harvest_area = st_area(convex_hull) where count is not null;

--- Run when other are done 
alter table lemma_kmeanscenters add column harvest_area_group numeric;
update lemmav2.lemma_kmeanscenters set harvest_area_group = 12.5*ceil(harvest_area*0.000247105/12.5) where count is not null;
alter table lemma_kmeanscenters add column biomass_per_acre numeric;
update lemma_kmeanscenters set biomass_per_acre = (biomass_total/1000)/(harvest_area*0.000247105) where count is not null;
alter table lemma_kmeanscenters add column biomass_per_acre_group numeric;
update lemma_kmeanscenters set biomass_per_acre_group = ceil(biomass_per_acre) where count is not null;


-- kmeans histogram 

select count(*) from lemma_kmeancenters where count is not null group by count_group; 
