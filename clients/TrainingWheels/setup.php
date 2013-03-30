<?php

function connect(){
    $username = "USERNAME";
    $password = "PASSWORD";
    return $conn=pg_connect("host=db.schemaverse.com user=$username dbname=schemaverse password=$password connect_timeout=60");
}

ini_set('memory_limit', '-1');

?>