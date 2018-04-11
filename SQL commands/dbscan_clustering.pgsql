-- Create the clusters
DROP TABLE IF EXISTS lemma_dbscanclusters180;
CREATE TABLE lemmav2.lemma_dbscanclusters180 AS
select key, pol_id, ST_ClusterDBSCAN(geom, eps := 180, minpoints := 112) over () AS cluster_no,
"D_BM_kgsum_25CRM", "D_BM_kgsum_3CRM", "D_BMkg_sum25J", "D_BMkg_sum3J", geom
from lemmav2.lemma_totalv2 where county is not NULL;
delete from lemmav2.lemma_dbscanclusters180 where cluster_no is NULL;
alter table lemma_dbscanclusters180 add primary key (key, pol_id, cluster_no);

DROP TABLE IF EXISTS lemma_dbscanclusters200;
CREATE TABLE lemmav2.lemma_dbscanclusters200 AS
select key, pol_id, ST_ClusterDBSCAN(geom, eps := 200, minpoints := 112) over () AS cluster_no,
"D_BM_kgsum_25CRM", "D_BM_kgsum_3CRM", "D_BMkg_sum25J", "D_BMkg_sum3J", geom
from lemmav2.lemma_totalv2 where county is not NULL;
delete from lemmav2.lemma_dbscanclusters200 where cluster_no is NULL;
alter table lemma_dbscanclusters200 add primary key (key, pol_id, cluster_no);

DROP TABLE IF EXISTS lemma_dbscanclusters210;
CREATE TABLE lemmav2.lemma_dbscanclusters210 AS
select key, pol_id, ST_ClusterDBSCAN(geom, eps := 210, minpoints := 112) over () AS cluster_no,
"D_BM_kgsum_25CRM", "D_BM_kgsum_3CRM", "D_BMkg_sum25J", "D_BMkg_sum3J", geom
from lemmav2.lemma_totalv2 where county is not NULL;
delete from lemmav2.lemma_dbscanclusters210 where cluster_no is NULL;
alter table lemma_dbscanclusters210 add primary key (key, pol_id, cluster_no);

DROP TABLE IF EXISTS lemma_dbscanclusters215;
CREATE TABLE lemmav2.lemma_dbscanclusters215 AS
select key, pol_id, ST_ClusterDBSCAN(geom, eps := 215, minpoints := 112) over () AS cluster_no,
"D_BM_kgsum_25CRM", "D_BM_kgsum_3CRM", "D_BMkg_sum25J", "D_BMkg_sum3J", geom
from lemmav2.lemma_totalv2 where county is not NULL;
delete from lemmav2.lemma_dbscanclusters215 where cluster_no is NULL;
alter table lemma_dbscanclusters215 add primary key (key, pol_id, cluster_no);

DROP TABLE IF EXISTS lemma_dbscanclusters220;
CREATE TABLE lemmav2.lemma_dbscanclusters220 AS
select key, pol_id, ST_ClusterDBSCAN(geom, eps := 220, minpoints := 112) over () AS cluster_no, 
"D_BM_kgsum_25CRM", "D_BM_kgsum_3CRM", "D_BMkg_sum25J", "D_BMkg_sum3J", geom
from lemmav2.lemma_totalv2 where county is not NULL;
delete from lemmav2.lemma_dbscanclusters220 where cluster_no is NULL;
alter table lemma_dbscanclusters220 add primary key (key, pol_id, cluster_no);

DROP TABLE IF EXISTS lemma_dbscanclusters225;
CREATE TABLE lemmav2.lemma_dbscanclusters225 AS
select key, pol_id, ST_ClusterDBSCAN(geom, eps := 225, minpoints := 112) over () AS cluster_no,
"D_BM_kgsum_25CRM", "D_BM_kgsum_3CRM", "D_BMkg_sum25J", "D_BMkg_sum3J", geom
from lemmav2.lemma_totalv2 where county is not NULL;
delete from lemmav2.lemma_dbscanclusters225 where cluster_no is NULL;
alter table lemma_dbscanclusters225 add primary key (key, pol_id, cluster_no);

