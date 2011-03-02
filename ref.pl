#!/usr/bin/perl
#############################
# 	Ref v0.1	    #
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
	get_player_error_channel(usename::character varying) as error_channel,
	usename as username, 
	current_query as current_query,  
	pg_cancel_backend(procpid)  as canceled
from 
	pg_stat_activity 
where 
	now() - query_start > interval '1 minute'
	AND datname = '${db_name}' AND usename <> '${db_username}'
	AND current_query <> '<IDLE>'; 
SQLSTATEMENT


	my $rs = $master_connection->prepare($sql); 
	$rs->execute();
	while (($pid, $error_channel, $username, $current_query, $canceled) = $rs->fetchrow()) {
		$master_connection->do("NOTIFY ${error_channel}, 'The following query was canceled due to timeout: ${current_query}'; ");
	}
	$rs->finish;

	$master_connection->disconnect();
	sleep(30);

}
