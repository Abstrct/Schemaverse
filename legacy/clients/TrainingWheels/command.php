<?
session_start();
$error = 1;
$cmd = trim($_GET['cmd']);
	
if ($cmd == 'register' || $cmd == 'login') 
{
	$_GET['username'] = strtolower(preg_replace('/[^A-Za-z0-9_]/', '', str_replace(' ', '', $_GET['username'])));
} 
else
{
	if (!isset($_SESSION['username']))
	{
		$return['error'][$error++] = 'User logged out';
		$return['goto'] = 'index.php';
	}

	$player_connection = pg_connect("host=db.schemaverse.com dbname=schemaverse user=".strtolower($_SESSION['username']));
	if (pg_connection_status($player_connection) === 'PGSQL_CONNECTION_BAD') 
	{
		$return['error'][$error++] = 'Database issue... so this game probably will not be too much fun for the time being.';
	}	
}

if (!isset($return['error']))
{
//	$_GET['cmd'] =  base64_decode($_GET['cmd']);
	//pg_query('INSERT INTO history(player_id, command) VALUES(GET_PLAYER_ID(\'' . pg_escape_string($_SESSION['username']) .'\'),\''. pg_escape_string($_GET['cmd']).'\'::TEXT');
	
	$return['rid'] = md5(date(DATE_RFC822));			
	switch ($cmd)
	{
		case 'save_new':
			$return['type'] = 'query_save';
			
			$label = pg_escape_string($_GET['label']);
			$query = pg_escape_string($_GET['query']);
			
			$code_result = pg_query("INSERT INTO my_query_store(name, query_text) VALUES('{$label}','{$query}'::TEXT) RETURNING id");
			if (pg_affected_rows($code_result) == 1)
			{
				$return['msg'] = "Query {$label} has been saved successfully.";
				$return['affected_rows'] = pg_affected_rows($code_result);
				$return['num_rows'] = pg_num_rows($code_result);

				$return['column_count'] = pg_num_fields($code_result);
				for ($row = 0; $row < pg_num_rows($code_result); $row++)
				{
					$return['rows'][$row]['id'] = $row;
					for ($col = 0; $col < $return['column_count']; $col++)
					{
						$return['rows'][$row]['data'][$col] = pg_fetch_result($code_result, $row, $col);
					}
				}

			} else {
				$return['error'][$error++] = 'Sorry, your query could not be saved';	
			}
		break;
		case 'save_old':
			$return['type'] = 'query_save';
			
			$qid = $_GET['qid'];
			$label = pg_escape_string($_GET['label']);
			$query = pg_escape_string($_GET['query']);

			
			if (is_numeric($qid))	
				$code_result = pg_query($player_connection, "UPDATE my_query_store SET name='{$label}', query_text='{$query}'::TEXT  WHERE id={$qid}");
			else 
				 $return['error'][$error++] = "That ID wasn't numeric at all...not cool bro";


			if (pg_affected_rows($code_result) == 1)
			{
				$return['msg'] = "Query {$label} has been saved successfully.";
				$return['affected_rows'] = pg_affected_rows($code_result);
				$return['num_rows'] = pg_num_rows($code_result);

				$return['column_count'] = pg_num_fields($code_result);
				for ($row = 0; $row < pg_num_rows($code_result); $row++)
				{
					$return['rows'][$row]['id'] = $row;
					for ($col = 0; $col < $return['column_count']; $col++)
					{
						$return['rows'][$row]['data'][$col] = pg_fetch_result($code_result, $row, $col);
					}
				}

			} else {
				$return['error'][$error++] = 'Sorry, your query could not be saved';	
			}
		break;
		case 'delete':
			$return['type'] = 'delete';
			
			$qid = $_GET['qid'];
			
			if (is_numeric($qid))	
				$code_result = pg_query("DELETE FROM  my_query_store WHERE id={$qid}");
			else 
				 $return['error'][$error++] = "That ID wasn't numeric at all...not cool bro";


			if (pg_affected_rows($code_result) == 1)
			{
				$return['msg'] = "Query {$label} has been deleted successfully.";
			} else {
				$return['error'][$error++] = 'Sorry, your query could not be deleted';	
			}
		break;
		
		//load
		case 'load':
			$return['type'] = 'query_load';
			$qid = trim($_GET['qid']);
	
			if (is_numeric($qid))
			{
				$code_result = pg_query("SELECT id, name, query_text FROM my_query_store WHERE id='$qid'");
			} else {
				 $return['error'][$error++] = "That ID wasn't numeric at all...not cool bro";
			}
			if  (!$code_result) {
			   $return['error'][$error++] = "There was a problem with this query.... in the database game..";
			}
			if (pg_num_rows($code_result) == 0) {
				$return['error'][$error++] = "No query with that ID or Name. Try doing a SELECT * FROM my_query_store; to see which queries you have available.";
			} else {

				$return['affected_rows'] = pg_affected_rows($code_result);
				$return['num_rows'] = pg_num_rows($code_result);

				$return['column_count'] = pg_num_fields($code_result);
				for ($row = 0; $row < pg_num_rows($code_result); $row++)
				{
					$return['rows'][$row]['id'] = $row;
					for ($col = 0; $col < $return['column_count']; $col++)
					{
						$return['rows'][$row]['data'][$col] = stripslashes(pg_fetch_result($code_result, $row, $col));
					}
				}
			}
		break;
		case 'load_list':
			$return['type'] = 'list_load';
	
			$code_result = pg_query("SELECT * FROM my_query_store ORDER BY name ASC");

			if  (!$code_result) {
			   $return['error'][$error++] = "There was a problem with this query.... in the database game..";
			}

			if (pg_num_rows($code_result) == 0) {
				$return['error'][$error++] = "You have no saved queries";
			} else {
				$return['column_count'] = pg_num_fields($code_result);
				$return['affected_rows'] = pg_affected_rows($code_result);
				$return['num_rows'] = pg_num_rows($code_result);

				for ($row = 0; $row < pg_num_rows($code_result); $row++)
				{
					$return['rows'][$row]['id'] = $row;
					for ($col = 0; $col < $return['column_count']; $col++)
					{
						$return['rows'][$row]['data'][$col] = pg_fetch_result($code_result, $row, $col);
					}
				}
			}
		break;
		case 'execute':
			$return['type'] = 'query';
			$command = stripslashes(trim($_GET['query']));
			$command_result = pg_query($player_connection, $command);
			if  (!$command_result) {
			   $return['error'][$error++] = nl2br(pg_last_error($player_connection));
			   $return['error'][$error++] = nl2br($_GET['cmd']);
			} else {
				$return['affected_rows'] = pg_affected_rows($command_result);
				$return['num_rows'] = pg_num_rows($command_result);
				
				$return['column_count'] = pg_num_fields($command_result);
				for ($j = 0; $j < $return['column_count']; $j++) {
					$return['columns'] .=  pg_field_name($command_result, $j) . (($j<$return['column_count']-1)?', ':'');
					$return['columns_size'] .=  '150' . (($j<$return['column_count']-1)?', ':'');
					$return['columns_align'] .=  'right' . (($j<$return['column_count']-1)?', ':'');
					$return['column'][$j]['name'] = pg_field_name($command_result, $j);
					$return['column'][$j]['size'] = pg_field_prtlen($command_result, $j);
					$return['column'][$j]['type'] = pg_field_type($command_result, $j);
				}
				
				if($return['num_rows'] > 0) 
				{
					for ($row = 0; $row < pg_num_rows($command_result); $row++)
					{
						$return['rows'][$row]['id'] = $row;
						for ($col = 0; $col < $return['column_count']; $col++)
						{
							$return['rows'][$row]['data'][$col] = htmlspecialchars(pg_fetch_result($command_result, $row, $col));
						}
					}
				}
			}		
		break;
		case 'register':
			$return['type'] = 'register';
		
			$system_connection = pg_connect("host=db.schemaverse.com dbname=schemaverse user=schemaverse");
			if (isset($_GET['username'])) {
				if (!pg_query("INSERT INTO player(username, password, balance, fuel_reserve) VALUES('".$_GET['username']."','md5".MD5($_GET['password'].$_GET['username'])."',10000,100000)")) {
					$return['error'][$error++] = 'Username exists. ';	
				}	
			}
			pg_close($system_connection);
		case 'login':
			$player_connection = pg_connect("host=db.schemaverse.com dbname=schemaverse user=".$_GET['username']);
			$rset = pg_query("SELECT id FROM my_player WHERE upper(username)=upper('".$_GET['username']."') AND password='md5".md5($_GET["password"].$_GET['username'])."'");
	
			if (pg_num_rows($rset) == NULL)
			{
				$return['error'][$error++]  = "Password is incorrect. "; 
			} else {
				$return['error'][--$error] = NULL;
				$_SESSION['username'] = $_GET['username'];
			}
			$return['msg'] = "Login Complete";
			$return['username'] = $_GET['username'];
		break;
	}
}
print json_encode($return);

?>