DROP TABLE IF EXISTS lemma_dbscanclusters250;
CREATE TABLE lemmav2.lemma_dbscanclusters250 AS
select key, pol_id, ST_ClusterDBSCAN(geom, eps := 250, minpoints := 112) over () AS cluster_no,
"D_BM_kgsum_25CRM", "D_BM_kgsum_3CRM", "D_BMkg_sum25J", "D_BMkg_sum3J", geom
from lemmav2.lemma_totalv2 where county is not NULL;
delete from lemmav2.lemma_dbscanclusters250 where cluster_no is NULL;
alter table lemma_dbscanclusters250 add primary key (key, pol_id, cluster_no);

DROP TABLE IF EXISTS lemma_dbscanclusters300;
CREATE TABLE lemmav2.lemma_dbscanclusters300 AS
select key, pol_id, ST_ClusterDBSCAN(geom, eps := 300, minpoints := 112) over () AS cluster_no,
"D_BM_kgsum_25CRM", "D_BM_kgsum_3CRM", "D_BMkg_sum25J", "D_BMkg_sum3J", geom
from lemmav2.lemma_totalv2 where county is not NULL;
delete from lemmav2.lemma_dbscanclusters300 where cluster_no is NULL;
alter table lemma_dbscanclusters300 add primary key (key, pol_id, cluster_no);

DROP TABLE IF EXISTS lemma_dbscanclusters400;
CREATE TABLE lemmav2.lemma_dbscanclusters400 AS
select key, pol_id, ST_ClusterDBSCAN(geom, eps := 400, minpoints := 112) over () AS cluster_no,
"D_BM_kgsum_25CRM", "D_BM_kgsum_3CRM", "D_BMkg_sum25J", "D_BMkg_sum3J", geom
from lemmav2.lemma_totalv2 where county is not NULL;
delete from lemmav2.lemma_dbscanclusters400 where cluster_no is NULL;
alter table lemma_dbscanclusters400 add primary key (key, pol_id, cluster_no);

-- Standard distance calculations centers creation

DROP TABLE IF EXISTS lemmav2.lemma_dbscancenters180;
CREATE TABLE lemmav2.lemma_dbscancenters180 AS
SELECT cluster_no, count(*), ST_Centroid(ST_Collect(geom)) AS center_geom, 
sum("D_BM_kgsum_25CRM") as biomass_total25crm, 
sum("D_BM_kgsum_3CRM") as biomass_total3crm, 
sum("D_BMkg_sum25J") as biomass_total25j, 
sum("D_BMkg_sum3J") AS biomass_total3j
FROM lemmav2.lemma_dbscanclusters180
GROUP BY cluster_no;

DROP TABLE IF EXISTS lemmav2.lemma_dbscancenters200;
CREATE TABLE lemmav2.lemma_dbscancenters200 AS
SELECT cluster_no, count(*), ST_Centroid(ST_Collect(geom)) AS center_geom, 
sum("D_BM_kgsum_25CRM") as biomass_total25crm, 
sum("D_BM_kgsum_3CRM") as biomass_total3crm, 
sum("D_BMkg_sum25J") as biomass_total25j, 
sum("D_BMkg_sum3J") AS biomass_total3j
FROM lemmav2.lemma_dbscanclusters200
GROUP BY cluster_no;

DROP TABLE IF EXISTS lemmav2.lemma_dbscancenters210;
CREATE TABLE lemmav2.lemma_dbscancenters210 AS
SELECT cluster_no, count(*), ST_Centroid(ST_Collect(geom)) AS center_geom, 
sum("D_BM_kgsum_25CRM") as biomass_total25crm, 
sum("D_BM_kgsum_3CRM") as biomass_total3crm, 
sum("D_BMkg_sum25J") as biomass_total25j, 
sum("D_BMkg_sum3J") AS biomass_total3j
FROM lemmav2.lemma_dbscanclusters210
GROUP BY cluster_no;

DROP TABLE IF EXISTS lemmav2.lemma_dbscancenters215;
CREATE TABLE lemmav2.lemma_dbscancenters215 AS
SELECT cluster_no, count(*), ST_Centroid(ST_Collect(geom)) AS center_geom, 
sum("D_BM_kgsum_25CRM") as biomass_total25crm, 
sum("D_BM_kgsum_3CRM") as biomass_total3crm, 
sum("D_BMkg_sum25J") as biomass_total25j, 
sum("D_BMkg_sum3J") AS biomass_total3j
FROM lemmav2.lemma_dbscanclusters215
GROUP BY cluster_no;

