window.startVisualization = () ->
  $('#tic_value').html("0")
  $('#tic_planets').html("0")
  $('#total_planets').html("0")

  # Initialize the map
  visualizer.map.init()

  # Get the initial planet data
  schemaverse.getPlanets((planetData) ->

    # Set the map bounds and more map initialization stuff
    visualizer.map.setXY(planetData)

    # Draw all the planets for the first time
    visualizer.drawPlanets(planetData)

    # Get all the players
    schemaverse.getPlayers () ->            
      # Once the players have loaded, start going through the tics

      schemaverse.getTic () ->
        schemaverse.active = true  

        # The starting tic to start mapping
        schemaverse.mapTic(380)          
  )

  
