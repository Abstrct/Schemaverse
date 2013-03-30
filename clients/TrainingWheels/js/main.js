(function() {

  window.startVisualization = function() {
    visualizer.map.init();
    return schemaverse.getPlanets(function(planetData) {
      visualizer.map.setXY(planetData);
      visualizer.drawPlanets(planetData);
      return schemaverse.getPlayers(function() {
        return schemaverse.getTic(function() {
          return schemaverse.mapTic(380);
        });
      });
    });
  };

}).call(this);
