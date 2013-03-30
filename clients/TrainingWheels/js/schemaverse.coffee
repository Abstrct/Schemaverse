window.schemaverse = {
  players: []
  previousShips: []
  currentTic: -1
  active: true

  getTic: (callback) ->
    $.getJSON '/visualizer/tic', (data) ->
      schemaverse.currentTic = data.currentTic.last_value      

      if typeof callback is 'function'
        callback()

  getPlayers: (callback) ->
    d3.json "/visualizer/players.json", (data) ->
      players = schemaverse.players
      for player in players
        if (player.conqueror_id)
          players[player.conqueror_id] = player

      if typeof callback is 'function'
        callback()

  getTicData: (ticNumber, callback) ->
    d3.json '/visualizer/map_tic.json?tic=' + ticNumber, (data) ->      
      $('#tic_value').html(ticNumber)      
      if data
        shipData = data.ships
        planetData = data.planets

        if (shipData && planetData)
          shipData.map (ship) ->
            ship.location_x = parseFloat(ship.location_x, 10)
            ship.location_y = parseFloat(ship.location_y, 10)
            ship.conqueror_id = parseInt(ship.conqueror_id, 10) || null
            if (schemaverse.players[ship.conqueror_id]) 
              ship.conqueror_name = schemaverse.players[ship.conqueror_id].conqueror_name
              ship.conqueror_color = schemaverse.players[ship.conqueror_id].rgb
              ship.conqueror_symbol = '@'
              schemaverse.players[ship.conqueror_id].count++
          
          # Draw the ships on the map
          visualizer.drawShips(shipData)

          # Update the planets conquered this tic
          $('#planets_tic').html(planetData.length);

          for pData in planetData
            $planetText = $('#planet-' + pData.referencing_id)
            if pData.player_id_1 is "11247"
              $planetText.text('R').attr('fill', 'red')
              planetCount = parseInt($('#total_planets').html())
              $('#total_planets').html(planetCount + 1)              
            else 
              $planetText.text("\u26aa").attr('fill', 'black')
              planetCount = parseInt($('#total_planets').html())
              $('#total_planets').html(planetCount - 1)

        if typeof callback is 'function'
          callback()

  mapTic: (ticNumber) ->
    if schemaverse.active
      schemaverse.getTicData ticNumber, () ->
        ticNumber++      
        if ticNumber <= schemaverse.currentTic
          schemaverse.mapTic(ticNumber)

  getPlanets: (callback) ->
    d3.json "/visualizer/planets.json", (data) ->
      planetData = data.planets
      planetData.map (d) ->
        d.location_x = parseFloat(d.location_x, 10)
        d.location_y = parseFloat(d.location_y, 10)
        d.conqueror_id = null

      if typeof callback is 'function'
        callback(planetData)
}