#!/usr/bin/perl
#############################
# 	Tic v0.7	    #
# Created by Josh McDougall #
#############################
# This no longer sits in the cron and should be run in a screen session instead


# use module
use DBI; 
 
#My quick off switch
while (1){ 

# Config Variables
my $db_name 	= "schemaverse";
my $db_username = "schemaverse";

# Make the master database connection
my $master_connection = DBI->connect("dbi:Pg:dbname=${db_name};host=localhost", $db_username);

# Move the rest of the ships in whatever direction they have specified
my $sql = <<SQLSTATEMENT;
BEGIN WORK;
LOCK TABLE ship, ship_control IN EXCLUSIVE MODE;
SELECT 
	MOVE(ship.id, ship_control.speed, 
	CASE WHEN ship_control.destination_x IS NULL AND ship_control.destination_y IS NULL THEN ship_control.direction ELSE NULL END, 
	ship_control.destination_x, ship_control.destination_y)
FROM 
	ship, ship_control  
WHERE
	 ship.id = ship_control.ship_id
	AND
	ship_control.speed <> 0
	AND 
	ship.last_move_tic != (SELECT last_value FROM tic_seq);
COMMIT WORK;
SQLSTATEMENT
$master_connection->do($sql); 


# Retreive Fleet Scripts and run them as the user they belong to
my $sql = <<SQLSTATEMENT;
SELECT 
	player.username as username,
	fleet.id as fleet_id,
	player.error_channel as error_channel
FROM 
	fleet, player
WHERE
	fleet.player_id=player.id
ORDER BY 
	player.username;
SQLSTATEMENT


my $rs = $master_connection->prepare($sql); 
$rs->execute();
$temp_user = '';
while (($player_username, $fleet_id, $error_channel) = $rs->fetchrow()) {

	if ($temp_user ne $player_username)
	{
		if ($temp_user ne '')
		{
			$temp_connection->disconnect();
			
		}
		$temp_user = $player_username;
		$temp_connection = DBI->connect("dbi:Pg:dbname=$db_name;host=localhost", $player_username);
		$temp_connection->{PrintError} = 0;
		$temp_connection->{RaiseError} = 1;
	}

	eval { $temp_connection->do("SELECT FLEET_SCRIPT_${fleet_id}()"); };
  	if( $@ ) {
		$temp_connection->do("NOTIFY ${error_channel}, 'Fleet script ${fleet_id} has failed to fully execute during the tic'; ");
	}
}
$temp_connection->disconnect();
$rs->finish;


#planets are mined
$master_connection->do("SELECT perform_mining()");

#dirty planet renewal hack
$master_connection->do("UPDATE planet SET fuel=fuel+10000 WHERE id in (select id from planet order by RANDOM() LIMIT 5000);");
	
#future_health is dealt with
$master_connection->do("BEGIN WORK; LOCK TABLE ship, ship_control IN EXCLUSIVE MODE; 
UPDATE ship SET current_health=max_health WHERE future_health >= max_health; 
UPDATE ship SET current_health=future_health WHERE future_health between 0 and  max_health;
UPDATE ship SET current_health=0 WHERE future_health < 0;
UPDATE ship SET last_living_tic=(SELECT last_value FROM tic_seq) WHERE current_health > 0;
UPDATE ship SET destroyed='t' WHERE ((SELECT last_value FROM tic_seq)-last_living_tic)>GET_NUMERIC_VARIABLE('EXPLODED') and player_id > 0;

COMMIT WORK;");



#UPDATE ship SET 
#	current_health=(CASE 
#		WHEN future_health >= max_health THEN max_health 
#		WHEN future_health BETWEEN 0 AND max_health THEN future_health
#		ELSE 0 END),
#	last_living_tic=(CASE 
#		WHEN future_health > 0  THEN (SELECT last_value FROM tic_seq)
#		ELSE last_living_tic END),
#	destroyed=(CASE
#		WHEN future_health < 1 AND (((SELECT last_value FROM tic_seq)-last_living_tic) + 1) > GET_NUMERIC_VARIABLE('EXPLODED') THEN 't'
#		ELSE 'f' END)::boolean
#	WHERE player_id > 0;




$master_connection->do("UPDATE player SET balance=balance+10;");

#Update some stats now and then
$master_connection->do("insert into stat_log  select * from current_stats WHERE mod(current_tic,60)=0;");

#Tic is increased to NEXTVAL
$master_connection->do("SELECT nextval('tic_seq')");	

#$master_connection->do("DELETE FROM event  WHERE toc < current_date - interval '1 week'");


$master_connection->disconnect();
sleep(60);

}
