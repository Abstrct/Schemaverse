(function() {

  window.schemaverse = {
    players: [],
    previousShips: [],
    currentTic: -1,
    active: true,
    lastTic: 0,
    getTic: function(callback) {
      return $.getJSON('/visualizer/tic', function(data) {
        schemaverse.currentTic = data.currentTic.last_value;
        if (typeof callback === 'function') return callback();
      });
    },
    getPlayers: function(callback) {
      return d3.json("/visualizer/players.json", function(data) {
        var player, players, _i, _len;
        players = schemaverse.players;
        for (_i = 0, _len = players.length; _i < _len; _i++) {
          player = players[_i];
          if (player.conqueror_id) players[player.conqueror_id] = player;
        }
        if (typeof callback === 'function') return callback();
      });
    },
    getTicData: function(ticNumber, callback) {
      return d3.json('/visualizer/map_tic.json?tic=' + ticNumber, function(data) {
        var $planetText, pData, planetCount, planetData, playerColour, playerSymbol, shipData, _i, _len;
        $('#tic_value').html(ticNumber);
        if (data) {
          shipData = data.ships;
          planetData = data.planets;
          if (shipData && planetData) {
            shipData.map(function(ship) {
              ship.location_x = parseFloat(ship.location_x, 10);
              ship.location_y = parseFloat(ship.location_y, 10);
              ship.conqueror_id = parseInt(ship.conqueror_id, 10) || null;
              if (schemaverse.players[ship.conqueror_id]) {
                ship.conqueror_name = schemaverse.players[ship.conqueror_id].conqueror_name;
                ship.conqueror_color = schemaverse.players[ship.conqueror_id].rgb;
                ship.conqueror_symbol = '@';
                return schemaverse.players[ship.conqueror_id].count++;
              }
            });
            visualizer.drawShips(shipData);
            $('#planets_tic').html(planetData.length);
            for (_i = 0, _len = planetData.length; _i < _len; _i++) {
              pData = planetData[_i];
              $planetText = $('#planet-' + pData.referencing_id);
              if (pData.player_id_1 === pData.session_user_id) {
                playerSymbol = getSymbol(players[pData.session_user_id]);
                playerColour = getColor(players[pData.session_user_id]);
                $planetText.text(playerSymbol).attr('fill', 'red');
                planetCount = parseInt($('#total_planets').html());
                $('#total_planets').html(planetCount + 1);
              } else {
                $planetText.text("\u26aa").attr('fill', 'black');
                planetCount = parseInt($('#total_planets').html());
                $('#total_planets').html(planetCount - 1);
              }
            }
          } else {
            $('#planets_tic').html("0");
          }
          if (typeof callback === 'function') return callback();
        }
      });
    },
    mapTic: function(ticNumber) {
      schemaverse.lastTic = ticNumber;
      if (schemaverse.active) {
        return schemaverse.getTicData(ticNumber, function() {
          ticNumber++;
          if (ticNumber <= schemaverse.currentTic) {
            return schemaverse.mapTic(ticNumber);
          }
        });
      }
    },
    getPlanets: function(callback) {
      return d3.json("/visualizer/planets.json", function(data) {
        var planetData;
        planetData = data.planets;
        planetData.map(function(d) {
          d.location_x = parseFloat(d.location_x, 10);
          d.location_y = parseFloat(d.location_y, 10);
          return d.conqueror_id = null;
        });
        if (typeof callback === 'function') return callback(planetData);
      });
    }
  };

}).call(this);
