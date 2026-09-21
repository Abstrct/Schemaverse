(function() {

  $(function() {
    $('#visualize_link').click(function(e) {
      $('#query_content').slideToggle();
      $('#visualizer_content').slideToggle();
      startVisualization();
      $(this).hide();
      $('#visualizer_controls').show();
      $('#start_visualization').hide();
      $('#stop_visualization').show();
      return e.preventDefault();
    });
    $('#start_visualization').click(function(e) {
      $(this).hide();
      $('#stop_visualization').show();
      schemaverse.active = true;
      return schemaverse.mapTic(schemaverse.lastTic);
    });
    $('#stop_visualization').click(function(e) {
      $(this).hide();
      $('#start_visualization').show();
      return schemaverse.active = false;
    });
    $('#restart_visualization').click(function(e) {
      schemaverse.active = false;
      $('#start_visualization').hide();
      $('#stop_visualization').show();
      return startVisualization();
    });
    return $('#exit_visualization').click(function(e) {
      schemaverse.active = false;
      $('#query_content').slideToggle();
      $('#visualizer_content').slideToggle();
      $('#visualize_link').show();
      return $('#visualizer_controls').hide();
    });
  });

  window.visualizer = {
    color: d3.scale.category20(),
    vis: null,
    symbol: function(i) {
      var length, symbols;
      symbols = ["\u2640", "\u2641", "\u2642", "\u2643", "\u2644", "\u2645", "\u2646", "\u2647", "\u2648", "\u2649", "\u2642", "\u264A", "\u264B", "\u264C", "\u264D", "\u264E", "\u264F", "\u2630", "\u2631", "\u2632", "\u2633", "\u2634", "\u2635", "\u2636", "\u2637", "\u2638", "\u2639", "\u2632", "\u263A", "\u263B", "\u263C", "\u263D", "\u263E", "\u263F", "\u2640", "\u2641", "\u2642", "\u2643", "\u2644", "\u2645", "\u2646", "\u2647", "\u2648", "\u2649", "\u2642", "\u264A", "\u264B", "\u264C", "\u264D", "\u264E", "\u264F", "\u2650", "\u2651", "\u2652", "\u2653", "\u2654", "\u2655", "\u2656", "\u2657", "\u2658", "\u2659", "\u2652", "\u265A", "\u265B", "\u265C", "\u265D", "\u265E", "\u265F"];
      length = symbols.length;
      return symbols[i % length];
    },
    getSymbol: function(player) {
      if (player.conqueror_id === null) {
        return "\u26aa";
      } else if (player.conqueror_symbol) {
        return player.conqueror_symbol;
      } else {
        return visualizer.symbol(player.conqueror_id);
      }
    },
    getColor: function(player) {
      if (player.conqueror_id === null) {
        return '#000';
      } else if (player.conqueror_color) {
        return '#' + player.conqueror_color;
      } else {
        return visualizer.color(player.conqueror_id);
      }
    },
    drawPlanets: function(planetData) {
      var enter, map, planets;
      map = visualizer.map;
      planets = visualizer.vis.selectAll("text.planet").data(planetData, function(d) {
        return d.id;
      });
      enter = planets.enter().append("text").attr('id', function(d) {
        return 'planet-' + d.id;
      }).attr('dx', -5).attr('dy', 5);
      if (map.x && map.y) {
        enter.attr("transform", function(p) {
          return "translate(" + map.x(p.location_x) + "," + map.y(p.location_y) + ")";
        });
        return planets.attr("class", function(d) {
          return 'dot planet';
        }).attr("fill", visualizer.getColor).text(visualizer.getSymbol);
      }
    },
    drawShips: function(shipData) {
      var enter, prevShip, prevShipArr, ships, _i, _j, _len, _len2, _ref;
      _ref = schemaverse.previousShips;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        prevShipArr = _ref[_i];
        for (_j = 0, _len2 = prevShipArr.length; _j < _len2; _j++) {
          prevShip = prevShipArr[_j];
          $(prevShip).remove();
        }
      }
      ships = visualizer.vis.selectAll("text.planet").data(shipData, function(ship) {
        return ship.id;
      });
      enter = ships.enter().append("text").attr('id', function(ship) {
        return 'planet-' + ship.id;
      }).attr('dx', -5).attr('dy', 5);
      if (visualizer.map.x && visualizer.map.y) {
        enter.attr("transform", function(ship) {
          return "translate(" + visualizer.map.x(ship.location_x) + "," + visualizer.map.y(ship.location_y) + ")";
        });
      }
      ships.attr("fill", 'green').text('@');
      return schemaverse.previousShips.push(ships);
    },
    map: {
      init: function() {
        var map;
        map = visualizer.map;
        map.width = 700;
        map.height = 700;
        map.margin = 1;
        $('#container .main svg').remove();
        visualizer.vis = d3.select("#container .main").append("svg").attr("width", map.width + map.margin * 2).attr("height", map.height + map.margin * 2).attr("class", "map").append("g").attr("transform", "translate(" + map.margin + "," + map.margin + ")");
        return visualizer.vis.append("rect").attr("width", map.width).attr("height", map.height);
      },
      setXY: function(planetData) {
        var map, vis, xrule, yrule;
        map = visualizer.map;
        vis = visualizer.vis;
        map.extentX = d3.extent(planetData, function(eX) {
          return eX.location_x;
        });
        map.extentY = d3.extent(planetData, function(eY) {
          return eY.location_y;
        });
        map.x = d3.scale.linear().range([0, map.width]).domain(map.extentX).clamp(true).nice();
        map.y = d3.scale.linear().range([0, map.height]).domain(map.extentY).clamp(true).nice();
        xrule = vis.selectAll("g.x").data(map.x.ticks(10)).enter().append("g").attr("class", "x");
        xrule.append("line").attr("x1", map.x).attr("x2", map.x).attr("y1", 0).attr("y2", map.height);
        yrule = vis.selectAll("g.y").data(map.y.ticks(10)).enter().append("g").attr("class", "y");
        return yrule.append("line").attr("x1", 0).attr("x2", map.width).attr("y1", map.y).attr("y2", map.y);
      }
    }
  };

}).call(this);
