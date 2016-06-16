-- Deploy view-public_variable
-- requires: table-variable
-- requires: function-get_player_id

BEGIN;

CREATE VIEW public_variable AS SELECT * FROM variable WHERE (private='f' AND player_id=0) OR player_id=GET_PLAYER_ID(SESSION_USER);

CREATE OR REPLACE RULE public_variable_delete AS
     ON DELETE TO public_variable DO INSTEAD  
         DELETE FROM variable WHERE variable.name::text = old.name::text AND variable.player_id = get_player_id(SESSION_USER);


CREATE OR REPLACE RULE public_variable_insert AS
    ON INSERT TO public_variable DO INSTEAD  
        INSERT INTO variable (name, char_value, numeric_value, description, player_id) 
            VALUES (new.name, new.char_value, new.numeric_value, new.description, get_player_id(SESSION_USER));


CREATE OR REPLACE RULE public_variable_update AS
    ON UPDATE TO public_variable DO INSTEAD  
        UPDATE variable SET numeric_value = new.numeric_value, description = new.description
            WHERE variable.name::text = new.name::text AND variable.player_id = get_player_id(SESSION_USER);

COMMIT;
