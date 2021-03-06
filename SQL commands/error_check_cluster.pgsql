-- Find Polygons with more clusters assigned than rows 
set search_path  = lemmav2, public;
drop table lemma_clusterabnormal;
CREATE TABLE lemmav2.lemma_clusterabnormal as
select lemma_clusterquantity.pol_id, lemma_clusterquantity.cluster_quantity, foo.count_grouped from lemma_clusterquantity inner join 
(select pol_id as pol_id_grouped, count(*) as count_grouped from lemma_total group by pol_id) as foo ON
 lemma_clusterquantity.pol_id = foo.pol_id_grouped where lemma_clusterquantity.cluster_quantity >= foo.count_grouped and lemma_clusterquantity.cluster_quantity > 1
 order by pol_id;
 -- drop the pizels with 0 and also abnormal values. A
 delete from lemma_total where "D_BM_kg_sum" = 0 and lemma_total.pol_id in (select pol_id from lemma_clusterabnormal); 

-- check the pixels with the abnormal numbers A

set search_path  = lemmav2, public;
select count(lemma_total.*) from lemma_total, lemma_clusterabnormal where lemma_total.pol_id = lemma_clusterabnormal.pol_id; 

-- Correction code 1 
set search_path  = lemmav2, public;
drop table lemmav2.abnormalfx_temp;
create table lemmav2.abnormalfx_temp as (
select abnormal.key, abnormal.pol_id as pol_id_o, final_pol.pol_id as pol_id_f, final_pol.pol_area from
	(select key, pol_id, geom 
	from lemma_total where lemma_total.pol_id in (select pol_id from lemma_clusterabnormal)) as abnormal
cross join lateral
	(select clean_lemma.pol_id, clean_lemma.pol_area from 
		(select lemma_total.* from lemma_total where lemma_total.pol_id not in (select pol_id from lemma_clusterabnormal)) as clean_lemma
ORDER BY abnormal.geom <-> clean_lemma.geom limit 1) as final_pol);

-- Table worked out ok, now the code for the substitution

select count(*) from lemma_total, abnormalfx_temp where lemma_total.key = abnormalfx_temp.key and lemma_total.pol_id = abnormalfx_temp.pol_id_o;

-- Update table query

set search_path  = lemmav2, public;
update lemma_total set pol_id = abnormalfx_temp.pol_id_f, pol_area = abnormalfx_temp.pol_area from abnormalfx_temp where lemma_total.key = abnormalfx_temp.key and lemma_total.pol_id = abnormalfx_temp.pol_id_o;
