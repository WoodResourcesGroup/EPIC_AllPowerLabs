
alter table lemma_kmeanscenters add column biomass_group INT;
UPDATE lemma_kmeanscenters SET slope_group = ceil(biomass_total/25)

alter table lemma_kmeanscenters add column count_group INT;
UPDATE lemma_kmeanscenters SET count_group = ceil(biomass_total/10)

create table kmeans_histogram as 

