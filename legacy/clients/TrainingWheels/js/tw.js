$(document).ready(function() {

	$("#hideView").click(function() {
		$("#content").toggleClass("hide");
	
		if ($(this).html() == 'Hide Quick Query') 
		{
			$(this).html('Show Quick Query');
		} else {
			$(this).html('Hide Quick Query');
		}

	});
		
	$("#hideError").click(function() {
		$("#error").toggleClass("hide");
	});

	 $(".execute").click(execute_click);
	 $(".saveQuery").click(save_click);
	 $(".deleteQuery").click(delete_click);
	 $('#sidebar li').click(load_click);



});

function get_stats() {
	var command = 'select  (select last_value FROM tic_seq), my_player.balance, my_player.fuel_reserve, player_round_stats.ships_built - player_round_stats.ships_lost, player_round_stats.planets_conquered - player_round_stats.planets_lost FROM player_round_stats, my_player WHERE player_round_stats.player_id=my_player.id and player_round_stats.round_id = (select last_value from round_seq);';
	//var command = 'select current_stats.current_tic, my_player.balance, my_player.fuel_reserve, (SELECT COUNT(id) FROM my_ships),(SELECT COUNT(id) from planets WHERE conqueror_id=GET_PLAYER_ID(SESSION_USER)),current_stats.total_ships,current_stats.total_players, (SELECT count(id) from planets WHERE conqueror_id IS NOT NULL), 43280 FROM current_stats, my_player;';
	$.getJSON('command.php?',{'cmd':'execute', 'query':command}, function(data) {
		if($('#intro_loading').length){
			$('#intro_loading').remove();
			$('#menu').prepend('Current Tic:<span id="stat_tic"> </span> | 	Balance:<span id="stat_balance"></span> | Fuel:<span id="stat_fuel_reserve"></span> | 	Ships:<span id="stat_ships"></span> | Conquered Planets:<span id="stat_conquered_planets"></span> ');			
		}
		$('#stat_tic').html(data.rows[0].data[0]);
		$('#stat_balance').html('$'+data.rows[0].data[1]);
		$('#stat_fuel_reserve').html(data.rows[0].data[2]);
		$('#stat_ships').html(data.rows[0].data[3]);
		$('#stat_conquered_planets').html(data.rows[0].data[4]);
		//$('#stat_overall_ships').html(data.rows[0].data[5]);
		//$('#stat_overall_players').html(data.rows[0].data[6]);
		//$('#stat_overall_planets').html(data.rows[0].data[8]);
		//$('#stat_overall_conquered_planets').html(data.rows[0].data[7]);
		
	});
	command = "SELECT * FROM online_players WHERE username !='schemaverse';";
	$.getJSON('command.php?',{'cmd':'execute', 'query':command}, function(data) {
		$('#online_players').empty();
				for (i=0; i < data.rows.length; i++){
								  $('#online_players').append('<li>' + data.rows[i].data[1]+'</li>');
		}
	});

	
}

function close_click() {
	$(this).parents('.results').remove();
}

function delete_click() {
		var qid = $(this).parents(".results").find('#qid').val();
		var rid =  $(this).parents('.results').attr('id');
	
		$.getJSON('command.php?',{'qid':qid, 'cmd':'delete'}, function(data) {
			$('#sidebar').find('#'+qid).remove();
			$('#'+rid).remove();
	});		
}

