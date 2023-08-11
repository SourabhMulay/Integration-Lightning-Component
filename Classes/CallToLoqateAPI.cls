public with sharing class CallToLoqateAPI {

   public class customDataType{

        public customDataType(String street,String postalCode, String countrycode,String statecode,String city,Boolean yesEmpty){
             this.street=street;
             this.postalcode=postalCode;
             this.countrycode=countrycode;
             this.statecode=statecode;
             this.city=city;
             this.isEmpty=yesEmpty;
         }
         public String street;
         public String postalcode;
         public String countrycode;
         public String statecode;
         public String city;
         public Boolean isEmpty;
     }

     @AuraEnabled
     public static string GetCountryCodeOfAccountAndLead(String accId){
        try {
            if(accID.length()>0){
                Account a=[select Id, BillingCountryCode from Account where Id=:accID];
                customDataType c=new customDataType('','',a.BillingCountryCode,'','',false);
                String s=JSON.serialize(c);
                return s;
            }
            return NULL;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
     }
    
    @AuraEnabled(cacheable=true)
    public static String GetAddress(String Text,String Country){
        try {

            String encodedText = EncodingUtil.urlEncode(Text, 'UTF-8');
            String encodedCountry = EncodingUtil.urlEncode(Country, 'UTF-8');
            CustomAPIDetails__mdt Loqate=[select APIKey__c,MethodType__c,APIValue__c,EndpointURL__c,Limit__c,MasterLabel from CustomAPIDetails__mdt where MasterLabel='LoqateFindAPI'];
            String URL=Loqate.EndpointURL__c+Loqate.APIKey__c+'='+Loqate.APIValue__c+'&Text='+encodedText+'&Countries='+encodedCountry+'&Limit='+Loqate.Limit__c;
            system.debug(URL);
            String Data=APICallouts.GetCallout(URL,Loqate.MethodType__c);
            return Data;

        } catch (Exception e) {
           throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static string GetAddressData(String ID,String UserSelectedText,String Country){

        try {
            
            String encodedText = EncodingUtil.urlEncode(UserSelectedText, 'UTF-8');
            String encodedCountry = EncodingUtil.urlEncode(Country, 'UTF-8');
            CustomAPIDetails__mdt Loqate=[select APIKey__c, MethodType__c,APIValue__c,EndpointURL__c,Limit__c,MasterLabel from CustomAPIDetails__mdt where MasterLabel='LoqateFindAPI'];
            UserSelectedText=UserSelectedText.replaceAll(' ','');
            system.debug(UserSelectedText);
            String URL= Loqate.EndpointURL__c+Loqate.APIKey__c+'='+Loqate.APIValue__c +'&Text='+encodedText+'&Countries='+encodedCountry+'&container='+ID+'&Limit='+Loqate.Limit__c;
            String URL1=URL.trim();
            String Data=APICallouts.GetCallout(URL,Loqate.MethodType__c);
            return Data;
            
        } catch (Exception e) {

            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static string GetExtraEndAddress(String Id){
        try {
            
            CustomAPIDetails__mdt Loqate=[select APIKey__c, MethodType__c,APIValue__c,EndpointURL__c,Limit__c,MasterLabel from CustomAPIDetails__mdt where MasterLabel='LoqateFindRETRIEVE'];
            
            String URL=Loqate.EndpointURL__c+Loqate.APIKey__c+'='+Loqate.APIValue__c+'&Id='+Id;

            String Data=APICallouts.GetCallout(URL,Loqate.MethodType__c);
            return Data;
            
        } catch (Exception e) {
        
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string CreateCustomerAddress(String lqtId,String accID,String city, String street, String postalCode,String country,String provience,String BuildingNumber){
        try {
            CustomerAddress__c c=new CustomerAddress__c();
            c.Account__c=accID;

            c.Address__CountryCode__s= country;
            c.Address__StateCode__s=provience;
            c.Address__PostalCode__s=postalCode;
            c.Address__City__s=city;
            c.Address__Street__s=street;
            c.Active__c=true;
            c.LoqateId__c=lqtId;
            c.RestrictedPartyScreening__c='Passed';
            system.debug(c);
            insert c;
            return c.ID;
        }catch (DMLException e) {
        
            throw new AuraHandledException(e.getDMLMessage(0));
            
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string UpdateLeadAddress(String LoqateId,String LeadId,String city, String street, String postalCode,String country,String address,String statecode,String BuildingNumber){
        try {

            if(address=='Main Address'){
                Lead l=[SELECT Id, Street, City, State, PostalCode, Country, StateCode, CountryCode FROM Lead Where Id=:LeadId];
                l.StateCode=statecode;
                l.City=city;
                l.Street=street;
                l.PostalCode=postalCode;
                l.CountryCode=country;
                l.LoqateId__c=LoqateId;
                upsert l;
                return l.Id;

            }
            else if(address=='Extra Address'){
                Lead l=[SELECT Id,	LoqateIdExtraAddress__c, ExtraAddress__Street__s, ExtraAddress__City__s, ExtraAddress__StateCode__s, ExtraAddress__PostalCode__s, ExtraAddress__CountryCode__s FROM Lead Where Id=:LeadId];
                l.ExtraAddress__City__s=city;
                l.ExtraAddress__CountryCode__s=country;
                l.ExtraAddress__PostalCode__s=postalCode;
                l.ExtraAddress__StateCode__s=statecode;
                l.ExtraAddress__Street__s=street;
                l.LoqateIdExtraAddress__c=LoqateId;
                upsert l;
                return l.Id;
            }

            return NULL;
        }catch (DMLException e) {
            throw new AuraHandledException(e.getDMLMessage(0));
            
        } 
         catch (Exception e) {
            system.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getLeadAddress(string recordID,string address){
            Boolean isEmpty=false;

            Lead l=[SELECT Id, Street, City, State, PostalCode, Country, StateCode, CountryCode, ExtraAddress__Street__s, ExtraAddress__City__s, ExtraAddress__StateCode__s, ExtraAddress__PostalCode__s, ExtraAddress__CountryCode__s FROM Lead Where Id=:recordID];
            if(l.Street==null && l.State==null && l.PostalCode==null  && l.Country==null && l.StateCode==null && l.CountryCode==null && l.ExtraAddress__Street__s==null && l.ExtraAddress__City__s==null && l.ExtraAddress__CountryCode__s==null && l.ExtraAddress__PostalCode__s==null && l.ExtraAddress__StateCode__s==null){
                isEmpty=true;
                customDataType c=new customDataType(l.Street, l.postalCode, l.CountryCode, l.State, l.City,isEmpty);
                return JSON.serialize(c);
            }

            if(address=='Main Address'){
                customDataType c=new customDataType(l.Street, l.postalCode, l.CountryCode, l.State, l.City,isEmpty);
                String s=JSON.serialize(c);
                return s;
            }
            else if(address=='Extra Address'){
                customDataType c=new customDataType(l.ExtraAddress__Street__s, l.ExtraAddress__PostalCode__s, l.ExtraAddress__CountryCode__s, l.ExtraAddress__StateCode__s, l.ExtraAddress__City__s,isEmpty);
                String s=JSON.serialize(c);
                return s;
            }
            return NULL;
       
    }

}

//Class APICALLOUTS

public with sharing class APICallouts {

    public static String GetCallout(String URL,String MethodType){
        try{
    
        HttpRequest rqt=new HttpRequest();
        rqt.setEndpoint(URL);
        rqt.setMethod(MethodType);
        HttpResponse res = new Http().send(rqt);
        system.debug('Body and Code'+res.getStatusCode()+res.getBody());
        if(res.getStatusCode()==200){
            return res.getBody();

        }else{
            throw new CalloutException('HTTP Callout failed with status code: ' + res.getStatusCode() + ' and response body: ' + res.getBody());
        }

    }
    catch(Exception e){
        throw new CalloutException('HTTP Callout failed: ' + e.getMessage());
        
    }
    }

}

//TEST CLASS

@isTest
public with sharing class CallToLoqateAPITestClass {
    public CallToLoqateAPITestClass() {
    }
    
     @TestSetup
    static void setupTestData(){
        
        Account a=TestDataFactory.createTestAccount();
        try{
            insert a;
        }catch(Exception e){
            system.debug(e.getMessage());
        }    
     
        Lead L = TestDataFactory.createTestLeadForLoqateTestClass();
        try{
           insert L;
        }catch(Exception e){
            system.debug(e.getMessage());
        }
    }
   
 
     @isTest
    static void TestGetCountryCodeOfAccountAndLead() {
        system.Test.startTest();
        Account a=[select Id, Name from Account where Name='Test Account' LIMIT 1];
        CallToLoqateAPI.customDataType DS=new CallToLoqateAPI.customDataType('','','IN','','',false);
        String str=JSON.serialize(DS);
        String result=CallToLoqateAPI.GetCountryCodeOfAccountAndLead(a.Id);
        String result1=CallToLoqateAPI.GetCountryCodeOfAccountAndLead('');
        try{
        String result2=CallToLoqateAPI.GetCountryCodeOfAccountAndLead('0012312313123');
        }catch(Exception e){
            system.debug(e.getMessage());
        }
        system.assertEquals(str,result,'Fail');
        system.Test.stopTest();
    }   
    
     @isTest
    static void TestGetAddress() {
        system.Test.startTest();
        String Text='Pastoriestraat 11 3128 Tremelo';
       	HttpMockFactory Mock=new HttpMockFactory(200,'Ok','{"Items":[{"Id":"BE|LP|B|2106438|11_DUT","Type":"Address","Text":"Pastoriestraat 11 3128 Tremelo","Highlight":"0-14,15-17,18-22,23-30","Description":""}]}',new Map<String,String>());
        system.Test.setMock(HttpCalloutMock.class, Mock);
        String result = CallToLoqateAPI.GetAddress(Text,'BE');
        String expectedResult = '{"Items":[{"Id":"BE|LP|B|2106438|11_DUT","Type":"Address","Text":"Pastoriestraat 11 3128 Tremelo","Highlight":"0-14,15-17,18-22,23-30","Description":""}]}';
        System.assertEquals(expectedResult, result, 'HTTP callout result is incorrect.');
        Account a=new Account(Name='Sa');
        insert a;
        HttpMockFactory Mock1=new HttpMockFactory(500,'Ok','Exception',new Map<String,String>());
        system.Test.setMock(HttpCalloutMock.class, Mock);
        try{
        String result_Exception = CallToLoqateAPI.GetAddress(Text,'BE');
        }catch(Exception e){
            system.debug(e.getMessage());
        }
        system.Test.stopTest();
    }
    
     @isTest
    static void TestGetExtraEndAddressData() {
        system.Test.startTest();
        HttpMockFactory Mock=new HttpMockFactory(200,'Ok','{"Items":[{"Id":"BE|LP|B|2106438|11_DUT","DomesticId":"2106438","Language":"DUT","LanguageAlternatives":"DUT","BuildingNumber":"11","Street":"Pastoriestraat","District":"Baal","City":"Tremelo","Line1":"Pastoriestraat 11","Line2":"Baal","AdminAreaName":"Leuven","Province":"Vlaams Brabant","PostalCode":"3128","CountryName":"Belgium","CountryIso2":"BE","CountryIso3":"BEL","CountryIsoNumber":"056"',new Map<String,String>());
        system.Test.setMock(HttpCalloutMock.class, Mock);
        String Id='BE|LP|B|2106438|11_DUT';
        String result = CallToLoqateAPI.GetExtraEndAddress(Id);
        String expectedResult = '{"Items":[{"Id":"BE|LP|B|2106438|11_DUT","DomesticId":"2106438","Language":"DUT","LanguageAlternatives":"DUT","BuildingNumber":"11","Street":"Pastoriestraat","District":"Baal","City":"Tremelo","Line1":"Pastoriestraat 11","Line2":"Baal","AdminAreaName":"Leuven","Province":"Vlaams Brabant","PostalCode":"3128","CountryName":"Belgium","CountryIso2":"BE","CountryIso3":"BEL","CountryIsoNumber":"056"';
        System.assertEquals(expectedResult, result, 'HTTP callout result is incorrect.');
        String result_fail = CallToLoqateAPI.GetExtraEndAddress('');
        
        Account a=new Account(Name='Sa');
        insert a;
        HttpMockFactory Mock1=new HttpMockFactory(500,'Ok','{"Items":[{"Id":"BE|LP|B|2106438|11_DUT","DomesticId":"2106438","Language":"DUT","LanguageAlternatives":"DUT","Department":"","Company":"","SubBuilding":"","BuildingNumber":"11","BuildingName":"","SecondaryStreet":"","Street":"Pastoriestraat","Block":"","Neighbourhood":"","District":"Baal","City":"Tremelo","Line1":"Pastoriestraat 11","Line2":"Baal","Line3":"","Line4":"","Line5":"","AdminAreaName":"Leuven","AdminAreaCode":"","Province":"Vlaams Brabant","ProvinceName":"Vlaams Brabant","ProvinceCode":"","PostalCode":"3128","CountryName":"Belgium","CountryIso2":"BE","CountryIso3":"BEL","CountryIsoNumber":"056","SortingNumber1":"","SortingNumber2":"","Barcode":"","POBoxNumber":"","Label":"Pastoriestraat 11\n3128  TREMELO\nBELGIUM","Type":"Unknown","DataLevel":"Premise","Field1":"","Field2":"","Field3":"","Field4":"","Field5":"","Field6":"","Field7":"","Field8":"","Field9":"","Field10":"","Field11":"","Field12":"","Field13":"","Field14":"","Field15":"","Field16":"","Field17":"","Field18":"","Field19":"","Field20":""}]',new Map<String,String>());
        system.Test.setMock(HttpCalloutMock.class, Mock1);
        try{
        String result_Exception = CallToLoqateAPI.GetExtraEndAddress(Id);
        }catch(Exception e){
            system.debug(e.getMessage());
        }
        
        system.Test.stopTest();
        
    }
    @isTest
     static void TestGetAddressData() {
        system.Test.startTest();
        HttpMockFactory Mock=new HttpMockFactory(200,'Ok','{"Items":[{"Id":"BE|LP|B|1448215|2_DUT","Type":"Address","Text":"Pastoor Hermansstraat 2 3668 As","Highlight":"","Description":""}',new Map<String,String>());
        system.Test.setMock(HttpCalloutMock.class, Mock);
        String Text='Pastoor Hermansstraat 3668 As';
        String Id='be-lp|4-Ibl4kBX8V_g8REvcdY';
        String result = CallToLoqateAPI.GetAddressData(Id,Text,'BE');
        result=result.trim();
        String expectedResult = '{"Items":[{"Id":"BE|LP|B|1448215|2_DUT","Type":"Address","Text":"Pastoor Hermansstraat 2 3668 As","Highlight":"","Description":""}';
        expectedResult=expectedResult.trim();
        System.assertEquals(expectedResult, result, 'HTTP callout result is incorrect.');
        
        //perform DML to throw exception
        Account a=new Account(Name='SS');
        insert a;
         try{
        	String result_fail = CallToLoqateAPI.GetAddressData(Id,Text,'BE');
         }Catch(exception e){
             system.debug(e.getMessage());
         }
        system.Test.stopTest();
    }

    @isTest static void TestCustomerAddressCreation(){
        system.Test.startTest();
        Account a=[select Id, Name, BillingCountryCode from Account where Name='Test Account' and BillingCountryCode='IN' LIMIT 1 ];
       
        String Result=CallToLoqateAPI.CreateCustomerAddress('',a.Id,'ABC123','ABC Nes-123 STreet','412412','IN','GJ','');
        system.debug('Result of Customer address'+Result);
        try{
        String Result_fail=CallToLoqateAPI.CreateCustomerAddress('','','','','','','','');
        }catch(Exception e){
            system.debug(e.getMessage());
        }
        system.Test.stopTest();
    }
    @isTest static void TestLeadUpdate(){
        system.test.startTest();
        String state='MH', country='IN', street='Test Street' , postalcode='12345', city='Vizag';

        Lead L=[select Id, LastName,Company,CountryCode,Phone from Lead where CountryCode='IN' AND Company='TestCompany' AND LastName='TestData' LIMIT 1];
        String LId=L.Id;
        //success;

        //Test Main Address
        String Result=CallToLoqateAPI.UpdateLeadAddress('',LId,city,street,postalcode,country,'Main Address',state,'');
  		String Result_ExtraAddress=CallToLoqateAPI.UpdateLeadAddress('',LId,city,street,postalcode,'BE','Extra Address','','');
        try{
        	String Result_fail=CallToLoqateAPI.UpdateLeadAddress('',LId,'','','','','Main Address','','');
        }catch(AuraHandledException E){
        	system.debug(E.getMessage());
        }
        //No address
        String Result_NoAddress=CallToLoqateAPI.UpdateLeadAddress('',LId,city,street,postalcode,country,'',state,'');     
        System.assertEquals(null,Result_NoAddress );
        
        system.test.stopTest();
    }

    @isTest static void TestGetLeadAddress(){
        system.test.startTest();
        String state='MH', country='IN', street='Test Street' , postalcode='12345', city='Vizag';

        Lead L=[select Id, LastName,Company,CountryCode,Phone from Lead where CountryCode='IN' AND Company='TestCompany' LIMIT 1];
        L.ExtraAddress__CountryCode__s='BE';
        try{
            update L;
            
        }
        catch(Exception e){
            system.debug(e.getMessage());
        }
        String LId=L.Id;
        String result=CallToLoqateAPI.getLeadAddress(LId,'Main Address');
        String result_ExtraAddress=CallToLoqateAPI.getLeadAddress(LId,'Extra Address');
        
        CallToLoqateAPI.customDataType DS=new CallToLoqateAPI.customDataType(null,null,'IN',null,null,false);
        String Str=JSON.serialize(DS);
        System.assertEquals(Str, result, 'The result is incorrect.'); 

        CallToLoqateAPI.customDataType DS_1=new CallToLoqateAPI.customDataType(null,null,'BE',null,null,false);
        String Str_1=JSON.serialize(DS_1);
        System.assertEquals(Str_1, result_ExtraAddress, 'The result is incorrect.'); 

        //Null Check
        String result_NULL=CallToLoqateAPI.getLeadAddress(LId,'');
        System.assertEquals(result_NULL,NULL);
        system.test.stopTest();
    }

    
    
}
