/**
 * Created by kolmi on 12. 11. 2017.
 */

global with sharing class CalculationController {

    global CalculationController() {

    }

    @AuraEnabled
    public static NN_Calculation__c saveCalculation(NN_Calculation__c calculation) {
        upsert calculation Id;
        return calculation;
    }

    @AuraEnabled
    public static List<Object> saveAccount(Account acc, String accountType, NN_Calculation__c calc, NNRelationship__c relation) {
        List<Object> returnedObjects = new List<Object>();
        if (calc.Is_Anonymous__c) {
            acc.FirstName = '';
            acc.LastName = 'Anonym588'; //TODO doresit
            acc.PersonBirthdate = null;
        }
        upsert acc Id;
        System.debug('acc ' + acc);
        relation.NNCalculation__c = calc.Id;
        relation.Account__c = acc.Id;
        relation.Role__c = accountType;
        upsert relation Id;
        returnedObjects.add(relation);
        returnedObjects.add(acc);
        return returnedObjects;
    }

    @AuraEnabled
    public static String upsertFunds(String funds, String calculationId) {
        List<Fund__c> fundsList = (List<Fund__c>) System.JSON.deserializeStrict(funds, List<Fund__c>.Class);
        for (Fund__c fund : fundsList) {
            fund.NN_Calculation__c = calculationId;
        }
        upsert fundsList Id;
        return JSON.serialize(fundsList);
    }

    @AuraEnabled
    public static String saveChildren(String childrenString, String calculationId) {
        System.debug('blablabla ');
        List<Account> accountsToInsert = new List<Account>();
        List<NNRelationship__c> relationshipsToInsert = new List<NNRelationship__c>();
        List<Component__c> componentsToInsert = new List<Component__c>();
        List<CalculationController.ChildWrapper> childrenWrappers = (List<CalculationController.ChildWrapper>) System.JSON.deserializeStrict(childrenString, List<CalculationController.ChildWrapper>.Class);
        for (CalculationController.ChildWrapper wrap : childrenWrappers) {
            if (wrap.acc == null) {
                Account acc = new Account();
                acc.FirstName = wrap.firstName;
                acc.LastName = wrap.lastName;
                acc.PersonBirthdate = Date.valueOf(wrap.birthDate);
                insert acc;
                wrap.acc = acc;
                for (Component__c c : wrap.components) {
                    c.NN_Calculation__c = calculationId;
                    c.Account__c = acc.Id;
                    if (c.Selected__c) {
                        componentsToInsert.add(c);
                    }
                }
                NNRelationship__c rel = new NNRelationship__c();
                rel.Account__c = acc.Id;
                rel.NNCalculation__c = calculationId;
                rel.Role__c = 'Child';
                insert rel;
                wrap.rel = rel;
            } else {
                System.debug('idecka mam, nic nemusim');
            }

        }
        upsert componentsToInsert Id;
        childrenString = JSON.serialize(childrenWrappers);
        System.debug('nachazim ' + childrenString);
        return childrenString;
    }

    @AuraEnabled
    public static Map<String, List<Component__c>> saveComponents(String death, String shortTerm, String longTerm, String calculationId, Account account) {
        List<Component__c> componentsToInsert = new List<Component__c>();
        Map<String, List<Component__c>> components = new Map<String, List<Component__c>>();
        Component__c[] deathComponents = (List<Component__c>) System.JSON.deserializeStrict(death, List<Component__c>.Class);
        Component__c[] shortTermComponents = (List<Component__c>) System.JSON.deserializeStrict(shortTerm, List<Component__c>.Class);
        Component__c[] longTermComponents = (List<Component__c>) System.JSON.deserializeStrict(longTerm, List<Component__c>.Class);
        components.put('death', deathComponents);
        components.put('shortTerm', shortTermComponents);
        components.put('longTerm', longTermComponents);
        List<Component__c> componentsToDelete = [SELECT Id FROM Component__c WHERE NN_Calculation__c = :calculationId AND Account__c = :account.Id];
        delete componentsToDelete;
        for (List<Component__c> comps : components.values()) {
            for (Component__c singleComponent : comps) {
                if (singleComponent.Selected__c) {
                    singleComponent.NN_Calculation__c = calculationId;
                    singleComponent.Account__c = account.Id;
                    componentsToInsert.add(singleComponent);
                }
            }
        }
        insert componentsToInsert;
        return components;
    }

    @AuraEnabled
    public static NNRelationship__c saveNNnRelationship() {
        return null; //TODO
    }

    @AuraEnabled
    global static String getVPMSResponse(String calcId, String accId) {
        System.debug('calcId ' + calcId + ' ' + 'accId ' + accId);
        StaticResource sr2 = [SELECT Id, Body FROM StaticResource WHERE Name = 'calculateJson' LIMIT 1];
        String body2 = sr2.Body.toString();

        Calculation_Initialization__c calc = [SELECT Id, Product__c, Planned_Signature_Date__c, Start_Insurance_Date__c, Payment_Frequency__c, Product_Variant__c, Special_Group__c FROM Calculation_Initialization__c];
        Map<String, Object> values = new Map<String, Object>();
        values.put('totalPremium', 2.00);
        values.put('expectedSignatureDate', calc.Planned_Signature_Date__c);
        values.put('firstTop', calc.Start_Insurance_Date__c);
        values.put('paymentFrequency', calc.Payment_Frequency__c);
        values.put('productCode', calc.Product__c);
        values.put('variant', calc.Product_Variant__c);
        values.put('specialGroup', calc.Special_Group__c);
        values.put('vpmsCalcRequest', body2);
        return JSON.serialize(values);
    }

    @AuraEnabled
    public static List<PicklistOption> getPaymentFrequencies() {
        List<PicklistOption> options = new List<PicklistOption>();
        Schema.DescribeFieldResult fieldResult = NN_Calculation__c.PaymentFrequency__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f : ple) {
            options.add(new PicklistOption(f.getLabel(), f.getValue(), f.defaultValue));
        }
        return options;
    }

    @AuraEnabled
    public static List<PicklistOption> getProducts() {
        List<PicklistOption> options = new List<PicklistOption>();
        Schema.DescribeFieldResult fieldResult = NN_Calculation__c.Product__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f : ple) {
            options.add(new PicklistOption(f.getLabel(), f.getValue()));
        }
        return options;
    }

    @AuraEnabled
    public static List<PicklistOption> getEmploymentTypes() {
        List<PicklistOption> options = new List<PicklistOption>();
        Schema.DescribeFieldResult fieldResult = Account.EmploymentTypeNew__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f : ple) {
            options.add(new PicklistOption(f.getLabel(), f.getValue(), f.defaultValue));
        }
        return options;
    }

    @AuraEnabled
    public static List<PicklistOption> getInvestmentVariants() {
        List<PicklistOption> options = new List<PicklistOption>();
        Schema.DescribeFieldResult fieldResult = NN_Calculation__c.Investment_Variant__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f : ple) {
            options.add(new PicklistOption(f.getLabel(), f.getValue(), f.defaultValue));
        }
        return options;
    }

    @AuraEnabled
    public static List<PicklistOption> getInsuranceVariants() {
        List<PicklistOption> options = new List<PicklistOption>();
        Schema.DescribeFieldResult fieldResult = NN_Calculation__c.Insurance_Variant__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f : ple) {
            options.add(new PicklistOption(f.getLabel(), f.getValue(), f.defaultValue));
        }
        return options;
    }

    @AuraEnabled
    public static List<PicklistOption> getSpecialGroups() {
        List<PicklistOption> options = new List<PicklistOption>();
        Schema.DescribeFieldResult fieldResult = NN_Calculation__c.Special_Group__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f : ple) {
            options.add(new PicklistOption(f.getLabel(), f.getValue(), f.defaultValue));
        }
        return options;
    }

    @AuraEnabled
    public static List<PicklistOption> getInvestmentStrategies() {
        List<PicklistOption> options = new List<PicklistOption>();
        Schema.DescribeFieldResult fieldResult = NN_Calculation__c.Investment_Strategy__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f : ple) {
            options.add(new PicklistOption(f.getLabel(), f.getValue(), f.defaultValue));
        }
        return options;
    }

    @AuraEnabled
    public static List<PicklistOption> getInvestmentFrequencies() {
        List<PicklistOption> options = new List<PicklistOption>();
        Schema.DescribeFieldResult fieldResult = NN_Calculation__c.Investment_Frequency_Extra__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f : ple) {
            options.add(new PicklistOption(f.getLabel(), f.getValue(), f.defaultValue));
        }
        return options;
    }

    @AuraEnabled
    public static List<PicklistOption> getSports() {
        List<PicklistOption> options = new List<PicklistOption>();
        for (Sport__c s : [SELECT Sport_Code__c, Sport_Description__c FROM Sport__c where Country__c = 'SK']) {
            options.add(new PicklistOption(s.Sport_Description__c, s.Sport_Code__c));
        }
        return options;
    }

    @AuraEnabled
    public static List<PicklistOption> getOccupations() {
        List<PicklistOption> options = new List<PicklistOption>();
        for (Occupation__c s : [SELECT Occupation_Code__c, Occupation_Name__c FROM Occupation__c where Country__c = 'SK']) {
            options.add(new PicklistOption(s.Occupation_Name__c, s.Occupation_Code__c));
        }
        return options;
    }

    @AuraEnabled
    public static String getNetIncome(Account acc) {
        Map<String, Object> values = new Map<String, Object>();
        VPMSCalloutLightning call = new VPMSCalloutLightning();
        StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'calculateJson' LIMIT 1];
        String body = sr.Body.toString();
        Map<String, Object> initMap = new Map<String, Object>();
        initMap = (Map<String, Object>) JSON.deserializeUntyped(body);
        VPMSCalculationAndIllustrationRequest request;
        String serializedRequest = JSON.serialize(initMap, true);
        request = (VPMSCalculationAndIllustrationRequest) JSON.deserialize(serializedRequest, VPMSCalculationAndIllustrationRequest.class);
        request.VpmsRequest.data.InsuredPerson[0].GrossMonthlyIncome = String.valueOf(acc.GrossMonthyIncome__pc);
        String neco = JSON.serialize(request, true);
        initMap = (Map<String, Object>) JSON.deserializeUntyped(neco);
        Map<String, Object> outMap = new Map<String, Object>();
        call.invokeMethod('ComputeWithVal', initMap, outMap);
        outMap = (Map<String, Object>) outMap.get('response');
        String respJson = JSON.serialize(outMap);
        VPMSInitProductResponse response = (VPMSInitProductResponse) JSON.deserialize(respJson, VPMSInitProductResponse.class);
        values.put('netIncome', Decimal.valueOf(response.VpmsResponse.calc.InsuredPerson[0].NetMonthlyIncome.value));
        return JSON.serialize(values);
    }

    @AuraEnabled
    public static String getComponents(String calculationRequest, String insuredPersonIndex) {
        List<String> errorMessages = new List<String>();
        List<String> infoMessages = new List<String>();
        List<String> warningMessages = new List<String>();
        List<String> autoCorrectMessages = new List<String>();
        Map<String, Object> values = new Map<String, Object>();
        VPMSCalloutLightning call = new VPMSCalloutLightning();
        Map<String, Object> initMap = new Map<String, Object>();
        initMap = (Map<String, Object>) JSON.deserializeUntyped(calculationRequest);
        VPMSCalculationAndIllustrationRequest request;
        String serializedRequest = JSON.serialize(initMap, true);
        request = (VPMSCalculationAndIllustrationRequest) JSON.deserialize(serializedRequest, VPMSCalculationAndIllustrationRequest.class);
        Boolean secondInsuredIsNull = false;
        if (Integer.valueOf(insuredPersonIndex) == 1) {
            if (request.VpmsRequest.data.SecondInsuredPerson.Component == null) {
                secondInsuredIsNull = true;
                VPMSCalculationAndIllustrationRequest.cls_InsuredPerson secondInsured = new VPMSCalculationAndIllustrationRequest.cls_InsuredPerson();
                secondInsured.BirthDate = '01.01.1987';
                secondInsured.GrossMonthlyIncome = '0';
                secondInsured.Sports = new List<String>();
                secondInsured.Sports.add('');
                secondInsured.EmploymentType = 'Z';
                secondInsured.Occupation = 'Z1';
                secondInsured.Component = request.VpmsRequest.data.InsuredPerson[0].Component;
                request.VpmsRequest.data.SecondInsuredPerson = secondInsured;
//                for (VPMSCalculationAndIllustrationRequest.cls_Component comp : request.VpmsRequest.data.SecondInsuredPerson.Component) {
//                    if (comp.ComponentCode.equals('R22S') || comp.ComponentCode.equals('UM2S') ) {
//                        comp.ComponentSelected = '1';
//                    } else {
//                        comp.ComponentSelected = '0';
//                    }
//                }
                request.VpmsRequest.data.InsuredPerson.add(secondInsured);
//                request.VpmsRequest.data.InsuredPerson.add(secondInsured);
//                for (VPMSCalculationAndIllustrationRequest.cls_Component comp : request.VpmsRequest.data.InsuredPerson[1].Component) {
//                    if (comp.ComponentCode.equals('R22S') || comp.ComponentCode.equals('UM2S')) {
//                        comp.ComponentSelected = '1';
//                    } else {
//                        comp.ComponentSelected = '0';
//                    }
//                }
            }
        }
        String calcRequest = JSON.serialize(request, true);
        initMap = (Map<String, Object>) JSON.deserializeUntyped(calcRequest);
        Map<String, Object> outMap = new Map<String, Object>();
        call.invokeMethod('ComputeWithVal', initMap, outMap);
        outMap = (Map<String, Object>) outMap.get('response');
        String respJson = JSON.serialize(outMap);
        System.debug('getComponents response ' + respJson);
        VPMSInitProductResponse response = (VPMSInitProductResponse) JSON.deserialize(respJson, VPMSInitProductResponse.class);
        List<Component__c> componentsDeath = new List<Component__c>();
        List<Component__c> componentsLongTerm = new List<Component__c>();
        List<Component__c> componentsShortTerm = new List<Component__c>();
        List<Component__c> childrenRiders = new List<Component__c>();
        List<ChildWrapper> children = new List<ChildWrapper>();
        if (Integer.valueOf(insuredPersonIndex) == 0) {
            for (VPMSInitProductResponse.cls_Component comp : response.VpmsResponse.data.InsuredPerson[0].Component) {
                if (comp.ChildrenRider != null && !comp.ChildrenRider) {
                    Component__c c = new Component__c();
                    c.Term__c = Decimal.valueOf(comp.Term.value);
                    c.SumAssured__c = Decimal.valueOf(comp.SumAssured.value);
                    c.MedicalLoading__c = Decimal.valueOf(comp.MUWLoadingPercent.value);
                    c.PremiumAfterAllDiscount__c = Decimal.valueOf(comp.PremiumAfterAllDiscount.value);
                    c.PremiumBeforeAllDiscount__c = Decimal.valueOf(comp.PremiumBeforeAllDiscount.value);
                    c.Code__c = comp.ComponentCode.value;
                    c.ComponentName__c = comp.ComponentName.value;
                    c.ComponentGroupName__c = comp.ComponentGroupName;
                    System.debug('hint ' + comp.ComponentHint);
                    c.Component_Hint__c = comp.ComponentHint;
                    System.debug('c.Component_Hint__c ' + c.Component_Hint__c);
                    if (comp.ComponentCode.value.equals('RM2S') || comp.ComponentCode.value.equals('UM2S') || comp.ComponentSelected.value.equals('1')) {
                        if (comp.ComponentCode.value.equals('RM2S') || comp.ComponentCode.value.equals('UM2S')) {
                            c.Disabled__c = true;
                        }
                        c.Selected__c = true;
                    } else {
                        c.Disabled__c = false;
                        c.Selected__c = false;
                    }
                    if (comp.ComponentGroupName.equalsIgnoreCase('Úmrtie')) {
                        componentsDeath.add(c);
                    } else if (comp.ComponentGroupName.equalsIgnoreCase('Dlhodobé dopady na život')) {
                        componentsLongTerm.add(c);
                    } else {
                        componentsShortTerm.add(c);
                    }
                } else if (comp.ChildrenRider != null && comp.ChildrenRider) {
                    Component__c c = new Component__c();
                    c.Term__c = Decimal.valueOf(comp.Term.value);
                    c.SumAssured__c = Decimal.valueOf(comp.SumAssured.value);
                    c.MedicalLoading__c = Decimal.valueOf(comp.MUWLoadingPercent.value);
                    c.PremiumAfterAllDiscount__c = Decimal.valueOf(comp.PremiumAfterAllDiscount.value);
                    c.PremiumBeforeAllDiscount__c = Decimal.valueOf(comp.PremiumBeforeAllDiscount.value);
                    c.Code__c = comp.ComponentCode.value;
                    c.ComponentName__c = comp.ComponentName.value;
                    c.Component_Hint__c = comp.ComponentHint;
                    c.Selected__c = false;
                    childrenRiders.add(c);
                }
            }
        } else {
            List<VPMSInitProductResponse.cls_Component> componentsList = new List<VPMSInitProductResponse.cls_Component>();
            if (response.VpmsResponse.data.SecondInsuredPerson != null && response.VpmsResponse.data.SecondInsuredPerson.Component != null) {
                componentsList = response.VpmsResponse.data.SecondInsuredPerson.Component;
            } else {
                componentsList = response.VpmsResponse.data.InsuredPerson[1].Component;
            }
            for (VPMSInitProductResponse.cls_Component comp : componentsList) {
                if (comp.ChildrenRider != null && !comp.ChildrenRider) {
                    Component__c c = new Component__c();
                    c.Term__c = Decimal.valueOf(comp.Term.value);
                    c.SumAssured__c = Decimal.valueOf(comp.SumAssured.value);
                    c.MedicalLoading__c = Decimal.valueOf(comp.MUWLoadingPercent.value);
                    c.PremiumAfterAllDiscount__c = Decimal.valueOf(comp.PremiumAfterAllDiscount.value);
                    c.PremiumBeforeAllDiscount__c = Decimal.valueOf(comp.PremiumBeforeAllDiscount.value);
                    c.Code__c = comp.ComponentCode.value;
                    c.ComponentName__c = comp.ComponentName.value;
                    c.ComponentGroupName__c = comp.ComponentGroupName;
                    c.Default_Sum_Assured__c = Decimal.valueOf(comp.SumAssured.value);
                    c.Component_Hint__c = comp.ComponentHint;
                    if (comp.ComponentCode.value.equals('RM2S') || comp.ComponentCode.value.equals('UM2S') || comp.ComponentCode.equals('R22S') || comp.ComponentSelected.value.equals('1')) {
                        if (comp.ComponentCode.value.equals('RM2S') || comp.ComponentCode.value.equals('UM2S') || comp.ComponentCode.equals('R22S')) {
                            c.Disabled__c = true;
                        }
                        c.Selected__c = true;
                    } else {
                        c.Disabled__c = false;
                        c.Selected__c = false;
                    }
                    if (comp.ComponentGroupName.equalsIgnoreCase('Úmrtie')) {
                        componentsDeath.add(c);
                    } else if (comp.ComponentGroupName.equalsIgnoreCase('Dlhodobé dopady na život')) {
                        componentsLongTerm.add(c);
                    } else {
                        componentsShortTerm.add(c);
                    }
                } else if (comp.ChildrenRider != null && comp.ChildrenRider) {
                    Component__c c = new Component__c();
                    c.Term__c = Decimal.valueOf(comp.Term.value);
                    c.SumAssured__c = Decimal.valueOf(comp.SumAssured.value);
                    c.MedicalLoading__c = Decimal.valueOf(comp.MUWLoadingPercent.value);
                    c.PremiumAfterAllDiscount__c = Decimal.valueOf(comp.PremiumAfterAllDiscount.value);
                    c.PremiumBeforeAllDiscount__c = Decimal.valueOf(comp.PremiumBeforeAllDiscount.value);
                    c.Code__c = comp.ComponentCode.value;
                    c.ComponentName__c = comp.ComponentName.value;
                    c.Selected__c = false;
                    c.Component_Hint__c = comp.ComponentHint;
                    //c.Editable__c = true;
                    childrenRiders.add(c);
                }
            }

        }
        children = initChildren(children, childrenRiders);
        VPMSInitProductResponse.cls_rows[] warnings = response.VpmsResponse.calc.Product.Warnings.rows;
        if (warnings != null) {
            for (VPMSInitProductResponse.cls_rows row : warnings) {
                warningMessages.add(row.col2);
            }
        }
        VPMSInitProductResponse.cls_rows[] infos = response.VpmsResponse.calc.Product.Infos.rows;
        if (infos != null) {
            for (VPMSInitProductResponse.cls_rows row : infos) {
                infoMessages.add(row.col2);
            }
        }
        VPMSInitProductResponse.cls_rows[] errors = response.VpmsResponse.calc.Product.Errors.rows;
        if (errors != null) {
            for (VPMSInitProductResponse.cls_rows row : errors) {
                errorMessages.add(row.col2);
            }
        }
        VPMSInitProductResponse.cls_rows[] autoCorrect = response.VpmsResponse.calc.Product.Autocorrect.rows;
        if (autoCorrect != null) {
            for (VPMSInitProductResponse.cls_rows row : autoCorrect) {
                autoCorrectMessages.add(row.col2);
            }
        }
        values.put('children', children);
        values.put('childrenRiders', childrenRiders);
        values.put('componentsDeath', componentsDeath);
        values.put('componentsLong', componentsLongTerm);
        values.put('componentsShort', componentsShortTerm);
        values.put('calculatedClient', Decimal.valueOf(response.VpmsResponse.calc.Product.CalculatedClientPremium.value));
        values.put('totalPremium', Decimal.valueOf(response.VpmsResponse.calc.Product.TotalPremiumAfterDiscounts.value));
        values.put('riskDiscount', Decimal.valueOf(response.VpmsResponse.calc.Product.RiskDiscount.value));
        values.put('groupDiscount', Decimal.valueOf(response.VpmsResponse.calc.Product.GroupDiscount.value));
        values.put('frequencyDiscount', Decimal.valueOf(response.VpmsResponse.calc.Product.FrequencyDiscount.value));
        values.put('calculatedEmployer', Decimal.valueOf(response.VpmsResponse.calc.Product.CalculatedEmployerPayment.value));
        values.put('totalAfterDiscount', Decimal.valueOf(response.VpmsResponse.calc.Product.TotalPremiumAfterDiscounts.value));
        values.put('calcRequest', calcRequest);
        values.put('errorMessages', errorMessages);
        values.put('infoMessages', infoMessages);
        values.put('warningMessages', warningMessages);
        values.put('autoCorrectMessages', autoCorrectMessages);
        return JSON.serialize(values);
    }

    @AuraEnabled
    public static String recalculateFundsController(String calculationRequest, NN_Calculation__c calculation) {
        List<String> errorMessages = new List<String>();
        List<String> infoMessages = new List<String>();
        List<String> warningMessages = new List<String>();
        List<String> autoCorrectMessages = new List<String>();
        List<Fund__c> fundsList = new List<Fund__c>();
        Map<String, Object> values = new Map<String, Object>();
        VPMSCalloutLightning call = new VPMSCalloutLightning();
        Map<String, Object> initMap = new Map<String, Object>();
        initMap = (Map<String, Object>) JSON.deserializeUntyped(calculationRequest);
        VPMSCalculationAndIllustrationRequest request;
        String serializedRequest = JSON.serialize(initMap, true);
        request = (VPMSCalculationAndIllustrationRequest) JSON.deserialize(serializedRequest, VPMSCalculationAndIllustrationRequest.class);
        request.VpmsRequest.data.Investment.InvestmentStrategy = calculation.Investment_Strategy__c;
        String neco = JSON.serialize(request, true);
        initMap = (Map<String, Object>) JSON.deserializeUntyped(neco);
        Map<String, Object> outMap = new Map<String, Object>();
        call.invokeMethod('ComputeWithVal', initMap, outMap);
        outMap = (Map<String, Object>) outMap.get('response');
        String respJson = JSON.serialize(outMap);
        VPMSInitProductResponse response = (VPMSInitProductResponse) JSON.deserialize(respJson, VPMSInitProductResponse.class);
        VPMSInitProductResponse.cls_rows[] warnings = response.VpmsResponse.calc.Product.Warnings.rows;
        if (warnings != null) {
            for (VPMSInitProductResponse.cls_rows row : warnings) {
                warningMessages.add(row.col2);
            }
        }
        VPMSInitProductResponse.cls_rows[] infos = response.VpmsResponse.calc.Product.Infos.rows;
        if (infos != null) {
            for (VPMSInitProductResponse.cls_rows row : infos) {
                infoMessages.add(row.col2);
            }
        }
        VPMSInitProductResponse.cls_rows[] errors = response.VpmsResponse.calc.Product.Errors.rows;
        if (errors != null) {
            for (VPMSInitProductResponse.cls_rows row : errors) {
                errorMessages.add(row.col2);
            }
        }
        VPMSInitProductResponse.cls_rows[] autoCorrect = response.VpmsResponse.calc.Product.Autocorrect.rows;
        if (autoCorrect != null) {
            for (VPMSInitProductResponse.cls_rows row : autoCorrect) {
                autoCorrectMessages.add(row.col2);
            }
        }
        VPMSInitProductResponse.cls_rows[] fundsRows = response.VpmsResponse.calc.Investment.InvestmentFund.rows;
        if (fundsRows != null && calculation.Investment_Strategy__c == 'OWN') {
            for (VPMSInitProductResponse.cls_rows row : fundsRows) {
                Fund__c fund = new Fund__c();
                fund.FundCode__c = row.col1;
                fund.Fund_Name__c = row.col3;
                fund.Sharing__c = 0;
                fund.Expected_Profit__c = row.col6;
                fundsList.add(fund);
            }
        }
        values.put('calculatedClient', Decimal.valueOf(response.VpmsResponse.calc.Product.CalculatedClientPremium.value));
        values.put('totalPremium', Decimal.valueOf(response.VpmsResponse.calc.Product.TotalPremiumAfterDiscounts.value));
        values.put('riskDiscount', Decimal.valueOf(response.VpmsResponse.calc.Product.RiskDiscount.value));
        values.put('groupDiscount', Decimal.valueOf(response.VpmsResponse.calc.Product.GroupDiscount.value));
        values.put('frequencyDiscount', Decimal.valueOf(response.VpmsResponse.calc.Product.FrequencyDiscount.value));
        values.put('calculatedEmployer', Decimal.valueOf(response.VpmsResponse.calc.Product.CalculatedEmployerPayment.value));
        values.put('totalAfterDiscount', Decimal.valueOf(response.VpmsResponse.calc.Product.TotalPremiumAfterDiscounts.value));
        values.put('totalFundValue', Decimal.valueOf(response.VpmsResponse.calc.Investment.TotalFundValue.value));
        values.put('expectedYield', response.VpmsResponse.calc.Investment.ExpectedYield.value);
        values.put('calcRequest', neco);
        values.put('errorMessages', errorMessages);
        values.put('infoMessages', infoMessages);
        values.put('warningMessages', warningMessages);
        values.put('autoCorrectMessages', autoCorrectMessages);
        values.put('fundsList', fundsList);
//values.put('vpmsRequestCalc', body);
        return JSON.serialize(values);
    }

    @AuraEnabled
    public static String getVPMSIllustration(String calculationId, String calculationRequest) {
        Map<String, Object> values = new Map<String, Object>();
        VPMSCalloutLightning call = new VPMSCalloutLightning();
        Map<String, Object> initMap = new Map<String, Object>();
        initMap = (Map<String, Object>) JSON.deserializeUntyped(calculationRequest);
        ((Map<String, Object>) initMap.get('VpmsRequest')).put('ApplicationId', calculationId);
        Map<String, Object> outMap = new Map<String, Object>();
        call.invokeMethod('ComputeAndIllustrate', initMap, outMap);
        outMap = (Map<String, Object>) outMap.get('response');
        String respJson = JSON.serialize(outMap);
        VPMSInitProductResponse response = (VPMSInitProductResponse) JSON.deserialize(respJson, VPMSInitProductResponse.class);
        PopulateJSONData pop = new PopulateJSONData();
        StaticResource sr2 = [SELECT Id, Body FROM StaticResource WHERE Name = 'VpmsJsonData' LIMIT 1];
        String VPMSJsonChartRequest = sr2.Body.toString();
        Map<String, Object> jsonInitMap = new Map<String, Object>();
        jsonInitMap = (Map<String, Object>) JSON.deserializeUntyped(VPMSJsonChartRequest);
        jsonInitMap.put('ApplicationId', calculationId);
        pop.invokeMethod('updateJSONData', jsonInitMap, outMap, null);
//IllustrationPDFController.savePdfAsAttachment(calculationId, 'SK_PROTECT_Illustration_Template_4_0');
        return JSON.serialize(values);
    }

    @AuraEnabled
    public static String savePDF(String calculationId) {
        IllustrationPDFController.savePdfAsAttachment(calculationId, 'SK_PROTECT_Illustration_Template_4_0');
        return calculationId;
    }

    @AuraEnabled
    public static String recalculateRiders(String death, String shortTerm, String longTerm, String calculationRequest, String calculationId, Decimal groupDiscount, Decimal employerContribution, String indexInsuredPerson, String paymentFrequency, String variant, String product, Boolean hasChildren, String children, Account firstInsured, Account secondInsured, String selectedSportsFirstInsured, String selectedSportsSecondInsured, String fundsList) {
        List<String> infoMessages = new List<String>();
        List<String> errorMessages = new List<String>();
        List<String> warningMessages = new List<String>();
        List<String> autoCorrectMessages = new List<String>();
        List<Component__c> componentsToInsert = new List<Component__c>();
        Map<String, List<Component__c>> components = new Map<String, List<Component__c>>();
        Component__c[] deathComponents = (List<Component__c>) System.JSON.deserializeStrict(death, List<Component__c>.Class);
        Component__c[] shortTermComponents = (List<Component__c>) System.JSON.deserializeStrict(shortTerm, List<Component__c>.Class);
        Component__c[] longTermComponents = (List<Component__c>) System.JSON.deserializeStrict(longTerm, List<Component__c>.Class);
        List<ChildWrapper> childrenWrappers = (List<ChildWrapper>) System.JSON.deserializeStrict(children, List<ChildWrapper>.Class);
        components.put('death', deathComponents);
        components.put('shortTerm', shortTermComponents);
        components.put('longTerm', longTermComponents);
        VPMSCalculationAndIllustrationRequest request;
        Map<String, Object> values = new Map<String, Object>();
        VPMSCalloutLightning call = new VPMSCalloutLightning();
        Map<String, Object> initMap = new Map<String, Object>();
        initMap = (Map<String, Object>) JSON.deserializeUntyped(calculationRequest);
        ((Map<String, Object>) initMap.get('VpmsRequest')).put('ApplicationId', calculationId);
        String serializedRequest = JSON.serialize(initMap, true);
        request = (VPMSCalculationAndIllustrationRequest) JSON.deserialize(serializedRequest, VPMSCalculationAndIllustrationRequest.class);
        request.VpmsRequest.data.Product.GroupDiscountPercent = String.valueOf(groupDiscount);
        request.VpmsRequest.data.Product.EmployerPayment = String.valueOf(employerContribution);
        request.VpmsRequest.data.Product.PaymentFrequency = paymentFrequency;
        request.VpmsRequest.data.Product.ProductVariant = variant;
        request.VpmsRequest.data.Product.ProductCode = product;
        request.VpmsRequest.data.Product.ProposalDate = '19.03.2018';
        request.VpmsRequest.data.Product.ExpectedSignatureDate = '18.03.2018';
        if (product.equals('UM2S')) {
            List<Fund__c> funds = (List<Fund__c>) System.JSON.deserializeStrict(fundsList, List<Fund__c>.Class);
            if (funds != null && !funds.isEmpty()) {
                request.VpmsRequest.data.Investment.funds = new List<VPMSCalculationAndIllustrationRequest.cls_Funds>();
                for (Fund__c f : funds) {
                    VPMSCalculationAndIllustrationRequest.cls_Funds fundDef = new VPMSCalculationAndIllustrationRequest.cls_Funds();
                    fundDef.DistributionRatio = String.valueOf(f.Sharing__c.setScale(0));
                    fundDef.FundCode = f.FundCode__c;
                    request.VpmsRequest.data.Investment.funds.add(fundDef);
                }
            }
        } else {
            //request.VpmsRequest.data.Investment.funds = null;
        }
        if (Integer.valueOf(indexInsuredPerson) == 0) {
            VPMSCalculationAndIllustrationRequest.cls_Component[] componentsList = request.VpmsRequest.data.InsuredPerson[0].Component;
            for (List<Component__c> comps : components.values()) {
                for (Component__c singleComponent : comps) {
                    for (VPMSCalculationAndIllustrationRequest.cls_Component cmp : componentsList) {
                        if (singleComponent.Code__c.equals(cmp.ComponentCode)) {
                            cmp.SumAssured = String.valueOf(singleComponent.SumAssured__c.setScale(0));
                            cmp.Term = String.valueOf(singleComponent.Term__c.setScale(0));
                            cmp.MUWLoadingPercent = String.valueOf(singleComponent.MedicalLoading__c);
                            if (singleComponent.Selected__c) {
                                cmp.ComponentSelected = '1';
                            } else {
                                cmp.ComponentSelected = '0';
                            }
                        }
                    }
                }
            }
            request.VpmsRequest.data.InsuredPerson[0].Occupation = firstInsured.Occupation_New__c != null ? firstInsured.Occupation_New__c : 'Z1';
            request.VpmsRequest.data.InsuredPerson[0].Sports = new List<String>();
            System.debug('sports ' + request.VpmsRequest.data.InsuredPerson[0]);
            if (selectedSportsFirstInsured != null && selectedSportsFirstInsured != '') {
                List<String> sports = selectedSportsFirstInsured.split(';');
                for (String s : sports) {
                    request.VpmsRequest.data.InsuredPerson[0].Sports.add(s);
                }
            } else {
                request.VpmsRequest.data.InsuredPerson[0].Sports.add('');
            }
            System.debug('sports ' + request.VpmsRequest.data.InsuredPerson[0].Sports);
            request.VpmsRequest.data.InsuredPerson[0].EmploymentType = firstInsured.EmploymentTypeNew__c != null ? firstInsured.EmploymentTypeNew__c : 'Z';
            request.VpmsRequest.data.InsuredPerson[0].GrossMonthlyIncome = firstInsured.GrossMonthyIncome__pc != null ? String.valueOf(firstInsured.GrossMonthyIncome__pc) : '0';
        } else {
            VPMSCalculationAndIllustrationRequest.cls_Component[] componentsList = request.VpmsRequest.data.InsuredPerson[1].Component;
            for (List<Component__c> comps : components.values()) {
                for (Component__c singleComponent : comps) {
                    for (VPMSCalculationAndIllustrationRequest.cls_Component cmp : componentsList) {
                        if (singleComponent.Code__c.equals(cmp.ComponentCode)) {
                            cmp.SumAssured = String.valueOf(singleComponent.SumAssured__c.setScale(0));
                            cmp.Term = String.valueOf(singleComponent.Term__c.setScale(0));
                            cmp.MUWLoadingPercent = String.valueOf(singleComponent.MedicalLoading__c);
                            if (singleComponent.Selected__c) {
                                cmp.ComponentSelected = '1';
                            } else {
                                cmp.ComponentSelected = '0';
                            }
                        }
                    }
                }
            }
            request.VpmsRequest.data.InsuredPerson[1].Occupation = secondInsured.Occupation_New__c != null ? secondInsured.Occupation_New__c : 'Z1';
            request.VpmsRequest.data.InsuredPerson[1].Sports = new List<String>();
            System.debug('sports ' + request.VpmsRequest.data.InsuredPerson[1]);
            if (selectedSportsSecondInsured != null && selectedSportsSecondInsured != '') {
                List<String> sports = selectedSportsSecondInsured.split(';');
                for (String s : sports) {
                    request.VpmsRequest.data.InsuredPerson[1].Sports.add(s);
                }
            } else {
                request.VpmsRequest.data.InsuredPerson[1].Sports.add('');
            }
            System.debug('sports ' + request.VpmsRequest.data.InsuredPerson[1].Sports);
            request.VpmsRequest.data.InsuredPerson[1].EmploymentType = secondInsured.EmploymentTypeNew__c != null ? secondInsured.EmploymentTypeNew__c : 'Z';
            request.VpmsRequest.data.InsuredPerson[1].GrossMonthlyIncome = secondInsured.GrossMonthyIncome__pc != null ? String.valueOf(secondInsured.GrossMonthyIncome__pc) : '0';
        }
        if (hasChildren) {
            request.VpmsRequest.data.Children = new List<VPMSCalculationAndIllustrationRequest.cls_Children>();
            for (ChildWrapper childWrap : childrenWrappers) {
                VPMSCalculationAndIllustrationRequest.cls_Children child = new VPMSCalculationAndIllustrationRequest.cls_Children();
                child.Component = new List<VPMSCalculationAndIllustrationRequest.cls_Component>();
                for (Component__c c : childWrap.components) {
                    VPMSCalculationAndIllustrationRequest.cls_Component childComponent = new VPMSCalculationAndIllustrationRequest.cls_Component();
                    childComponent.Term = '13'; //TODO
                    childComponent.SumAssured = String.valueOf(c.SumAssured__c);
                    childComponent.MUWLoadingPercent = String.valueOf(c.MedicalLoading__c.setScale(0));
                    childComponent.InsuredUntilAge = '18'; //TODO
                    childComponent.ComponentSelected = c.Selected__c ? '1' : '0';
                    childComponent.ComponentCode = c.Code__c;
                    child.Component.add(childComponent);
                }
                //child.BirthDate = String.valueOf(childWrap.birthDate);
                child.BirthDate = '08.08.2012';
                child.Name = childWrap.firstName;
                request.VpmsRequest.data.Children.add(child);
            }
        }
        serializedRequest = JSON.serialize(request, true);
        System.debug('serializedRequest ' + serializedRequest);
        initMap = (Map<String, Object>) JSON.deserializeUntyped(serializedRequest);
        Map<String, Object> outMap = new Map<String, Object>();
        call.invokeMethod('ComputeWithVal', initMap, outMap);
        outMap = (Map<String, Object>) outMap.get('response');
        String respJson = JSON.serialize(outMap);
        System.debug('responseJson ' + respJson);
        VPMSInitProductResponse response = (VPMSInitProductResponse) JSON.deserialize(respJson, VPMSInitProductResponse.class);
        for (List<Component__c> comps : components.values()) {
            for (Component__c singleComponent : comps) {
                if (Integer.valueOf(indexInsuredPerson) == 0) {
                    for (VPMSInitProductResponse.cls_Component cmp : response.VpmsResponse.data.InsuredPerson[0].Component) {
                        if (singleComponent.Code__c.equals(cmp.ComponentCode.value) && singleComponent.Selected__c) {
                            if (cmp.SumAssured != null && cmp.SumAssured.value != null) {
                                singleComponent.SumAssured__c = Decimal.valueOf(cmp.SumAssured.value);
                            }
                            singleComponent.MedicalLoading__c = Decimal.valueOf(cmp.MUWLoadingPercent.value);
                            singleComponent.PremiumBeforeAllDiscount__c = Decimal.valueOf(cmp.PremiumBeforeAllDiscount.value);
                            singleComponent.PremiumAfterAllDiscount__c = Decimal.valueOf(cmp.PremiumAfterAllDiscount.value);
                            singleComponent.RiskGroup__c = cmp.RiskGroup;
                        }
                    }
                } else {
                    for (VPMSInitProductResponse.cls_Component cmp : response.VpmsResponse.data.SecondInsuredPerson.Component) {
                        if (singleComponent.Code__c.equals(cmp.ComponentCode.value) && singleComponent.Selected__c) {
                            if (cmp.SumAssured != null && cmp.SumAssured.value != null) {
                                singleComponent.SumAssured__c = Decimal.valueOf(cmp.SumAssured.value);
                            }
                            singleComponent.MedicalLoading__c = Decimal.valueOf(cmp.MUWLoadingPercent.value);
                            singleComponent.PremiumBeforeAllDiscount__c = Decimal.valueOf(cmp.PremiumBeforeAllDiscount.value);
                            singleComponent.PremiumAfterAllDiscount__c = Decimal.valueOf(cmp.PremiumAfterAllDiscount.value);
                            singleComponent.RiskGroup__c = cmp.RiskGroup;
                        }
                    }
                }
            }
        }
        if (hasChildren) {
            Integer index = 0;
            for (ChildWrapper wrap : childrenWrappers) {
                List<VPMSInitProductResponse.cls_Component> childComponents = response.VpmsResponse.data.Children[index].Component;
                for (Component__c c : wrap.components) {
                    for (VPMSInitProductResponse.cls_Component comp : childComponents) {
                        if (c.Code__c == comp.ComponentCode.value && comp.ComponentSelected.value == '1') {
                            System.debug('comp ' + comp);
                            c.SumAssured__c = Decimal.valueOf(comp.SumAssured.value);
                            c.MedicalLoading__c = Decimal.valueOf(comp.MUWLoadingPercent.value);
                            c.PremiumBeforeAllDiscount__c = Decimal.valueOf(comp.PremiumBeforeAllDiscount.value);
                            c.PremiumAfterAllDiscount__c = Decimal.valueOf(comp.PremiumAfterAllDiscount.value);
                        }
                    }
                }
                index++;
            }
        }
        VPMSInitProductResponse.cls_rows[] warnings = response.VpmsResponse.calc.Product.Warnings.rows;
        if (warnings != null) {
            for (VPMSInitProductResponse.cls_rows row : warnings) {
                warningMessages.add(row.col2);
            }
        }
        VPMSInitProductResponse.cls_rows[] infos = response.VpmsResponse.calc.Product.Infos.rows;
        if (infos != null) {
            for (VPMSInitProductResponse.cls_rows row : infos) {
                infoMessages.add(row.col2);
            }
        }
        VPMSInitProductResponse.cls_rows[] errors = response.VpmsResponse.calc.Product.Errors.rows;
        if (errors != null) {
            for (VPMSInitProductResponse.cls_rows row : errors) {
                errorMessages.add(row.col2);
            }
        }
        VPMSInitProductResponse.cls_rows[] autoCorrect = response.VpmsResponse.calc.Product.Autocorrect.rows;
        if (autoCorrect != null) {
            for (VPMSInitProductResponse.cls_rows row : autoCorrect) {
                autoCorrectMessages.add(row.col2);
            }
        }

        values.put('totalPremium', Decimal.valueOf(response.VpmsResponse.calc.Product.TotalPremiumAfterDiscounts.value));
        values.put('groupDiscount', Decimal.valueOf(response.VpmsResponse.calc.Product.GroupDiscount.value));
        values.put('frequencyDiscount', Decimal.valueOf(response.VpmsResponse.calc.Product.FrequencyDiscount.value));
        values.put('calculatedClient', Decimal.valueOf(response.VpmsResponse.calc.Product.CalculatedClientPremium.value));
        values.put('calculatedEmployer', Decimal.valueOf(response.VpmsResponse.calc.Product.CalculatedEmployerPayment.value));
        values.put('riskDiscount', Decimal.valueOf(response.VpmsResponse.calc.Product.RiskDiscount.value));
        values.put('paymentFrequency', response.VpmsResponse.data.Product.PaymentFrequency.value);
        values.put('variant', response.VpmsResponse.data.Product.ProductVariant.value);
        values.put('componentsDeath', components.get('death'));
        values.put('componentsLong', components.get('longTerm'));
        values.put('componentsShort', components.get('shortTerm'));
        values.put('errorMessages', errorMessages);
        values.put('infoMessages', infoMessages);
        values.put('warningMessages', warningMessages);
        values.put('autoCorrectMessages', autoCorrectMessages);
        values.put('vpmsRequest', serializedRequest);
        values.put('childrenWrappers', childrenWrappers);
        System.debug('recalculateRiders vracim ' + JSON.serialize(values));
        return JSON.serialize(values);
    }

    @AuraEnabled
    public static List<ChildWrapper> initChildren(List<ChildWrapper> children, List<Component__c> childrenComponents) {
        if (children == null) {
            children = new List<ChildWrapper>();
        }
        ChildWrapper acc = new ChildWrapper();
        acc.components = new List<Component__c>();
        acc.components.addAll(childrenComponents);
        children.add(acc);
        return children;
    }

    @AuraEnabled
    public static List<ChildWrapper> addNextChild(List<ChildWrapper> children, String childrenComponents) {
        Component__c[] childComponents = (List<Component__c>) System.JSON.deserializeStrict(childrenComponents, List<Component__c>.Class);
        if (children != null && !children.isEmpty()) {
            ChildWrapper acc = new ChildWrapper();
            acc.components = new List<Component__c>();
            acc.components.addAll(childComponents);
            children.add(acc);
        }
        return children;
    }

    @AuraEnabled
    public static List<Account> removeChild(List<Account> children) {
        if (children != null && children.isEmpty()) {
            Account acc = new Account();
            children.add(acc);
        }
        return children;
    }

    public class ChildWrapper {
        @AuraEnabled
        public Account acc {
            get;
            set;
        }

        @AuraEnabled
        public NNRelationship__c rel {
            get;
            set;
        }

        @AuraEnabled
        public String firstName {
            get;
            set;
        }

        @AuraEnabled
        public String lastName {
            get;
            set;
        }

        @AuraEnabled
        public String birthDate {
            get;
            set;
        }

        @AuraEnabled
        public List<Component__c> components {
            get;
            set;
        }

        public ChildWrapper() {

        }

        public ChildWrapper(String firstName, String lastName, String birthDate, List<Component__c> components) {
            this.firstName = firstName;
            this.lastName = lastName;
            this.birthDate = birthDate;
            this.components = components;
        }

        public ChildWrapper(Account acc, NNRelationship__c rel, String firstName, String lastName, String birthDate, List<Component__c> components) {
            this.acc = acc;
            this.rel = rel;
            this.firstName = firstName;
            this.lastName = lastName;
            this.birthDate = birthDate;
            this.components = components;
        }
    }

    public class PicklistOption {

        @AuraEnabled
        public String label {
            get;
            set;
        }

        @AuraEnabled
        public String value {
            get;
            set;
        }

        @AuraEnabled
        public Boolean selected {
            get;
            set;
        }

        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }

        public PicklistOption(String label, String value, Boolean selected) {
            this.label = label;
            this.value = value;
            this.selected = selected;
        }

    }
}