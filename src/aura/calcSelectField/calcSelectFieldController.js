({
  fireChangeEvent: function(component, event) {
    component
      .getEvent("calcProductChangeEvent")
      .setParams({ fieldName: event.getSource().get("v.name") })
      .fire();
  }
});
