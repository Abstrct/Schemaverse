import select
import psycopg2
import psycopg2.extensions
import getpass


print "Schemaverse Output Stream (SOS) v1.0"
Username = raw_input("Username: ")
Password = getpass.getpass()
Host = raw_input("Host: ")

conn = psycopg2.connect("dbname='schemaverse' user='" + Username + "' host='"+Host+"' password='"+Password +"'")
conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)

get_channel = conn.cursor()
get_channel.execute("""SELECT get_player_error_channel();""")
error_channel = get_channel.fetchone()

curs = conn.cursor()
curs.execute("LISTEN " + error_channel[0] + ";")
print "Waiting for notifications on error channel '"+ error_channel[0] +"'"
while 1:
    if select.select([conn],[],[],5) != ([],[],[]):
       	conn.poll()
        while conn.notifies:
       	    notify = conn.notifies.pop()
            print "[Error]", notify.payload
