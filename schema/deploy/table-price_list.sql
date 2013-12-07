-- Deploy table-price_list

BEGIN;

CREATE TABLE price_list
(
	code character varying NOT NULL PRIMARY KEY,
	cost integer NOT NULL,
	description TEXT
);

COMMIT;
