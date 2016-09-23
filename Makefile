 #Change this to the target database 
dbname := cec

 #Table name in th database
pxTableName := lemma_biomass

 #Change this to the target schema
pxSchema := public

 #this should be the csv file
srcFile := 'sandbox/Trial_Biomass_Pixels_LEMMA_6.csv'


# this is just used to make a temporary database, the switch-db2.erg.berkeley.edu
${dbname}db:
	createdb ${dbname}
	psql -d ${dbname} -c 'create extension postgis;'
	curl https://epsg.io/5070-1252.sql?download | psql -d ${dbname}
	mkdir $@

.PHONY: db
db:${dbname}db

# this is the target to migrate the csv to the database.
# once you have the variables defines above run the following from the same direcotyr as the Makefile: 'make <dbname>db/px2db'

${dbname}db/px2db:
	./px2db.py ${srcFile} ${dbname} ${pxSchema} ${pxTableName}
	psql -d ${dbname} -c "SELECT AddGeometryColumn ('${pxSchema}','${pxTableName}','geom',5070,'POINT',2);"
	psql -d ${dbname} -c "update ${pxTableName} set geom = st_setsrid(st_makepoint(x,y),5070);"
	touch $@
