<?php

function connect() {
    return $conn=pg_connect("host=db.schemaverse.com dbname=schemaverse user=".strtolower($_SESSION['username']));
}

ini_set('memory_limit', '-1');

?>