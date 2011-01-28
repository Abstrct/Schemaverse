#!/usr/bin/perl
#############################
# 	Tic v0.6	    #
# Created by Josh McDougall #
#############################
# Throw this in the cron and run it whenever you want the games tic interval to be.
# This part is highly untested so far and was just written quickly. Be kind D:


# use module
use DBI; 

# Config Variables
my $db_name 	= "schemaverse";
my $db_username = "schemaverse";

# Make the master database connection
my $master_connection = DBI->connect("dbi:Pg:dbname=${db_name};host=localhost", $db_username);

# Move all ships in the direction of their fleet leader
my $sql = <<SQLSTATEMENT;
SELECT 
	MOVE(ship.id, leader.speed, leader.direction, leader.destination_x, leader.destination_y)
FROM 
	ship, fleet, ship_control leader 
WHERE
	 ship.fleet_id = fleet.id
	AND
	fleet.lead_ship_id = leader.ship_id
SQLSTATEMENT
$master_connection->do($sql); 


# Move the rest of the ships in whatever direction they have specified
my $sql = <<SQLSTATEMENT;
SELECT 
	MOVE(ship.id, ship_control.speed, ship_control.direction, ship_control.destination_x, ship_control.destination_y)
FROM 
	ship, ship_control  
WHERE
	 ship.id = ship_control.ship_id
	AND
	ship.last_move_tic != (SELECT last_value FROM tic_seq)
SQLSTATEMENT
$master_connection->do($sql); 




# Retreive Fleet Leader Scripts and run them as the user they belong to
my $sql = <<SQLSTATEMENT;
SELECT 
	player.username as username,
	ship.id as ship_id

FROM 
	fleet, player, ship
WHERE
	fleet.lead_ship_id=ship.id
	AND
	ship.player_id=player.id
ORDER BY player.username;
SQLSTATEMENT

my $rs = $master_connection->prepare($sql); 
$rs->execute();
$temp_user = '';
while (($player_username, $ship_id) = $rs->fetchrow()) {
	if ($temp_user ne $player_username)
	{
		if ($temp_user ne '')
		{
			$temp_connection->disconnect();
			
		}
		$temp_user = $player_username;
		$temp_connection = DBI->connect("dbi:Pg:dbname=$db_name;host=localhost", $player_username);
		$temp_connection->{PrintError} = 0;
		$temp_connection->{RaiseError} = 0;
	}

	$temp_connection->do("SELECT SHIP_SCRIPT_${ship_id}();");
}
$temp_connection->disconnect();
$rs->finish;

# Retreive remaining scripts and run them as the user they belong to
my $sql = <<SQLSTATEMENT;
SELECT
        player.username as username,
        ship.id as ship_id

FROM
        player, ship
WHERE
        ship.id not in (select lead_ship_id from fleet where lead_ship_id is not NULL)
        AND
        ship.player_id=player.id
SQLSTATEMENT

my $rs = $master_connection->prepare($sql);
$rs->execute();
$temp_user = '';
while (($player_username, $ship_id) = $rs->fetchrow()) {
	if ($temp_user ne $player_username)
	{
		if ($temp_user ne '')
		{
			$temp_connection->disconnect();
		}
		$temp_user = $player_username;
		$temp_connection = DBI->connect("dbi:Pg:dbname=$db_name;host=localhost", $player_username);
		$temp_connection->{PrintError} = 0;
		$temp_connection->{RaiseError} = 0;	
	}

	$temp_connection->do("SELECT SHIP_SCRIPT_${ship_id}();");
}
$temp_connection->disconnect();
$rs->finish;





#planets are mined
$master_connection->do("select perform_mining()");

#dirty planet renewal hack
$master_connection->do("UPDATE planet SET fuel=fuel+100;");

	
#future_health is dealt with
$master_connection->do("UPDATE ship SET current_health=max_health WHERE future_health >= max_health;");
$master_connection->do("UPDATE ship SET current_health=future_health WHERE future_health between 0 and  max_health;");
$master_connection->do("UPDATE ship SET current_health=0 WHERE future_health < 0;");
$master_connection->do("UPDATE ship SET last_living_tic=(SELECT last_value FROM tic_seq) WHERE current_health > 0;");
$master_connection->do("DELETE FROM ship WHERE ((SELECT last_value FROM tic_seq)-last_living_tic)>GET_NUMERIC_VARIABLE('EXPLODED') and player_id > 0;");




#Update some stats now and then
$master_connection->do("insert into stat_log  select * from current_stats WHERE mod(current_tic,60)=0;");

#Tic is increased to NEXTVAL
$master_connection->do("SELECT nextval('tic_seq')");	


$master_connection->disconnect();
