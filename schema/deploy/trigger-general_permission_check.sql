-- Deploy trigger-general_permission_check

BEGIN;


CREATE OR REPLACE FUNCTION general_permission_check()
  RETURNS trigger AS
$BODY$
DECLARE
        real_player_id integer;
        checked_player_id integer;
BEGIN
        IF SESSION_USER = 'schemaverse' THEN
                RETURN NEW;
        ELSEIF CURRENT_USER = 'schemaverse' THEN
                SELECT id INTO real_player_id FROM player WHERE username=SESSION_USER;

                IF TG_TABLE_NAME IN ('ship','fleet','trade_item') THEN
                        IF (TG_OP = 'DELETE') THEN
				RETURN OLD;
			ELSE 
			 	RETURN NEW;
			END IF;
                ELSEIF TG_TABLE_NAME = 'trade' THEN
                        IF TG_OP = 'UPDATE' THEN
                                IF (OLD.player_id_1 != NEW.player_id_1) OR (OLD.player_id_2 != NEW.player_id_2) THEN
                                        RETURN NULL;
                                END IF;
                                IF NEW.confirmation_1 != OLD.confirmation_1 AND NEW.player_id_1 != real_player_id THEN
                                        RETURN NULL;
                                END IF;
                                IF NEW.confirmation_2 != OLD.confirmation_2 AND NEW.player_id_2 != real_player_id THEN
                                        RETURN NULL;
                                END IF;
                        ELSEIF TG_OP = 'DELETE' THEN
	                         IF real_player_id in (OLD.player_id_1, OLD.player_id_2) THEN
					RETURN OLD;
				ELSE 
					RETURN NULL;
				END IF;
			END IF;
			
                         IF real_player_id in (NEW.player_id_1, NEW.player_id_2) THEN
                                RETURN NEW;
                        END IF;
                ELSEIF TG_TABLE_NAME in ('ship_control') THEN
                        IF TG_OP = 'UPDATE' THEN
                                IF OLD.ship_id != NEW.ship_id THEN
                                        RETURN NULL;
				  END IF;
                        END IF;
                        SELECT player_id INTO checked_player_id FROM ship WHERE id=NEW.ship_id;
                        IF real_player_id = checked_player_id THEN
                                RETURN NEW;
                        END IF;
                END IF;

        ELSE

                SELECT id INTO real_player_id FROM player WHERE username=SESSION_USER;

                IF TG_TABLE_NAME IN ('ship','fleet','trade_item') THEN
                        IF TG_OP = 'UPDATE' THEN
                                IF OLD.player_id != NEW.player_id THEN
                                        RETURN NULL;
                                END IF;
                        END IF;
                        NEW.player_id = real_player_id;
                        RETURN NEW;

                ELSEIF TG_TABLE_NAME = 'trade' THEN
                        IF TG_OP = 'UPDATE' THEN
                                IF (OLD.player_id_1 != NEW.player_id_1) OR (OLD.player_id_2 != NEW.player_id_2) THEN
                                        RETURN NULL;
                                END IF;
                                IF NEW.confirmation_1 != OLD.confirmation_1 AND NEW.player_id_1 != real_player_id THEN
                                        RETURN NULL;
                                END IF;
                                IF NEW.confirmation_2 != OLD.confirmation_2 AND NEW.player_id_2 != real_player_id THEN
                                        RETURN NULL;
                                END IF;
                        END IF;
                         IF real_player_id in (NEW.player_id_1, NEW.player_id_2) THEN
                                RETURN NEW;
                        END IF;
                ELSEIF TG_TABLE_NAME in ('ship_control') THEN
                        IF TG_OP = 'UPDATE' THEN
                                IF OLD.ship_id != NEW.ship_id THEN
                                        RETURN NULL;
				  END IF;
                        END IF;
                        SELECT player_id INTO checked_player_id FROM ship WHERE id=NEW.ship_id;
                        IF real_player_id = checked_player_id THEN
                                RETURN NEW;
                        END IF;
                END IF;
        END IF;
        RETURN NULL;
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;


CREATE TRIGGER A_SHIP_PERMISSION_CHECK BEFORE INSERT OR UPDATE ON ship
  FOR EACH ROW EXECUTE PROCEDURE GENERAL_PERMISSION_CHECK(); 

CREATE TRIGGER A_SHIP_CONTROL_PERMISSION_CHECK BEFORE INSERT OR UPDATE OR DELETE ON ship_control
  FOR EACH ROW EXECUTE PROCEDURE GENERAL_PERMISSION_CHECK(); 

CREATE TRIGGER A_FLEET_PERMISSION_CHECK BEFORE INSERT OR UPDATE OR DELETE ON fleet
  FOR EACH ROW EXECUTE PROCEDURE GENERAL_PERMISSION_CHECK(); 


COMMIT;
