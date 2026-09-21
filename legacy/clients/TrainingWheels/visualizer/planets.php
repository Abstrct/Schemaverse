<?php
require '../setup.php';
header("Content-type: application/json");

	$conn = connect();
	if (!$conn) {
		echo json_encode(array('planets' => array()));
		exit;
	}

	$result = pg_query($conn, "SELECT
			planets.*
		FROM planets
	");
	if (!$result) {
		echo json_encode(array('planets' => array()));
		exit;
	}

	$arr = pg_fetch_all($result);
	$planets = json_encode(array('planets' => $arr));
	echo $planets;
	pg_close($conn);
?>
