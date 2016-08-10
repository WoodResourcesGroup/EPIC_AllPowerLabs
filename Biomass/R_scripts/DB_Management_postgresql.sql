-- Move Transportation Files from Sandbox to biomass schema
ALTER TABLE sandbox."AnfTransportation" SET SCHEMA biomass;

-- Move multiple tables between schemas at once
DO
$$
DECLARE	
	row record;
BEGIN	
	FOR row IN SELECT tablename FROM pg_tables WHERE schemaname = 'sandbox'
	LOOP
		EXECUTE 'ALTER TABLE sandbox.' || quote_ident(row.tablename) || ' SET SCHEMA biomass;';
		
	END LOOP;
END;
$$;

-- Move tables from DroughtTreeMortality to biomass, change owners, and delete DroughtTreeMortality
ALTER TABLE "DroughtTreeMortality"."droughttree" SET SCHEMA biomass;
ALTER TABLE "DroughtTreeMortality"."highhazardzones" SET SCHEMA biomass;
ALTER TABLE biomass."droughttree" OWNER TO "APL_biomass";
ALTER SCHEMA biomass OWNER TO "APL_biomass";

DO
$$
DECLARE	
	row record;
BEGIN	
	FOR row IN SELECT tablename FROM pg_tables WHERE schemaname = 'biomass'
	LOOP
		EXECUTE 'ALTER TABLE biomass.' || quote_ident(row.tablename) || ' OWNER TO "APL_biomass";';
		
	END LOOP;
END;
$$;

