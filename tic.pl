#!/usr/bin/perl
#############################
# 	Tic v0.3	    #
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
my $master_connection = 
DBI->connect("dbi:Pg:dbname=$db_name;host=localhost", $db_username);

# Move all ships in the direction of their fleet leader
my $sql = <<SQLSTATEMENT;
SELECT 
	MOVE(ship.id, leader.speed, leader.direction)
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
	MOVE(ship.id, ship_control.speed, ship_control.direction)
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
SQLSTATEMENT

my $rs = $master_connection->prepare($sql); 
$rs->execute();
while (($player_username, $ship_id) = $rs->fetchrow()) {
	$temp_connection = DBI->connect('dbi:Pg:dbname=$db_name;host=localhost', $player_username);
	$temp_connection->do("SELECT SHIP_SCRIPT_${ship_id}();");
	$temp_connection->disconnect();
}
$rs->finish;

#planets are mined
$master_connection->do("select perform_mining()");

	
#future_health is dealt with
$master_connection->do("UPDATE ship SET current_health=future_health");	

#Tic is increased to NEXTVAL
$master_connection->do("SELECT nextval('tic_seq')");	


$master_connection->disconnect();
