<?
session_start();
$_POST['username'] = strtolower(preg_replace('/[^A-Za-z0-9_]/', '', str_replace(' ', '', $_POST['username'])));

if ($_POST['login'] == 'Create Account and Login') {

	$system_connection = pg_connect("host=db.schemaverse.com dbname=schemaverse user=schemaverse");
	//$error=1;
	if (isset($_POST['username'])) {
		if (!pg_query("INSERT INTO player(username, password, balance, fuel_reserve) VALUES('".$_POST['username']."','md5".MD5($_POST['password'].$_POST['username'])."',10000,100000)")) {
			$msg = 'Username was taken. give er another shot';
			$error=1;
		}	
	}
	pg_close($system_connection);
}

$system_connection = pg_connect("host=db.schemaverse.com dbname=schemaverse user=".$_POST['username']);
$rset = pg_query("SELECT id FROM my_player WHERE upper(username)=upper('".$_POST['username']."') AND password='md5".md5($_POST["password"].$_POST['username'])."'");
if (pg_num_rows($rset) == NULL)
{
		$msg = ($msg != "" ) ? "Password is incorrect (or something)":$msg; 
		include ("login.html");     
        exit();
}

$_SESSION['username'] = $_POST['username'];
?>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">

  <head>
      <title> OMGTrainingWheels</title>
      <link href="/css/tw.css" rel="stylesheet" type="text/css" />    
      <link rel="stylesheet" href="/css/visualizer.css">
  </head>

  <body>
    <div id="header">
      <img src='/images/schemaverse-logo.png' width='250px'><br/><br/><br/>
      <b>[host=db.schemaverse.com dbname=schemaverse user=<?=$_SESSION['username']?>]</b>
    </div>

    <div id='menu'>
      <span id='intro_loading'> <b>Loading All Data. Please Wait</b></span>           
      <div class="toolbox"><a id="hideView" href="#">Hide Quick Query</a></div>
    </div>
    <div id="main">
  	  <div id="right">
  	    <div id="sidebar">
  	      <h3>Queries</h3>
  	      <ul>
          <? 
            $code_result = pg_query("SELECT id, name FROM my_query_store ORDER BY id ASC;");
            if (pg_num_rows($code_result) > 0) {
   	          for ($row = 0; $row < pg_num_rows($code_result); $row++) {
                print "<li id='".pg_fetch_result($code_result, $row, 0) ."'>". pg_fetch_result($code_result, $row, 1)."</li>";
              }
            }
          ?>
  	      </ul>                               
  	    </div>
  	    <div id="statbar">
  			  <h4>Online Players</h4>
  		    <ul id='online_players'></ul>                             
  	    </div>
        <div class='sidebar-holder'>
          <h4>Visualizer</h4>          
          <a href='#' id='visualize_link'>Switch to visualizer</a>          
          <div id='visualizer_controls'>
            <input type='submit' id="stop_visualization" value="Stop" />
            <input type='submit' id="start_visualization" value="Start" />

            <p>
              <b>Tic:</b>
              <span id='tic_value'>0</span>
            </p>            

            <p>
              <b>Tic Planets:</b>
              <span id='planets_tic'>0</span>
            </p>            

            <p>
              <b>Total Planets:</b>
              <span id="total_planets">0</span>            
            </p>
           
            <input type='submit' id="restart_visualization" value="Restart" />
            <input type='submit' id="exit_visualization" value="Exit" />
          </div>
        </div>
  	  </div>
  	  <div id="left">
  		  <div id="content">
          <div id='query_content'>
            <div class="control"> 
              <a class='execute'>Execute</a> 
              <input type='hidden' id='new' value='true' />
            </div>

            <h3>New Query</h3>
            <textarea id="activequery">SELECT username, balance, fuel_reserve FROM my_player;</textarea>
            Schemaverse Help: <a href="http://wiki.github.com/Abstrct/Schemaverse/how-to-play" target="_blank">How to play</a> | 
            <a href="http://wiki.github.com/Abstrct/Schemaverse/schemaverse-views" target="_blank">Views</a> | 
            <a href="http://wiki.github.com/Abstrct/Schemaverse/schemaverse-functions" target="_blank">Functions</a> |
            <a href="http://wiki.github.com/Abstrct/Schemaverse/schemaverse-tables" target="_blank">Tables</a> 
            <br />
            PostgreSQL Help: 
            <a href='http://www.postgresql.org/docs/9.0/static/sql-select.html' target="_blank">SELECT</a> |
            <a href='http://www.postgresql.org/docs/9.0/static/sql-update.html' target="_blank">UPDATE</a> |
            <a href='http://www.postgresql.org/docs/9.0/static/sql-insert.html' target="_blank">INSERT</a> |
            <a href='http://www.postgresql.org/docs/9.0/static/sql-delete.html' target="_blank">DELETE</a>
          </div>

          <div id="error" class='hide'>
            <div class="control"> <a href='#' id='hideError'>Close</a> </div>
              <h3>Error</h3>
            <p></p>
          </div>
          <div id="leftr"></div>          
          <div id='visualizer_content'>
            <div id='container'>              
              <div class="main"></div>
            </div>
          </div>
        </div>
  	  </div>
    </div>
    <div id="footer"> 
  		<a href='https://github.com/Abstrct/Schemaverse/wiki' target="_blank">Learn</a> |
  		<a href='http://groups.google.com/group/schemaverse/' target="_blank">Discuss</a> |
  		<a href='https://github.com/Abstrct/Schemaverse' target="_blank">Develop</a> |
  		<a href='http://twitter.com/#!/Schemaverse' target="_blank">Follow</a>
  	</div>

    <!-- Start of StatCounter Code -->
    <script type="text/javascript">
    var sc_project=6019573;
    var sc_invisible=1;
    var sc_security="cfa56a8e";
    </script>

    <script type="text/javascript"
    src="https://www.statcounter.com/counter/counter.js"></script><noscript><div
    class="statcounter"><a title="joomla analytics"
    href="http://www.statcounter.com/joomla/"
    target="_blank"><img class="statcounter"
    src="https://c.statcounter.com/6019573/0/cfa56a8e/1/"
    alt="joomla analytics" ></a></div></noscript>
    <!-- End of StatCounter Code -->

    <script type="text/javascript" src="/js/jquery.min.1.2.6.js"></script>
    <script type="text/javascript" src="/js/jquery.progressbar.min.js"></script>
    <script type="text/javascript" src="/js/tw.js"></script>
    <script type="text/javascript" src="/js/d3.v2.min.js"></script>
    <script type="text/javascript" src="/js/jquery.growl.js"></script>  
    <script type="text/javascript" src="/js/schemaverse.js"></script>
    <script type="text/javascript" src="/js/visualizer.js"></script>
    <script type="text/javascript" src="/js/main.js"></script>

  </body>
</html>

