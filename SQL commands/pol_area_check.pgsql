set search_path  = lemmav2, public;
-- not operational
select count(*) from (
    select x from 
    (select max(x) as x, "Pol.ID", max("Pol.Shap_Ar") from lemma_1215 union select max(x) as x, "Pol.ID", max("Pol.Shap_Ar")  from lemma_2016 group by "Pol.ID" order by "Pol.Shap_Ar" desc) as foo,
    (select x, pol_id_h[1], polygon_area_h[1] as area2 from lemma_total group by pol_id_h[1] order by polygon_area_h[1] desc) as bar
     where "Pol.Shap_Ar" > area2
) as foobar;