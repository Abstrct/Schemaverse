#!/usr/bin/perl
#############################
# 	Tic v0.7	    #
# Created by Josh McDougall #
#############################
# Throw this in the cron and run it whenever you want the games tic interval to be.
# This part is highly untested so far and was just written quickly. Be kind D:


# use module
use DBI; 
 
#My quick off switch
if (1 eq 1){ 

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
	MOVE(ship.id, ship_control.speed, ship_control.direction, ship_control.destination_x, ship_control.destination_y)
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

$master_connection->do("UPDATE player SET balance=balance+10;");

#Update some stats now and then
$master_connection->do("insert into stat_log  select * from current_stats WHERE mod(current_tic,60)=0;");

#Tic is increased to NEXTVAL
$master_connection->do("SELECT nextval('tic_seq')");	

#$master_connection->do("DELETE FROM event  WHERE toc < current_date - interval '1 week'");


$master_connection->disconnect();

}
