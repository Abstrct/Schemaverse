<?php
require '../setup.php';
header("Content-type: application/json");

	$conn = connect();
	if (!$conn) {
		echo json_encode(array('ships' => array()));
		exit;
	}

  $tic = $_GET['tic'];
	$ship_result = pg_query($conn, "SELECT * FROM my_ships_flight_recorder WHERE tic=" . $tic);
	if (!$ship_result) {
		echo json_encode(array('ships' => array(), 'planets' => array()));
		exit;
	}
	$ship_arr = pg_fetch_all($ship_result);

	$planet_result = pg_query($conn, "SELECT * FROM my_events WHERE action='CONQUER' AND (player_id_1=GET_PLAYER_ID(SESSION_USER) OR player_id_2=GET_PLAYER_ID(SESSION_USER)) AND tic=" . $tic);
  	if (!$planet_result) {
  		echo json_encode(array('ships' => array(), 'planets' => array()));
  		exit;
  	}
  $planet_arr = pg_fetch_all($planet_result);

	$tic_data = json_encode(array('ships' => $ship_arr, 'planets' => $planet_arr));
	echo $tic_data;
	pg_close($conn);
?>
