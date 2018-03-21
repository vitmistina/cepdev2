({
  validate: function(component, event) {
    var inputCalcName = component.find("calculationName");
    var allValid = inputCalcName.get("v.validity").valid;
    if (!allValid) {
      inputCalcName.showHelpMessageIfInvalid();
    }
    return allValid;
  }
});