function execute_click() {
	var command = $(this).parents().find("#activequery").val();
	var newwindow = $(this).siblings('input #new').val();
	if (newwindow != 'true'){
		var rid =  $(this).parents('.results').attr('id');
	}
	$.getJSON('command.php?',{'query':command, 'cmd':'execute'}, function(data) {
		var updated = '';
		var table = '';
		var error = '';
		var pb = new Array();
		if (data.error != null){
			error = 'The following error occured during execution:<br>' + data.error[1] + '<br><br> The original query was:<br>'+data.error[2];
			$('#error').removeClass('hide');
			$('#error p').html(error);			
		}
		if (data.num_rows > 0 || data.affected_rows == 0) {
			table = '<table><thead><tr>';

			for (i=0; i < data.column.length; i++){
				table = table + '<th>'+data.column[i].name+'</th>';
			}	
			table = table + '</tr></thead><tbody>';

			if (data.num_rows > 0){
				for (i=0; i < data.rows.length; i++){
					table = table + '<tr>';
					for (x=0; x < data.column.length; x++){
						if (data.column[x].name.substring(0,3) == 'pb_') {
							table = table + '<td><span class="progressBar" id="'+ data.rid+ '_' + i + '_' + x + '">'+data.rows[i].data[x]+'</span></td>';
							pb.push(data.rid+ '_' + i + '_' + x);
						} else {
							table = table + '<td>'+data.rows[i].data[x]+'</td>';
						}
					}
					table = table + '</tr>';
				}
			}
			table = table + '</tbody></table>';
		} else if (data.affected_rows != null) {
			updated = data.affected_rows + ' row(s) affected';
		}

		if (newwindow == 'true') {
			newQuery(data.rid);
			$('#' + data.rid + ' p').html(updated + table);			
			$('#' + data.rid).find('#activequery').val(command);			
		} else {
			$('#' + rid + ' p').html(updated + table);
			$('#' + rid).find('#activequery').val(command);
		}
		while (pb.length > 0){
			$('#'+pb.pop()).progressBar();	
		}
	});
};

function load_click() {
		qid = $(this).attr('id');
			$.getJSON('command.php?',{'qid':qid, 'cmd':'load'}, function(data) {
					var error = '';
					if (data.error != null){
							error = 'The following error occured during execution:<br>' + data.error[1] + '<br><br> The original query was:<br>'+data.error[2];
			$('#error').removeClass('hide');
			$('#error p').html(error);			
					}
		if ($(".results").find('#qid[value="'+qid+'"]').length)
		{
			$(".results").find('#qid[value="'+qid+'"]').parents('.results').find('#queryname').val(data.rows[0].data[1]); 			
			$(".results").find('#qid[value="'+qid+'"]').parents('.results').find('#activequery').val(data.rows[0].data[2]);							
		} else {
			newQuery(data.rid);
			$('#' + data.rid).find('#qid').val(data.rows[0].data[0]); 			
			$('#' + data.rid).find('#queryname').val(data.rows[0].data[1]); 			
			$('#' + data.rid).find('#activequery').val(data.rows[0].data[2]);			
		}
			});

	};

function save_click() {
		command = $(this).parents().find("#activequery").val();
		queryname = $(this).parents().find("#queryname").val();
	newwindow = $(this).siblings('input #new').val();
	qid = $(this).parents().find("#qid").val();

	if (newwindow != 'true'){
		rid =  $(this).parents('.results').attr('id');
	}
	
	if (qid > 0 ) {
		cmd = 'save_old';
	} else {
		cmd = 'save_new';
	}
	
			$.getJSON('command.php?',{'qid':qid, 'label':queryname, 'query':command, 'cmd':cmd}, function(data) {
					var updated = '';
					var error = '';
					if (data.error != null){
							error = 'The following error occured during execution:<br>' + data.error[1] + '<br><br> The original query was:<br>'+data.error[2];
			$('#error').removeClass('hide');
			$('#error p').html(error);			
					}
					if (data.num_rows > 0 || data.affected_rows == 0) {
			$('#' + rid).find('#qid').val(data.rows[0].data[0]);
			$('#sidebar ul').append('<li id="'+data.rows[0].data[0]+'">'+queryname+'</li>');
			$('#sidebar li').click(load_click);

		}

		if (cmd == 'save_old') {
			 $('#sidebar').find('#' + qid).html(queryname);					
		}

		if (data.affected_rows != null) {
							updated = 'Query Saved';
					}

					//$('#' + rid + ' p').append(updated);

			});

	};

function newQuery(id) { 
	$('#leftr').prepend(' <div id="' + id + '" class="results"><div class="control"><a class="execute">Execute</a> <a  class="closeResult">Close</a> <a  class="saveQuery">Save</a> <a class="deleteQuery">Delete</a></div><input type="hidden" id="qid" value="" /><input type="text" id="queryname" value="New Query Name" /><textarea id="activequery"></textarea><p><span></span></p></div>'); 
	$(".execute").click(execute_click);
	$(".saveQuery").click(save_click);
	$(".deleteQuery").click(delete_click);
	$(".closeResult").click(close_click);
	
}
get_stats();
setInterval( "get_stats()", 120000); 