DROP TABLE IF EXISTS lemmav2.lemma_dbscancenters220;
CREATE TABLE lemmav2.lemma_dbscancenters220 AS
SELECT cluster_no, count(*), ST_Centroid(ST_Collect(geom)) AS center_geom, 
sum("D_BM_kgsum_25CRM") as biomass_total25crm, 
sum("D_BM_kgsum_3CRM") as biomass_total3crm, 
sum("D_BMkg_sum25J") as biomass_total25j, 
sum("D_BMkg_sum3J") AS biomass_total3j
FROM lemmav2.lemma_dbscanclusters220
GROUP BY cluster_no;

DROP TABLE IF EXISTS lemmav2.lemma_dbscancenters230;
CREATE TABLE lemmav2.lemma_dbscancenters230 AS
SELECT cluster_no, count(*), ST_Centroid(ST_Collect(geom)) AS center_geom, 
sum("D_BM_kgsum_25CRM") as biomass_total25crm, 
sum("D_BM_kgsum_3CRM") as biomass_total3crm, 
sum("D_BMkg_sum25J") as biomass_total25j, 
sum("D_BMkg_sum3J") AS biomass_total3j
FROM lemmav2.lemma_dbscanclusters230
GROUP BY cluster_no;

DROP TABLE IF EXISTS lemmav2.lemma_dbscancenters250;
CREATE TABLE lemmav2.lemma_dbscancenters250 AS
SELECT cluster_no, count(*), ST_Centroid(ST_Collect(geom)) AS center_geom, 
sum("D_BM_kgsum_25CRM") as biomass_total25crm, 
sum("D_BM_kgsum_3CRM") as biomass_total3crm, 
sum("D_BMkg_sum25J") as biomass_total25j, 
sum("D_BMkg_sum3J") AS biomass_total3j
FROM lemmav2.lemma_dbscanclusters250
GROUP BY cluster_no;

DROP TABLE IF EXISTS lemmav2.lemma_dbscancenters300;
CREATE TABLE lemmav2.lemma_dbscancenters300 AS
SELECT cluster_no, count(*), ST_Centroid(ST_Collect(geom)) AS center_geom, 
sum("D_BM_kgsum_25CRM") as biomass_total25crm, 
sum("D_BM_kgsum_3CRM") as biomass_total3crm, 
sum("D_BMkg_sum25J") as biomass_total25j, 
sum("D_BMkg_sum3J") AS biomass_total3j
FROM lemmav2.lemma_dbscanclusters300
GROUP BY cluster_no;

DROP TABLE IF EXISTS lemmav2.lemma_dbscancenters400;
CREATE TABLE lemmav2.lemma_dbscancenters400 AS
SELECT cluster_no, count(*), ST_Centroid(ST_Collect(geom)) AS center_geom, 
sum("D_BM_kgsum_25CRM") as biomass_total25crm, 
sum("D_BM_kgsum_3CRM") as biomass_total3crm, 
sum("D_BMkg_sum25J") as biomass_total25j, 
sum("D_BMkg_sum3J") AS biomass_total3j
FROM lemmav2.lemma_dbscanclusters400
GROUP BY cluster_no;

-- sum of square of distances calculation

alter table lemma_dbscancenters180 drop column if exists sum_distances_sq;
alter table lemma_dbscancenters180 add column sum_distances_sq NUMERIC;
UPDATE lemmav2.lemma_dbscancenters180 SET sum_distances_sq = temp.dist 
from (select lemma_dbscancenters180.cluster_no as clust_no, sum(st_distance(lemma_dbscanclusters180.geom, lemma_dbscancenters180.center_geom)^2.0) as dist from lemma_dbscanclusters180, lemma_dbscancenters180 where 
lemma_dbscancenters180.cluster_no = lemma_dbscanclusters180.cluster_no group by lemma_dbscancenters180.cluster_no) as temp where lemmav2.lemma_dbscancenters180.cluster_no = temp.clust_no; 

