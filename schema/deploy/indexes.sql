-- Deploy indexes

BEGIN;

CREATE INDEX event_toc_index ON event USING btree (toc);

CREATE INDEX ship_location_index ON ship USING GIST (location);
CREATE INDEX planet_location_index ON planet USING GIST (location);

CREATE INDEX ship_player ON ship USING btree (player_id);
CREATE INDEX ship_health ON ship USING btree (current_health);
CREATE INDEX ship_fleet ON ship USING btree (fleet_id);
CREATE INDEX ship_loc_only ON ship USING gist (CIRCLE(location,1));
CREATE INDEX ship_loc_range ON ship USING gist (CIRCLE(location,range));

CREATE INDEX fleet_player ON fleet USING btree (player_id);
CREATE INDEX event_player ON event USING btree (player_id_1);

CREATE INDEX planet_player ON planet USING btree (conqueror_id);
CREATE INDEX planet_loc_only ON planet USING gist (CIRCLE(location,100000));

COMMIT;
