({
    show: function(cmp, name) {
        $A.util.removeClass(cmp.find(name), 'slds-hide');
    },

    hide: function(cmp, name) {
        $A.util.addClass(cmp.find(name), 'slds-hide');
    },

    visible: function(cmp, name, c) {
        if (c) {
            this.show(cmp, name);
        } else {
            this.hide(cmp, name);
        }
    },
    
    handleError: function(cmp, errors) {
        if (errors) {
            if (errors[0] && errors[0].message) {
                console.log("Error message: " + 
                            errors[0].message);
            }
        } else {
            console.log("Unknown error");
        }
    },
    callAction: function(cmp, actionName, successCallback, failureCallback ) {
        var action = cmp.get(actionName);
        
        action.setCallback(this, function(response) {
            if (cmp.isValid() && response.getState() === 'SUCCESS') {
                if (successCallback) {
                    successCallback(response.getReturnValue());
                }
            } else if (response.getState() == 'ERROR') {
                if (failureCallback) {
                    failureCallback(response.getError(), response.getState());
                } else {
                    this.logActionErrors(cmp, response.getError());
                }
            }
        });
        
        $A.enqueueAction( action );
        
    },
    
    createCalculation: function(cmp) {
        var calculation = cmp.get("v.NNCalculation");
        
        this.upsertCalculation(cmp, calculation, function(a) {
            var returnValue = a.getReturnValue();
            
            returnValue.DateSign__c = $A.localizationService.formatDate(returnValue.DateSign__c, "YYYY-MM-DD");
            returnValue.DateStart__c = $A.localizationService.formatDate(returnValue.DateStart__c, "YYYY-MM-DD");
            
            cmp.set("v.NNCalculation", returnValue);
        });
    },
    
    upsertCalculation : function(cmp, calculation, callback) {
        var action = cmp.get('c.saveCalculation');
        
        action.setParams({
            'calculation': calculation
        });
        
        if (callback) {
            action.setCallback(this, callback);
        }

        $A.enqueueAction(action);
    },

    createFirstInsured: function(cmp, accountType) {
        var selectedSkills = $('[id$=sportFirstInsured]').select2("val");
        cmp.set("v.firstInsured.Sport_MultiSelect__c",selectedSkills);
        var firstInsured = cmp.get("v.firstInsured");
        var relation = cmp.get("v.firstInsuredRelation");
        var calc = cmp.get("v.NNCalculation");
        console.log('jdu dal');
        this.upsertAccount(cmp, firstInsured, accountType, calc, relation, function(a) {
            var returnValue = a.getReturnValue();
            returnValue.PersonBirthdate = $A.localizationService.formatDate(returnValue.PersonBirthdate, "YYYY-MM-DD");
            console.log('hejhej ' + returnValue);
            cmp.set("v.firstInsuredRelation", returnValue[0]);
            cmp.set("v.firstInsured", returnValue[1]);
        });
    },

    createSecondInsured: function(cmp, accountType) {
        var selectedSkills = $('[id$=sportSecondInsured]').select2("val");
        cmp.set("v.secondInsured.Sport_MultiSelect__c",selectedSkills);
        var secondInsured = cmp.get("v.secondInsured");
        var relation = cmp.get("v.secondInsuredRelation");
        var calc = cmp.get("v.NNCalculation");
        this.upsertAccount(cmp, secondInsured, accountType, calc, relation, function(a) {
            var returnValue = a.getReturnValue();
            returnValue.PersonBirthdate = $A.localizationService.formatDate(returnValue.PersonBirthdate, "YYYY-MM-DD");
            cmp.set("v.secondInsuredRelation", returnValue[0]);
            cmp.set("v.secondInsured", returnValue[1]);
        });
    },

    createPolicyHolder: function(cmp, accountType) {
        var policyHolder = cmp.get("v.policyHolder");
        var relation = cmp.get("v.policyHolderRelation");
        var calc = cmp.get("v.NNCalculation");
        this.upsertAccount(cmp, policyHolder, accountType, calc, relation, function(a) {
            var returnValue = a.getReturnValue();
            returnValue.PersonBirthdate = $A.localizationService.formatDate(returnValue.PersonBirthdate, "YYYY-MM-DD");
            cmp.set("v.policyHolderRelation", returnValue[0]);
            cmp.set("v.policyHolder", returnValue[1]);
        });
    },

    upsertAccount : function (component, account, accountType, calc, relation,  callback) {
        var action = component.get('c.saveAccount');
        action.setParams({
           'acc' : account,
           'accountType' : accountType,
           'calc' : calc,
           'relation' : relation
        });

        if (callback) {
            action.setCallback(this, callback);
        }

        $A.enqueueAction(action);
    },

    upsertChildren : function(cmp) {
        var children = cmp.get('v.children');
        var calculationId = cmp.get('v.NNCalculation.Id');
        var action = cmp.get('c.saveChildren');
        action.setParams({
           'childrenString' : JSON.stringify(children),
           'calculationId' : calculationId
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            console.log('stateChildren je ' + state);
            if (state === "SUCCESS") {
                cmp.set('v.children', JSON.parse(response.getReturnValue()));
            }
        });
        $A.enqueueAction(action);
    },

    getNetIncome: function(component, grossIncome) {
        var s = component.get('v.currentStep');
        var action = component.get("c.getNetIncome");
        action.setParams({ 
            "acc": grossIncome
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var parsed = JSON.parse(response.getReturnValue());
                if (s == 2) {
                    component.set('v.firstInsured.NetMonthyIncome__pc', parsed.netIncome);
                } else {
                    component.set('v.secondInsured.NetMonthyIncome__pc', parsed.netIncome);
                }
            }
        });
        $A.enqueueAction(action);
    },

    getComponents: function(component, insuredPersonIndex) {
        var action = component.get("c.getComponents");
        var calculationRequest = component.get("v.NNCalculation.VPMS_Calculation_Request__c");
        action.setParams({
            'calculationRequest' : calculationRequest,
            'insuredPersonIndex' : insuredPersonIndex
        });
        //if (components.length == 0) {
            component.set("v.Spinner", true);
            action.setCallback(this, function(response){
                var state = response.getState();
                if (state === "SUCCESS") {
                    var parsed = JSON.parse(response.getReturnValue());
                    component.set('v.childrenRiders', parsed.childrenRiders);
                    component.set("v.NNCalculation.Total_Premium__c", parsed.totalPremium);
                    component.set("v.NNCalculation.Risk_Discount__c", parsed.riskDiscount);
                    component.set("v.NNCalculation.Group_Discount__c", parsed.groupDiscount);
                    console.log('blabla ');
                    component.set("v.NNCalculation.Frequency_Discount__c", parsed.frequencyDiscount);
                    component.set("v.NNCalculation.Calculated_Employer_Payment__c", parsed.calculatedEmployer);
                    component.set("v.NNCalculation.Total_Premium_After_Discount__c", parsed.totalAfterDiscount);
                    component.set("v.NNCalculation.Calculated_Client_Payment__c", parsed.calculatedClient);
                    console.log('bla ');
                    component.set("v.NNCalculation.VPMS_Calculation_Request__c", parsed.calcRequest);
                    component.set("v.errorMessages", parsed.errorMessages);
                    component.set("v.infoMessages", parsed.infoMessages);
                    component.set("v.warningMessages", parsed.warningMessages);
                    component.set("v.autoCorrectMessages", parsed.autoCorrectMessages);
                    console.log('blablabla ');
                    component.set("v.Spinner", false);
                    if (insuredPersonIndex == '0') {
                        console.log('blablabla ' + parsed.componentsDeath);
                        component.set('v.componentsFirstDeath', parsed.componentsDeath);
                        component.set('v.componentsFirstShort', parsed.componentsShort);
                        component.set('v.componentsFirstLong', parsed.componentsLong);
                    } else {
                        console.log('blablabla ' + parsed.componentsDeath);
                        component.set('v.componentsForSecond', parsed.componentsDeath);
                        console.log('blablabla ');
                        component.set('v.componentsSecondShort', parsed.componentsShort);
                        console.log('blablabla ');
                        component.set('v.componentsSecondLong', parsed.componentsLong);
                        console.log('blablabla ');
                    }
                    component.set('v.children', parsed.children);
                }
            });
            $A.enqueueAction(action);
        //}
    },

    recalculateFunds: function(component) {
        var action = component.get("c.recalculateFundsController");
        var calculation = component.get("v.NNCalculation");
        var calculationRequest = component.get("v.NNCalculation.VPMS_Calculation_Request__c");
        action.setParams({
            'calculationRequest' : calculationRequest,
            'calculation' : calculation
        });
        component.set("v.Spinner", true);
        action.setCallback(this, function(response){
            var state = response.getState();
            console.log('state ' + state);
            if (state === "SUCCESS") {
                var parsed = JSON.parse(response.getReturnValue());
                component.set('v.NNCalculation.Total_Premium__c', parsed.totalPremium);
                component.set('v.NNCalculation.Risk_Discount__c', parsed.riskDiscount);
                component.set('v.NNCalculation.Group_Discount__c', parsed.groupDiscount);
                component.set('v.NNCalculation.Frequency_Discount__c', parsed.frequencyDiscount);
                component.set('v.NNCalculation.Calculated_Employer_Payment__c', parsed.calculatedEmployer);
                component.set('v.NNCalculation.Total_Premium_After_Discount__c', parsed.totalAfterDiscount);
                component.set('v.NNCalculation.VPMS_Calculation_Request__c', parsed.calcRequest);
                component.set('v.NNCalculation.Expected_Yield__c', parsed.expectedYield);
                component.set('v.NNCalculation.Total_Fund_Value__c', parsed.totalFundValue);
                component.set("v.NNCalculation.Calculated_Client_Payment__c", parsed.calculatedClient);
                component.set('v.childrenRiders', parsed.childrenRiders);
                component.set("v.errorMessages", parsed.errorMessages);
                component.set("v.infoMessages", parsed.infoMessages);
                component.set("v.warningMessages", parsed.warningMessages);
                component.set("v.autoCorrectMessages", parsed.autoCorrectMessages);
                component.set("v.fundsList", parsed.fundsList);
                console.log('blablabla ');
                component.set("v.Spinner", false);
                if (calculation.Investment_Strategy__c == 'OWN') {
                    var fundSharing = component.find("fundSharing");
                    var remainingFunds = 100;
                    for (var i = 0; i < fundSharing.length; i++) {
                       console.log('fundsSharing ' + fundSharing[i].get("v.value"));
                       var currentValue = fundSharing[i].get("v.value");
                       if (currentValue != undefined) {
                           remainingFunds -= currentValue;
                       }
                       console.log('remainingFunds ' + remainingFunds);
                    }
                    component.set("v.remainingFunds", remainingFunds);
                }
            }
        });
        $A.enqueueAction(action);
        //}
    },

    getIllustrationData : function(component) {
        console.log('volam ilustraci');
        component.set("v.Spinner", true);
        var action = component.get("c.getVPMSIllustration");
        var action2 = component.get("c.savePDF");
        var calculationId = component.get("v.NNCalculation.Id");
        var calculationRequest = component.get("v.NNCalculation.VPMS_Calculation_Request__c");
        action.setParams({
            'calculationId': calculationId,
            'calculationRequest' : calculationRequest
        });
        action2.setParams({
            'calculationId': calculationId
        });
        action.setCallback(this, function(response){
            component.set('v.chartReady', true);
            component.set("v.Spinner", false);
            action2.setCallback(this, function(response) {

            });
        });
        $A.enqueueAction(action);
        $A.enqueueAction(action2);
    },

    saveComponents : function(component, step) {
        console.log('ukladam komponenty');
        var action = component.get("c.saveComponents");
        var calculationId = component.get("v.NNCalculation.Id");

        var death = component.get("v.componentsFirstDeath");
        var longTerm = component.get("v.componentsFirstLong");
        var shortTerm = component.get("v.componentsFirstShort");
        var account = component.get("v.firstInsured");
        if (step == 5) {
            death = component.get("v.componentsForSecond");
            longTerm = component.get("v.componentsSecondLong");
            shortTerm = component.get("v.componentsSecondShort");
            account = component.get("v.secondInsured");
        }

        action.setParams({
            'death' : JSON.stringify(death),
            'shortTerm' : JSON.stringify(shortTerm),
            'longTerm' : JSON.stringify(longTerm),
            'calculationId': calculationId,
            'account' : account
        });
        action.setCallback(this, function(response){
            console.log('ulozil jsem');
        });
        $A.enqueueAction(action);
    },

    getSelectedRiders : function(component) {
        var death = component.get("v.componentsFirstDeath");
        console.log('l ' + death.length);
        for (var i = 0; i < death.length; i++) {
            console.log('jsem in ');
            console.log('selected ' + death[i]);
        }
    },

    recalculateRiders : function(component, indexPerson) {
        console.log('prepocitavam');
        component.set("v.Spinner", true);
        var action = component.get("c.recalculateRiders");
        var calculationRequest = component.get("v.NNCalculation.VPMS_Calculation_Request__c");
        var groupDiscount = component.get("v.NNCalculation.Group_Discount_Percent__c") != undefined ? component.get("v.NNCalculation.Group_Discount_Percent__c") : 0;
        var employerContribution = component.get("v.NNCalculation.Employer_Contribution__c") != undefined ? component.get("v.NNCalculation.Employer_Contribution__c") : 0;
        var paymentFrequency = component.get("v.NNCalculation.PaymentFrequency__c");
        var variant = component.get("v.NNCalculation.Insurance_Variant__c");
        var product = component.get("v.NNCalculation.Product__c");
        var death = component.get("v.componentsFirstDeath");
        var longTerm = component.get("v.componentsFirstLong");
        var shortTerm = component.get("v.componentsFirstShort");
        var fundsList = component.get('v.fundsList');
        if (indexPerson == '1') {
            death = component.get("v.componentsForSecond");
            longTerm = component.get("v.componentsSecondLong");
            shortTerm = component.get("v.componentsSecondShort");
        }
        var children = component.get("v.children");
        var calculationId = component.get('v.NNCalculation.Id');
        var hasChildren = component.get("v.NNCalculation.Has_Children__c");
        if (hasChildren === undefined) {
            hasChildren = false;
        }
        var firstInsured = component.get("v.firstInsured");
        var secondInsured = component.get("v.secondInsured");
        var selectedSkills = $('[id$=sportFirstInsured]').select2("val");
        var sportString = '';
        if (selectedSkills != null) {
            for (var i = 0; i<selectedSkills.length; i++) {
                sportString += selectedSkills[i];
                sportString += ';';
            }
        }
        action.setParams({
            'death' : JSON.stringify(death),
            'shortTerm' : JSON.stringify(shortTerm),
            'longTerm' : JSON.stringify(longTerm),
            'calculationRequest': calculationRequest,
            'calculationId' : calculationId,
            'groupDiscount' : groupDiscount,
            'employerContribution' : employerContribution,
            'indexInsuredPerson' : indexPerson,
            'paymentFrequency' : paymentFrequency,
            'variant' : variant,
            'product' : product,
            'hasChildren' : hasChildren,
            'children' : JSON.stringify(children),
            'firstInsured' : firstInsured,
            'secondInsured' : secondInsured,
            'selectedSports' : sportString,
            'fundsList' : JSON.stringify(fundsList)
        });
        action.setCallback(this, function(response){
            var parsed = JSON.parse(response.getReturnValue());
            component.set("v.Spinner", false);
            component.set("v.errorMessages", parsed.errorMessages);
            console.log('pokus1 ');
            component.set("v.infoMessages", parsed.infoMessages);
            console.log('pokus1 ');
            component.set("v.warningMessages", parsed.warningMessages);
            console.log('pokus1 ');
            component.set("v.autoCorrectMessages", parsed.autoCorrectMessages);
            component.set("v.NNCalculation.PaymentFrequency__c", parsed.paymentFrequency);
            component.set("v.NNCalculation.Insurance_Variant__c", parsed.variant);
            component.set("v.NNCalculation.Total_Premium__c", parsed.totalPremium);
            component.set("v.NNCalculation.Group_Discount__c", parsed.groupDiscount);
            console.log('pokus1 ');
            component.set("v.NNCalculation.Frequency_Discount__c", parsed.frequencyDiscount);
            component.set("v.NNCalculation.Risk_Discount__c", parsed.riskDiscount);
            component.set("v.NNCalculation.Calculated_Client_Payment__c", parsed.calculatedClient);
            console.log('pokus2 ');
            component.set("v.NNCalculation.Calculated_Employer_Payment__c", parsed.calculatedEmployer);
            component.set("v.NNCalculation.VPMS_Calculation_Request__c", parsed.vpmsRequest);
            console.log('pokus3 ' + indexPerson);
            if (indexPerson == '0') {
                console.log('pokus3 ' + parsed.componentsDeath);
                component.set("v.componentsFirstDeath", parsed.componentsDeath);
                console.log('pokus3 ' + parsed.componentsLong);
                component.set("v.componentsFirstLong", parsed.componentsLong);
                console.log('pokus3 ' + parsed.componentsShort);
                component.set("v.componentsFirstShort", parsed.componentsShort);
            } else if (indexPerson == '1'){
                component.set("v.componentsForSecond", parsed.componentsDeath);
                component.set("v.componentsSecondLong", parsed.componentsLong);
                component.set("v.componentsSecondShort", parsed.componentsShort);
            }
            component.set("v.children", parsed.childrenWrappers);
            console.log('hura vlozil jsem');
        });
        $A.enqueueAction(action);
    },
    scriptsLoaded : function(component, event, helper) {
        console.log('load successfully');

       // active/call select2 plugin function after load jQuery and select2 plugin successfully
       $(".select2Class").select2({
           placeholder: ""
       });
    },

    upsertFunds : function(cmp) {
        console.log('upserting funds');
        var funds = cmp.get('v.fundsList');
        var calcId = cmp.get('v.NNCalculation.Id');
        var action = cmp.get("c.upsertFunds");
        action.setParams({
            'funds' : JSON.stringify(funds),
            'calculationId' : calcId
        });
        action.setCallback(this, function(response){
            console.log('ulozil jsem');
            var parsed = JSON.parse(response.getReturnValue());
            cmp.set('v.fundsList', parsed);
        });
        $A.enqueueAction(action);
    }
})