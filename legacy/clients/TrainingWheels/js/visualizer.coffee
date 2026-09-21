$ ->
  $('#visualize_link').click (e) ->
    $('#query_content').slideToggle()
    $('#visualizer_content').slideToggle()
    startVisualization()
    $(@).hide()
    $('#visualizer_controls').show()
    $('#start_visualization').hide()
    $('#stop_visualization').show()
    e.preventDefault()

  $('#start_visualization').click (e) ->
    $(@).hide()
    $('#stop_visualization').show()
    
    schemaverse.active = true    
    schemaverse.mapTic(schemaverse.lastTic)

  $('#stop_visualization').click (e) ->    
    $(@).hide()
    $('#start_visualization').show()
    
    schemaverse.active = false        

  $('#restart_visualization').click (e) ->
    schemaverse.active = false    

    $('#start_visualization').hide()        
    $('#stop_visualization').show()
    startVisualization()

  $('#exit_visualization').click (e) ->
    schemaverse.active = false

    $('#query_content').slideToggle()
    $('#visualizer_content').slideToggle() 
    $('#visualize_link').show()
    $('#visualizer_controls').hide()


window.visualizer =
  color: d3.scale.category20()
  vis: null

  symbol: (i) ->
    symbols = ["\u2640", "\u2641", "\u2642", "\u2643", "\u2644", "\u2645", "\u2646", "\u2647", "\u2648", "\u2649", "\u2642", "\u264A", "\u264B", "\u264C", "\u264D", "\u264E", "\u264F", "\u2630", "\u2631", "\u2632", "\u2633", "\u2634", "\u2635", "\u2636", "\u2637", "\u2638", "\u2639", "\u2632", "\u263A", "\u263B", "\u263C", "\u263D", "\u263E", "\u263F", "\u2640", "\u2641", "\u2642", "\u2643", "\u2644", "\u2645", "\u2646", "\u2647", "\u2648", "\u2649", "\u2642", "\u264A", "\u264B", "\u264C", "\u264D", "\u264E", "\u264F", "\u2650", "\u2651", "\u2652", "\u2653", "\u2654", "\u2655", "\u2656", "\u2657", "\u2658", "\u2659", "\u2652", "\u265A", "\u265B", "\u265C", "\u265D", "\u265E", "\u265F"]
    length = symbols.length
    symbols[i % length]

  getSymbol: (player) ->
    if player.conqueror_id is null
      "\u26aa"      
    else if (player.conqueror_symbol) 
      player.conqueror_symbol
    else
      visualizer.symbol(player.conqueror_id)

  getColor: (player) ->
    if player.conqueror_id is null
      '#000'
    else if player.conqueror_color
      '#' + player.conqueror_color
    else
      visualizer.color(player.conqueror_id);

  drawPlanets: (planetData) ->
    map = visualizer.map
    planets = visualizer.vis.selectAll("text.planet").data planetData, (d) ->
      d.id

    enter = planets.enter().append("text")
      .attr('id', (d) ->
         'planet-' + d.id
      ).attr('dx', -5).attr('dy', 5)

    if (map.x && map.y) 
      enter.attr "transform", (p) ->
        "translate(" + map.x(p.location_x) + "," + map.y(p.location_y) + ")"

      planets.attr("class", (d) ->
        'dot planet'
      ).attr("fill", visualizer.getColor).text(visualizer.getSymbol)

  drawShips: (shipData) ->

    # Remove all the previous ships from the map
    for prevShipArr in schemaverse.previousShips
      for prevShip in prevShipArr
        $(prevShip).remove()
    
    # Select all the ship elements on the page
    ships = visualizer.vis.selectAll("text.planet").data shipData, (ship) ->
      ship.id

    enter = ships.enter().append("text")
      .attr('id', (ship) ->
        'planet-' + ship.id
      ).attr('dx', -5).attr('dy', 5)

    if visualizer.map.x && visualizer.map.y
      enter.attr("transform", (ship) ->
        "translate(" + visualizer.map.x(ship.location_x) + "," + visualizer.map.y(ship.location_y) + ")"
      )

    ships.attr("fill", 'green').text('@')
    schemaverse.previousShips.push(ships)

  map:    
    init: () ->
      map = visualizer.map
      map.width = 700
      map.height = 700
      map.margin = 1   

      $('#container .main svg').remove() 
      
      visualizer.vis = d3.select("#container .main")
        .append("svg")
        .attr("width", map.width + map.margin * 2)
        .attr("height", map.height + map.margin * 2)
        .attr("class", "map")
        .append("g")
        .attr("transform", "translate(" + map.margin + "," + map.margin + ")")

      visualizer.vis.append("rect").attr("width", map.width).attr("height", map.height)

    setXY: (planetData) ->
      map = visualizer.map
      vis = visualizer.vis
      map.extentX = d3.extent planetData, (eX) ->
        eX.location_x

      map.extentY = d3.extent planetData, (eY) ->
        eY.location_y

      map.x = d3.scale.linear()
        .range([0, map.width])
        .domain(map.extentX)
        .clamp(true)
        .nice()

      map.y = d3.scale.linear()
        .range([0, map.height])
        .domain(map.extentY)
        .clamp(true)
        .nice()

      xrule = vis.selectAll("g.x")
        .data(map.x.ticks(10))
        .enter().append("g")
        .attr("class", "x")

      xrule.append("line")
        .attr("x1", map.x)
        .attr("x2", map.x)
        .attr("y1", 0)
        .attr("y2", map.height)

      yrule = vis.selectAll("g.y")
        .data(map.y.ticks(10))
        .enter().append("g")
        .attr("class", "y")

      yrule.append("line")
        .attr("x1", 0)
        .attr("x2", map.width)
        .attr("y1", map.y)
        .attr("y2", map.y)