-- Deploy function-ensure_event_partition
-- requires: event-partitioned
--
-- round_control() creates each round's partition, but a rolled-back
-- transaction that called nextval('round_seq') can leave the sequence ahead of
-- the partitions (sequences are not transactional). Events for such a round
-- land in event_default. This function creates the partition and moves any
-- rows out of the default partition first, because a partition cannot be
-- attached while the default partition holds rows that belong in it.

BEGIN;

CREATE OR REPLACE FUNCTION ensure_event_partition(r integer) RETURNS boolean AS
$BODY$
DECLARE
	part text := format('event_round_%s', r);
	moved integer;
BEGIN
	IF to_regclass(part) IS NOT NULL THEN
		RETURN false;
	END IF;

	EXECUTE format('CREATE TABLE %I (LIKE event INCLUDING DEFAULTS INCLUDING CONSTRAINTS)', part);
	EXECUTE format('WITH moved AS (DELETE FROM event_default WHERE round_id = %s RETURNING *)
	                INSERT INTO %I OVERRIDING SYSTEM VALUE SELECT * FROM moved', r, part);
	GET DIAGNOSTICS moved = ROW_COUNT;
	EXECUTE format('ALTER TABLE event ATTACH PARTITION %I FOR VALUES IN (%s)', part, r);

	IF moved > 0 THEN
		RAISE NOTICE 'ensure_event_partition: created % and moved % rows out of event_default', part, moved;
	END IF;
	RETURN true;
END
$BODY$ LANGUAGE plpgsql VOLATILE SET search_path = public, pg_temp;

REVOKE ALL ON FUNCTION ensure_event_partition(integer) FROM PUBLIC;

COMMIT;