alter table lemma_dbscancenters200 drop column if exists sum_distances_sq;
alter table lemma_dbscancenters200 add column sum_distances_sq NUMERIC;
UPDATE lemmav2.lemma_dbscancenters200 SET sum_distances_sq = temp.dist 
from (select lemma_dbscancenters200.cluster_no as clust_no, sum(st_distance(lemma_dbscanclusters200.geom, lemma_dbscancenters200.center_geom)^2.0) as dist from lemma_dbscanclusters200, lemma_dbscancenters200 where 
lemma_dbscancenters200.cluster_no = lemma_dbscanclusters200.cluster_no group by lemma_dbscancenters200.cluster_no) as temp where lemmav2.lemma_dbscancenters200.cluster_no = temp.clust_no; 

alter table lemma_dbscancenters210 drop column if exists sum_distances_sq;
alter table lemma_dbscancenters210 add column sum_distances_sq NUMERIC;
UPDATE lemmav2.lemma_dbscancenters210 SET sum_distances_sq = temp.dist 
from (select lemma_dbscancenters210.cluster_no as clust_no, sum(st_distance(lemma_dbscanclusters210.geom, lemma_dbscancenters210.center_geom)^2.0) as dist from lemma_dbscanclusters210, lemma_dbscancenters210 where 
lemma_dbscancenters210.cluster_no = lemma_dbscanclusters210.cluster_no group by lemma_dbscancenters210.cluster_no) as temp where lemmav2.lemma_dbscancenters210.cluster_no = temp.clust_no; 

alter table lemma_dbscancenters215 drop column if exists sum_distances_sq;
alter table lemma_dbscancenters215 add column sum_distances_sq NUMERIC;
UPDATE lemmav2.lemma_dbscancenters215 SET sum_distances_sq = temp.dist 
from (select lemma_dbscancenters215.cluster_no as clust_no, sum(st_distance(lemma_dbscanclusters215.geom, lemma_dbscancenters215.center_geom)^2.0) as dist from lemma_dbscanclusters215, lemma_dbscancenters215 where 
lemma_dbscancenters215.cluster_no = lemma_dbscanclusters215.cluster_no group by lemma_dbscancenters215.cluster_no) as temp where lemmav2.lemma_dbscancenters215.cluster_no = temp.clust_no; 

alter table lemma_dbscancenters230 drop column if exists sum_distances_sq;
alter table lemma_dbscancenters230 add column sum_distances_sq NUMERIC;
UPDATE lemmav2.lemma_dbscancenters230 SET sum_distances_sq = temp.dist 
from (select lemma_dbscancenters230.cluster_no as clust_no, sum(st_distance(lemma_dbscanclusters230.geom, lemma_dbscancenters230.center_geom)^2.0) as dist from lemma_dbscanclusters230, lemma_dbscancenters230 where 
lemma_dbscancenters230.cluster_no = lemma_dbscanclusters230.cluster_no group by lemma_dbscancenters230.cluster_no) as temp where lemmav2.lemma_dbscancenters230.cluster_no = temp.clust_no; 

alter table lemma_dbscancenters220 drop column if exists sum_distances_sq;
alter table lemma_dbscancenters220 add column sum_distances_sq NUMERIC;
UPDATE lemmav2.lemma_dbscancenters220 SET sum_distances_sq = temp.dist 
from (select lemma_dbscancenters220.cluster_no as clust_no, sum(st_distance(lemma_dbscanclusters220.geom, lemma_dbscancenters220.center_geom)^2.0) as dist from lemma_dbscanclusters220, lemma_dbscancenters220 where 
lemma_dbscancenters220.cluster_no = lemma_dbscanclusters220.cluster_no group by lemma_dbscancenters220.cluster_no) as temp where lemmav2.lemma_dbscancenters220.cluster_no = temp.clust_no; 

alter table lemma_dbscancenters250 drop column if exists sum_distances_sq;
alter table lemma_dbscancenters250 add column sum_distances_sq NUMERIC;
UPDATE lemmav2.lemma_dbscancenters250 SET sum_distances_sq = temp.dist 
from (select lemma_dbscancenters250.cluster_no as clust_no, sum(st_distance(lemma_dbscanclusters250.geom, lemma_dbscancenters250.center_geom)^2.0) as dist from lemma_dbscanclusters250, lemma_dbscancenters250 where 
lemma_dbscancenters250.cluster_no = lemma_dbscanclusters250.cluster_no group by lemma_dbscancenters250.cluster_no) as temp where lemmav2.lemma_dbscancenters250.cluster_no = temp.clust_no; 

