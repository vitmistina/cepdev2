({
  scriptsLoaded: function(component, event, helper) {
    console.log("load successfully");

    // active/call select2 plugin function after load jQuery and select2 plugin successfully
    $(".select2Class").select2({
      placeholder: ""
    });
  },
  next: function(cmp, e, h) {
    var s = cmp.get("v.currentStep");
    var product = cmp.get("v.NNCalculation.Product__c");
    var strategy = cmp.get("v.NNCalculation.Investment_Strategy__c");
    if (s == 9) {
      return;
    }
    if (s == 1) {
      if (!cmp.find("basicInfoSection").validate()) return;
    }
    if (s == 2) {
      console.log("jsem ve stepu 2");
      var childCmp = cmp.find("firstInsuredPersonForm");
      var auraMethodResult = childCmp.validateForm();
      console.log("auraMethodResult " + auraMethodResult);
      if (!auraMethodResult) {
        console.log("nevalidni");
        return;
      }
      console.log("validni snad");
      h.getComponents(cmp, "0");
    }
    if (s == 3 || s == 5) {
      h.saveComponents(cmp, s);
    }
    if (s == 4) {
      var childCmp = cmp.find("secondInsuredPersonForm");
      var auraMethodResult = childCmp.validateForm();
      if (!auraMethodResult) {
        console.log("nevalidni");
        return;
      }
      h.getComponents(cmp, "1");
    }
    if (s == 8) {
      h.getSelectedRiders(cmp);
    }
    const child = cmp.get("v.NNCalculation.Has_Children__c");
    const secondInsured = cmp.get("v.NNCalculation.Has_Second_Insured__c");
    if (!child || !secondInsured) {
      if (!child && s == 5) {
        s += 1;
      }
      if (!secondInsured && s == 3) {
        s += 2;
        if (!child) {
          s += 1;
        }
      }
    }
    console.log("esko pres smartem " + s);
    if (s == 6 && product != "UM2S") {
      s += 1;
    }
    if (s == 7) {
      h.getIllustrationData(cmp);
    }
    cmp.set("v.currentStep", s + 1);
    if (s > 0) {
      if (s != 4) {
        h.createCalculation(cmp);
      }
      console.log("esko " + s);
      if (s == 2) {
        console.log("volamFirstInsured " + s);
        h.createFirstInsured(cmp, "First Insured");
        var isPolicyHolder = cmp.get("v.isNotFirst");
        console.log("isPolicyHolder" + isPolicyHolder);
        if (isPolicyHolder) {
          h.createPolicyHolder(cmp, "Policy Holder");
        }
      }
      if (s == 4) {
        console.log("volamSecondInsured " + s);
        h.createSecondInsured(cmp, "Second Insurance");
      }
      if (
        s == 7 &&
        product == "UM2S" &&
        strategy != null &&
        strategy == "OWN"
      ) {
        console.log("ukladam fondy " + s);
        h.upsertFunds(cmp);
      }
      if (s == 7 && child) {
        console.log("volan saveChildren " + s);
        h.upsertChildren(cmp);
      }
    }
  },
  prev: function(cmp, e, h) {
    var s = cmp.get("v.currentStep");
    var product = cmp.get("v.NNCalculation.Product__c");
    if (s == 1) {
      return;
    }
    const child = cmp.get("v.NNCalculation.Has_Children__c");
    const secondInsured = cmp.get("v.NNCalculation.Has_Second_Insured__c");

    console.log("child " + child + " secondInsured " + secondInsured);
    if (!child || !secondInsured) {
      console.log("jsem in " + s);
      if (!secondInsured && s == 6) {
        s -= 2;
      }
      if (!child && s == 7) {
        s -= 1;
        console.log("nechild " + s);
        if (!secondInsured) {
          s -= 2;
        }
      }
      if (s == 8 && product != "UM2S") {
        s -= 1;
      }
    }
    cmp.set("v.currentStep", --s);
  },
  changeStep: function(cmp, e, h) {
    var s = cmp.get("v.currentStep");

    h.visible(cmp, "step1", s == 1);
    h.visible(cmp, "step2", s == 2);
    h.visible(cmp, "step3", s == 3);
    h.visible(cmp, "step4", s == 4);
    h.visible(cmp, "step5", s == 5);
    h.visible(cmp, "step6", s == 6);
    h.visible(cmp, "step7", s == 7);
    h.visible(cmp, "step8", s == 8);
    h.visible(cmp, "step9", s == 9);

    cmp.find("next").set("v.disabled", s == 9);
    cmp.find("prev").set("v.disabled", s == 1);
  },

  isChildrenChanged: function(cmp, e, h) {},

  isSecondInsuredChanged: function(cmp, e, h) {
    var issecond = cmp.get("v.isSecondInsured");
    console.log("isecond " + issecond);
  },

  isNotFirstChanged: function(cmp, e, h) {
    h.visible(
      cmp,
      "insuredSection",
      cmp.get("v.NNCalculation.Insurer_Is_Not_First_Insured__c")
    );
  },

  doInit: function(cmp, e, h) {
    var recordId = "";
    var accId = "";
    var parts = window.location.href.replace(
      /[?&]+([^=&]+)=([^&]*)/gi,
      function(m, key, value) {
        console.log(key + ":" + value);
        if (key == "calcId") {
          cmp.set("v.recordId", value);
          recordId = value;
        } else if (key == "accId") {
          cmp.set("v.accId", value);
          accId = value;
        }
      }
    );
    cmp.set("v.Spinner", true);
    h.callAction(cmp, "c.getPaymentFrequencies", function(data) {
      cmp.set("v.paymentFrequencyOptions", data);
    });

    h.callAction(cmp, "c.getProducts", function(data) {
      cmp.set("v.productOptions", data);
    });
    h.callAction(cmp, "c.getSports", function(data) {
      cmp.set("v.sportOptions", data);
    });
    h.callAction(cmp, "c.getEmploymentTypes", function(data) {
      cmp.set("v.employmentTypes", data);
    });
    h.callAction(cmp, "c.getInvestmentVariants", function(data) {
      cmp.set("v.investmentVariants", data);
    });
    h.callAction(cmp, "c.getInvestmentStrategies", function(data) {
      cmp.set("v.investmentStrategies", data);
    });
    h.callAction(cmp, "c.getInvestmentFrequencies", function(data) {
      cmp.set("v.investmentFrequencies", data);
    });
    h.callAction(cmp, "c.getInsuranceVariants", function(data) {
      cmp.set("v.insuranceVariants", data);
    });
    h.callAction(cmp, "c.getSpecialGroups", function(data) {
      cmp.set("v.specialGroups", data);
    });
    var action = cmp.get("c.getVPMSResponse");
    action.setParams({
      calcId: recordId,
      accId: accId
    });
    action.setCallback(this, function(response) {
      console.log("response " + response);

      if (response.getState() === "SUCCESS") {
        var parsed = JSON.parse(response.getReturnValue());

        console.log("Got JSON", parsed);
        cmp.set("v.Spinner", false);
        cmp.set("v.NNCalculation.Total_Premium__c", parsed.totalPremium);
        cmp.set("v.NNCalculation.Special_Group__c", parsed.specialGroup);
        cmp.set(
          "v.NNCalculation.DateSign__c",
          $A.localizationService.formatDate(
            parsed.expectedSignatureDate,
            "YYYY-MM-DD"
          )
        );
        cmp.set(
          "v.NNCalculation.DateStart__c",
          $A.localizationService.formatDate(parsed.firstTop, "YYYY-MM-DD")
        );
        cmp.set("v.NNCalculation.PaymentFrequency__c", parsed.paymentFrequency);
        cmp.set("v.NNCalculation.Product__c", parsed.productCode);
        cmp.set("v.firstInsured.EmploymentTypeNew__c", parsed.employmentType);
        cmp.set("v.secondInsured.EmploymentTypeNew__c", parsed.employmentType);
        cmp.set("v.policyHolder.EmploymentTypeNew__c", parsed.employmentType);
        cmp.set("v.NNCalculation.VPMS_Request__c", parsed.vpmsRequest);
        cmp.set(
          "v.NNCalculation.VPMS_Calculation_Request__c",
          parsed.vpmsCalcRequest
        );
        cmp.set("v.NNCalculation.Insurance_Variant__c", parsed.variant);
        cmp.set("v.NNCalculation.CalculationName__c", "Moje nová kalkulace");
        cmp.set(
          "v.selectedProduct",
          h.getSelectedProduct(cmp, parsed.productCode)
        );
      } else if (response.getState() == "ERROR") {
        h.handleError(cmp, response.getError());
      }
    });

    $A.enqueueAction(action);
  },

  saveData: function(cmp) {
    var action = cmp.get("c.saveCalculation");
    //action.setParams( );

    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        console.log("Save calculation response", response.getReturnValue());
      } else if (state === "ERROR") {
        h.handleError(cmp, response.getError());
      }
    });

    $A.enqueueAction(action);
  },

  loadData: function(cmp) {
    var loadingData = cmp.get("c.getCalculation");

    action.setCallback(this, function(response) {
      var state = response.getState();

      if (state === "SUCCESS") {
        alert("From server: " + response.getReturnValue());
      } else if (state === "ERROR") {
        h.handleError(cmp, response.getError());
      }
    });

    $A.enqueueAction(action);
  },
  handleGetNetIncome: function(component, event, helper) {
    console.log("handle event");
    var getNetIncome = event.getParam("grossIncome");
    console.log("vse" + getNetIncome);
    helper.getNetIncome(component, getNetIncome);
  },

  recalculate: function(component, event, helper) {
    var s = component.get("v.currentStep");
    component.set("v.recalculateRequired", false);
    console.log("jdu dal");
    var indexPerson = "0";
    if (s == 5) {
      indexPerson = "1";
    }
    helper.recalculateRiders(component, indexPerson);
  },

  showSpinner: function(component, event, helper) {
    // make Spinner attribute true for display loading spinner
    component.set("v.Spinner", true);
  },
  hideSpinner: function(component, event, helper) {
    // make Spinner attribute to false for hide loading spinner
    component.set("v.Spinner", false);
  },

  openPDF: function(component) {
    var calcId = component.get("v.NNCalculation.Id");
    window.open(
      "https://bttest002-nn-sales.cs85.force.com/testCalc/apex/IllustrationShowGeneratedPDF?applicationId=" +
        calcId,
      "_blank"
    );
    return false;
  },

  showOrHideRecalculate: function(component) {
    component.set("v.recalculateRequired", true);
  },

  handleProductChange: function(component, event, helper) {
    component.set("v.recalculateRequired", true);
    if (event.getParam("fieldName") === "Product") {
      component.set(
        "v.selectedProduct",
        helper.getSelectedProduct(component, event.getSource().get("v.value"))
      );
    }
  },

  showOrHideRecalculateFunds: function(component) {
    var fundSharing = component.find("fundSharing");
    var remainingFunds = 100;
    for (var i = 0; i < fundSharing.length; i++) {
      console.log("fundsSharing " + fundSharing[i].get("v.value"));
      var currentValue = fundSharing[i].get("v.value");
      if (currentValue != undefined) {
        remainingFunds -= currentValue;
      }
      console.log("remainingFunds " + remainingFunds);
    }
    component.set("v.remainingFunds", remainingFunds);
    component.set("v.recalculateRequired", true);
  },

  recalculateFunds: function(component, event, helper) {
    console.log("fondy");
    helper.recalculateFunds(component);
  },

  hasChildren: function(component, event, helper) {
    console.log("menim deti");
    var action = component.get("c.initChildren");
    var children = component.get("v.children");
    console.log("menim deti2");
    action.setParams({
      children: children
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        console.log("Save calculation response", response.getReturnValue());
        component.set("v.children", response.getReturnValue());
      } else if (state === "ERROR") {
        alert(response.getError());
        h.handleError(cmp, response.getError());
      }
    });

    $A.enqueueAction(action);
  },

  handleChange: function(cmp, event) {
    var changeValue = event.getParam("value");
    alert(changeValue);
  }
});
