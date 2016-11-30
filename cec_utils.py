from sqlalchemy import create_engine as ce
dbname = 'apl_cec'
host = 'switch-db2.erg.berkeley.edu'
user = ptittmann

def dbconfig(name, echoCmd=True):
    """
    returns a database engine object for querys and inserts
    -------------

    name = name of the PostgreSQL database
    echoCmd = True/False wheather sqlalchemy echos commands
    """
    #conString = '//username:{pwd}@{host}:{name}
    engine = ce('postgresql:///{0}'.format(name), echo=echoCmd)
    return engine