alter table lemma_dbscancenters300 drop column if exists sum_distances_sq;
alter table lemma_dbscancenters300 add column sum_distances_sq NUMERIC;
UPDATE lemmav2.lemma_dbscancenters300 SET sum_distances_sq = temp.dist 
from (select lemma_dbscancenters300.cluster_no as clust_no, sum(st_distance(lemma_dbscanclusters300.geom, lemma_dbscancenters300.center_geom)^2.0) as dist from lemma_dbscanclusters300, lemma_dbscancenters300 where 
lemma_dbscancenters300.cluster_no = lemma_dbscanclusters300.cluster_no group by lemma_dbscancenters300.cluster_no) as temp where lemmav2.lemma_dbscancenters300.cluster_no = temp.clust_no; 

alter table lemma_dbscancenters400 drop column if exists sum_distances_sq;
alter table lemma_dbscancenters400 add column sum_distances_sq NUMERIC;
UPDATE lemmav2.lemma_dbscancenters400 SET sum_distances_sq = temp.dist 
from (select lemma_dbscancenters400.cluster_no as clust_no, sum(st_distance(lemma_dbscanclusters400.geom, lemma_dbscancenters400.center_geom)^2.0) as dist from lemma_dbscanclusters400, lemma_dbscancenters400 where 
lemma_dbscancenters400.cluster_no = lemma_dbscanclusters400.cluster_no group by lemma_dbscancenters400.cluster_no) as temp where lemmav2.lemma_dbscancenters400.cluster_no = temp.clust_no; 

-- standard distances calculation
alter table lemma_dbscancenters180 drop column if exists standard_distance;
alter table lemma_dbscancenters180 add column standard_distance NUMERIC;
UPDATE lemmav2.lemma_dbscancenters180 SET standard_distance = sqrt(sum_distances_sq/count);

alter table lemma_dbscancenters200 drop column if exists standard_distance;
alter table lemma_dbscancenters200 add column standard_distance NUMERIC;
UPDATE lemmav2.lemma_dbscancenters200 SET standard_distance = sqrt(sum_distances_sq/count);

alter table lemma_dbscancenters210 drop column if exists standard_distance;
alter table lemma_dbscancenters210 add column standard_distance NUMERIC;
UPDATE lemmav2.lemma_dbscancenters210 SET standard_distance = sqrt(sum_distances_sq/count);

alter table lemma_dbscancenters215 drop column if exists standard_distance;
alter table lemma_dbscancenters215 add column standard_distance NUMERIC;
UPDATE lemmav2.lemma_dbscancenters215 SET standard_distance = sqrt(sum_distances_sq/count);

alter table lemma_dbscancenters220 drop column if exists standard_distance;
alter table lemma_dbscancenters220 add column standard_distance NUMERIC;
UPDATE lemmav2.lemma_dbscancenters220 SET standard_distance = sqrt(sum_distances_sq/count);

alter table lemma_dbscancenters230 drop column if exists standard_distance;
alter table lemma_dbscancenters230 add column standard_distance NUMERIC;
UPDATE lemmav2.lemma_dbscancenters230 SET standard_distance = sqrt(sum_distances_sq/count);

alter table lemma_dbscancenters250 drop column if exists standard_distance;
alter table lemma_dbscancenters250 add column standard_distance NUMERIC;
UPDATE lemmav2.lemma_dbscancenters250 SET standard_distance = sqrt(sum_distances_sq/count);

alter table lemma_dbscancenters300 drop column if exists standard_distance;
alter table lemma_dbscancenters300 add column standard_distance NUMERIC;
UPDATE lemmav2.lemma_dbscancenters300 SET standard_distance = sqrt(sum_distances_sq/count);

alter table lemma_dbscancenters400 drop column if exists standard_distance;
alter table lemma_dbscancenters400 add column standard_distance NUMERIC;
UPDATE lemmav2.lemma_dbscancenters400 SET standard_distance = sqrt(sum_distances_sq/count);










