#!/usr/bin/perl
#############################
#       Stat v1.0           #
# Created by Josh McDougall #
#############################
# This should be run inside a screen session
# stat.pl keeps player_round_stats up to date

# use module
use DBI;

# Config Variables
my $db_name     = "schemaverse";
my $db_username = "schemaverse";

# Make the master database connection
my $master_connection = DBI->connect("dbi:Pg:dbname=${db_name};host=localhost", $db_username);

while (1){


        my $sql = "SELECT player_id, round_id FROM player_round_stats ORDER BY round_id DESC, last_updated ASC LIMIT 1;";

        my $rs = $master_connection->prepare($sql);
        $rs->execute();
        while (($player_id, $round_id) = $rs->fetchrow()) {
                my $sql = <<SQLSTATEMENT;
                UPDATE player_round_stats SET
                        damage_taken = current_player_stats.damage_taken,
                        damage_done = current_player_stats.damage_done,
                        planets_conquered = least(current_player_stats.planets_conquered,32767),
                        planets_lost = least(current_player_stats.planets_lost,32767),
                        ships_built = LEAST(current_player_stats.ships_built,32767),
                        ships_lost = least(current_player_stats.ships_lost,32767),
                        ship_upgrades = current_player_stats.ship_upgrades,
                        fuel_mined = current_player_stats.fuel_mined,
                        distance_travelled = current_player_stats.distance_travelled,
                        last_updated=NOW()
                FROM current_player_stats
                WHERE player_round_stats.player_id=current_player_stats.player_id
                        AND current_player_stats.player_id=${player_id} AND player_round_stats.round_id=${round_id};

SQLSTATEMENT
                $master_connection->do($sql);
	
		if ($player_id % 100 == 0) {
	                $sql = <<SQLSTATEMENT;
                UPDATE round_stats SET
                        avg_damage_taken = current_round_stats.avg_damage_taken,
                        avg_damage_done = current_round_stats.avg_damage_done,
                        avg_planets_conquered = current_round_stats.avg_planets_conquered,
                        avg_planets_lost = current_round_stats.avg_planets_lost,
                        avg_ships_built = current_round_stats.avg_ships_built,
                        avg_ships_lost = current_round_stats.avg_ships_lost,
                        avg_ship_upgrades =current_round_stats.avg_ship_upgrades,
                        avg_fuel_mined = current_round_stats.avg_fuel_mined,
			avg_distance_travelled = current_round_stats.avg_distance_travelled
                FROM current_round_stats
                WHERE round_stats.round_id=${round_id};

SQLSTATEMENT
                	$master_connection->do($sql);
		}
        }
        $rs->finish;

        #sleep(5);
}
$master_connection->disconnect();
