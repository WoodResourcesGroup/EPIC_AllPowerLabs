-- Query to calculate the histogram values > 1 ton per pixel
with d_bm_stats as (
    select min("D_BM_kg")/1000 as min,
           max("D_BM_kg")/1000 as max
      from lemmav2.lemma_total where "D_BM_kg" > 100
)
select width_bucket(("D_BM_kg")/1000, min, max, 40) as bucket,
        int4range(min(("D_BM_kg")/1000)::INT, max(("D_BM_kg")/1000)::INT, '[]') as range,
        count(*) as freq
    from lemmav2.lemma_total, d_bm_stats where "D_BM_kg" > 100
group by bucket
order by bucket;


 -- Query for a particular YEAR
 set search_path = lemmav2, public; with d_bm_stats as (select min("D_BM_kg")/1000 as min, 
    max("D_BM_kg")/1000 as max from lemmav2.lemma_1215 where "D_BM_kg" > 100 and "RPT_YR" = 2012) 
    select width_bucket(("D_BM_kg")/1000, min, max, 40) as bucket, int4range(min(("D_BM_kg")/1000)::INT, 
    max(("D_BM_kg")/1000)::INT, '[]') as range, count(*) as freq from lemma_1215, d_bm_stats 
    where "D_BM_kg" > 100 and "RPT_YR" = 2012 group by bucket order by bucket;