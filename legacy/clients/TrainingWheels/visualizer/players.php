<?php
  require '../setup.php';
  header("Content-type: application/json");

  $conn = connect();
  if (!$conn) {
    echo json_encode(array('players' => array()));
    exit;
  }

  $result = pg_query($conn, "SELECT conqueror_id,
        get_player_username(conqueror_id) AS conqueror_name, get_player_symbol(conqueror_id) AS symbol, get_player_rgb(conqueror_id) AS rgb
        FROM planets GROUP BY conqueror_id
    ");
  if (!$result) {
    echo json_encode(array('players' => array()));
    exit;
  }

  $arr = pg_fetch_all($result);
  $players = json_encode(array('players' => $arr));
  echo $players;
  pg_close($conn);
?>
