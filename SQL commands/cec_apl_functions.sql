CREATE or replace FUNCTION elevUSGS (x double precision, y double precision)
  RETURNS double precision
AS $$
import urllib2
import ast
nedQuery = 'http://ned.usgs.gov/epqs/pqs.php?x={0}&y={1}&units=Meters&output=json'
resp = urllib2.urlopen(nedQuery.format(x,y))
di = ast.literal_eval(resp.read())
return di['USGS_Elevation_Point_Query_Service']['Elevation_Query']['Elevation']
$$ LANGUAGE plpythonu;
