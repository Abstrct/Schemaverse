#!/usr/bin/perl
#############################
# 	Ref v0.2	    #
# Created by Josh McDougall #
#############################
# This should be run inside a screen session
# Ref.pl makes sure no player has a query over ~1 minute. 
# Logging could be added here to monitor players trying to cuase problems and disable their accounts


# use module
use DBI; 
 
# Config Variables
my $db_name 	= "schemaverse";
my $db_username = "schemaverse";

while (1){ 

	# Make the master database connection
	my $master_connection = DBI->connect("dbi:Pg:dbname=${db_name};host=localhost", $db_username);


	my $sql = <<SQLSTATEMENT;
select 
	procpid as pid, 
	pg_notify(get_player_error_channel(usename::character varying), 'The following query was canceled due to timeout: ' ||current_query ),
	disable_fleet(CASE WHEN application_name ~ '^[0-9]+\$' THEN application_name::integer ELSE 0 END) as disabled,
	usename as username, 
	current_query as current_query,  
	pg_cancel_backend(procpid)  as canceled
from 
	pg_stat_activity 
where 
	datname = '${db_name}' 
	AND usename <> '${db_username}' 
	AND usename <> 'postgres'
        AND 
        (	 
		(
		current_query LIKE '%FLEET_SCRIPT_%' 
		AND (now() - query_start) > COALESCE(
						GET_FLEET_RUNTIME(CASE WHEN application_name ~ '^[0-9]+\$' THEN application_name::integer ELSE 0 END, usename::character varying), 
						'1 minute'::interval)
		)
         OR
		(
		current_query NOT LIKE '<IDLE>%' 
		AND current_query NOT LIKE '%FLEET_SCRIPT_%' 
		AND now() - query_start > interval '1 minute'
		)
	)
SQLSTATEMENT

	my $rs = $master_connection->prepare($sql); 
	$rs->execute();
	
	#while (($pid, $error_channel, $username, $current_query, $canceled) = $rs->fetchrow()) {}
	
	$rs->finish;

	$master_connection->disconnect();
	sleep(30);

}
