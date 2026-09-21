<?php
require '../setup.php';
header("Content-type: application/json");

	$conn = connect();
	if (!$conn) {
		echo json_encode(array('currentTic' => -1));
		exit;
	}

	$result = pg_query($conn, "SELECT * FROM tic_seq");
	if (!$result) {
		echo json_encode(array('currentTic' => -1));
		exit;
	}

	$arr = pg_fetch_all($result);
	$currentTic = json_encode(array('currentTic' => $arr[0]));
	echo $currentTic;
	pg_close($conn);
?>
