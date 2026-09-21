(function() {

  window.startVisualization = function() {
    $('#tic_value').html("0");
    $('#tic_planets').html("0");
    $('#total_planets').html("0");
    visualizer.map.init();
    return schemaverse.getPlanets(function(planetData) {
      visualizer.map.setXY(planetData);
      visualizer.drawPlanets(planetData);
      return schemaverse.getPlayers(function() {
        return schemaverse.getTic(function() {
          schemaverse.active = true;
          return schemaverse.mapTic(380);
        });
      });
    });
  };

}).call(this);
