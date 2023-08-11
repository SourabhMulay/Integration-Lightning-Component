import { LightningElement,track,api,wire } from 'lwc';
import GetAddress from '@salesforce/apex/CallToLoqateAPI.GetAddress';
import GetAddressData from '@salesforce/apex/CallToLoqateAPI.GetAddressData';
import GetExtraEndAddress from '@salesforce/apex/CallToLoqateAPI.GetExtraEndAddress';
import GetCountryCodeOfAccountAndLead from '@salesforce/apex/CallToLoqateAPI.GetCountryCodeOfAccountAndLead';
import { createRecord } from 'lightning/uiRecordApi';
import CustomerAddress from '@salesforce/schema/CustomerAddress__c'; 
import { CloseActionScreenEvent } from 'lightning/actions';
import Case from '@salesforce/schema/Case';
import LEAD from '@salesforce/schema/Lead';
import COUNTRY from '@salesforce/schema/Case.Country__c';
import StateCode from '@salesforce/schema/Lead.StateCode';
import { getObjectInfo, getPicklistValues, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import Address__CountryCode__s from '@salesforce/schema/CustomerAddress__c.Address__c';
import CreateCustomerAddress from '@salesforce/apex/CallToLoqateAPI.CreateCustomerAddress';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import UpdateLeadAddress from '@salesforce/apex/CallToLoqateAPI.UpdateLeadAddress';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import BillingCountryCode from '@salesforce/schema/Account.BillingCountryCode';
import LEAD_ADDRESS_FIELD from '@salesforce/schema/Lead.Address';
import getLeadAddress from '@salesforce/apex/CallToLoqateAPI.getLeadAddress';
import { NavigationMixin } from 'lightning/navigation';

export default class Loquate extends LightningElement {
@api cache={};
@api recordId="";  
@api NavigationID="";
@track ShowData=false;
@track showAddress=false;
@api stateMap;
@track leadAddressToShow="";
@track address;
@track EndAddress={};
@track SelectedValue="";
@track selectedCounrtryOptions="";
@track popUp=true;
@track isEmpty=false;
@track RenderList=[];
@track RenderList_Address=[];
@track LINE="";
@track AddressToShow="";
@track Fdata={};
@api fetchedData;
@api accObj={};
@track SelectedID="";
@api picklistValues;
@api CaseData;
@api accID="";
@track IsAccId=false;
@track countryOptions;
@track SelectedAddressText;
@track addressId="";
@track LeadId;
@track IsLeadId=false;
@track EndAddress1={};
@track mainAddress=false;
@track ExtraAddress=false;
@track selectedLeadAddress="";

@track LeadAddress=[
    {
        label:'Main Address',
        value:'Main Address'
    },
    {
        label:'Extra Address',
        value:'Extra Address'
    }
]

@wire(CurrentPageReference)
getStateParameters(currentPageReference) {
    console.log('Current Page reference-->',currentPageReference);
    console.log('currentpage',currentPageReference.state.recordId);
    const PageOBJ=currentPageReference;
    console.log('page referance',PageOBJ);
    this.recordId=PageOBJ.state.recordId;
    if(this.recordId.startsWith('001')){
        this.accID=this.recordId;
        this.IsAccId=true;
        GetCountryCodeOfAccountAndLead({'accId':this.accID}).then((res)=>{
            const AObj=JSON.parse(res);
            this.selectedCounrtryOptions=AObj.countrycode?AObj.countrycode:'';
        })
    }
    else if(this.recordId.startsWith('00Q')){
        this.LeadId=this.recordId;
        this.IsLeadId=true;
        if(this.LeadId.length!=0){
         getLeadAddress({'recordID':this.LeadId, 'address':'Main Address'}).then((response)=>{
            const adData=JSON.parse(response);
            console.log('Null data from lead',adData)
            if(adData.isEmpty){
                this.isEmpty=true;
            }
        })
    }       
    }
}

get handleExistingAddresssLogic(){
    return (this.IsLeadId && !this.isEmpty);
}
LeadAddressChangeHandler(e){
    this.selectedLeadAddress=e.detail.value;
    if(this.selectedLeadAddress=='Main Address'){
        this.mainAddress=true;
        this.ExtraAddress=false;   
    }
    else if(this.selectedLeadAddress=='Extra Address'){
        this.ExtraAddress=true;
        this.mainAddress=false;
    }
    if(this.LeadId.length!=0){
        const args={
            'recordID':this.LeadId,
            'address':this.selectedLeadAddress
        }
        getLeadAddress(args).then((response)=>{
            console.log('response from lead address call',response);
            this.leadAddressToShow=JSON.parse(response);
            console.log('Leadaddresstoshow',this.leadAddressToShow);
            this.selectedCounrtryOptions=this.leadAddressToShow.countrycode?this.leadAddressToShow.countrycode:'';
            this.CountryChangeHandler();
        }).catch(()=>{
            console.log('Failed to fetch lead ADDRESS');
        })
    }
}

    constructor(){
        super();  
    }

    @wire(getObjectInfo, { objectApiName: Case })
    CaseData;

    @wire(getPicklistValues, { recordTypeId:'$CaseData.data.defaultRecordTypeId',fieldApiName:COUNTRY })
    getPickValCountry({data, error}){
        if(data){
            this.GenerateCountryPicklist(data);    
        }
    }

    @wire(getObjectInfo, { objectApiName: LEAD })
    LeadData;

    @wire(getPicklistValues, { recordTypeId:'$LeadData.data.defaultRecordTypeId',fieldApiName:StateCode })
    getPickValState({data, error}){
        if(data){
           this.GenerateStateMap(data.values);
            
        }
    }
    
    GenerateCountryPicklist(data){
        console.log('Data',data);
        if(data){
            this.picklistValues=data.values.map((ele)=>{
                return{
                    label:ele.label,
                    value:ele.value
                }
            });
        }
        this.countryOptions=this.picklistValues;
    }


    GenerateStateMap(data){
        if(data){
            this.stateMap=new Map();
            data.map((ele)=>{
                const stateLabel=ele.label.replace(/[^A-Za-z]/g, '');
                this.stateMap.set(stateLabel,ele.value);
            })
            console.log('Map of States',this.stateMap);
        }
    }


    get checkSelectedCountryOption(){
        if(this.selectedCounrtryOptions.length!=0){
            return false;
        }
        return true;
    }

UpdateLeadHandler(e){
    const val=this.countryOptions.map((item)=>item.value==this.selectedCounrtryOptions);
    this.ShowAfterSave=true;
    if(this.addressId.length!=0){
        GetExtraEndAddress({'Id':this.addressId}).then((Respose)=>{
            const DT=JSON.parse(Respose);
            this.EndAddress=DT.Items;
            let getStateCode;
            let Line1=this.EndAddress[0].Line1?this.EndAddress[0].Line1+'\n':'';
            let Line2=this.EndAddress[0].Line2?this.EndAddress[0].Line2+'\n':'';
            let Line3=this.EndAddress[0].Line3?this.EndAddress[0].Line3+'\n':'';
            let Line4=this.EndAddress[0].Line4?this.EndAddress[0].Line4+'\n':'';
            this.LINE=Line1+Line2+Line3+Line4;
            if(this.EndAddress[0].ProvinceCode.length!=0){
                getStateCode=this.EndAddress[0].ProvinceCode;
            }
            else{
            getStateCode=this.stateMap.get(this.EndAddress[0].Province.replace(/[^A-Za-z]/g, ''));
            }
            const LeadObj={
                'LoqateId':this.addressId,
                'LeadId':this.LeadId,
                'city':this.EndAddress[0].City,
                'street':this.LINE,
                'postalCode':this.EndAddress[0].PostalCode,
                'country':this.EndAddress[0].CountryIso2,
                'address':this.selectedLeadAddress? this.selectedLeadAddress:'Main Address',
                'statecode':getStateCode,
                'BuildingNumber':this.EndAddress[0].BuildingNumber
            }
            UpdateLeadAddress(LeadObj).then((ID)=>{
                const event = new ShowToastEvent({
                    title: 'Success',
                    message: 'Record Address Updated successfully',
                    variant: 'success'
                });
                this.dispatchEvent(event);
                setTimeout(()=>{
                    this.HandleClose();
                    setTimeout(()=>{
                        window.location.reload();
                    },2000)
                },3000)
            }).catch((e)=>{
                const event = new ShowToastEvent({
                    mode: 'sticky',
                    title: 'Error',
                    message: e.body.message,
                    variant: 'error'
                });
                this.dispatchEvent(event);
            })
        })
    }
}

CallForAddress(){
    if(this.SelectedID.length!=0 && this.SelectedValue.length!=0 && this.selectedCounrtryOptions.length!=0 && this.addressId.length==0){
        GetAddressData({'ID':this.SelectedID, 'UserSelectedText':this.SelectedValue,'Country':this.selectedCounrtryOptions}).then((Response)=>{
            this.Fdata=JSON.parse(Response);
            this.RenderList_Address=this.Fdata.Items;
        }).catch(()=>{throw new Error('Bad Request');})
    }
}

addressSelectHandler(e){
    this.SelectedAddressText=e.target.textContent;
    this.AddressToShow=e.target.textContent;
    this.address=e.target.textCotent;
    this.addressId=e.target.dataset.key;
    this.addressId=JSON.stringify(this.addressId).replaceAll('"','');
    this.RenderList_Address=[];
    this.CallForRetrive();
}


 CountryChangeHandler(e){
    this.selectedCounrtryOptions=e.detail.value;
    this.AddressToShow="";
    this.RenderList=[];
    this.RenderList_Address=[];
    this.showAddress=false;
}

SelectHandler(e){
    this.SelectedValue = e.target.textContent;
    const index=e.target.dataset.index;
    const OBJ=this.RenderList[index];
    if(OBJ.Type=='Address'){
        this.addressId=OBJ.Id;
        this.SelectedAddressText=OBJ.Text;
        this.CallForRetrive();
    }
    this.AddressToShow=e.target.textContent;
    this.address=this.SelectedValue;
    this.SelectedID=e.target.dataset.key;
    this.SelectedID=JSON.stringify(this.SelectedID).replaceAll('"','');
    this.RenderList=[];
    this.CallForAddress();
}

CallForRetrive(){
    if(this.addressId.length!=0){
        this.showAddress=true;
        GetExtraEndAddress({'Id':this.addressId}).then((response)=>{
            const DT=JSON.parse(response);
            this.EndAddress=DT.Items[0];
            let Line1=this.EndAddress.Line1?this.EndAddress.Line1+'\n':'';
            let Line2=this.EndAddress.Line2?this.EndAddress.Line2+'\n':'';
            let Line3=this.EndAddress.Line3?this.EndAddress.Line3+'\n':'';
            let Line4=this.EndAddress.Line4?this.EndAddress.Line4+'\n':'';
            this.LINE=Line1+Line2+Line3+Line4;
            this.EndAddress1=this.EndAddress;
        })
    }
    else{
        const event=new ShowToastEvent({
            title:'Validate With Correct Address',
            message:'select the address from list to improve search.',
            varient:'error'
        })
        this.dispatchEvent(event);
    }
}

get CreateButtonHiddenLogic(){
    if(this.accID.length!=0){
    return ((!this.IsLeadId) && (!this.showAddress))?true:false;
    }
    else{
        return true;
    }
}

get LeadLogic(){
    if(this.showAddress){
        return false;
    }
    else{
        return true;
    }
}

Navigate(){
    var LINK=window.location.href.split('/')[2];
    var Proto="https://";
    var URL=Proto+LINK+'/lightning/r/CustomerAddress__c/'+this.NavigationID+'/view';
    setTimeout(()=>{
        window.open(URL,'_self');
    },5000)
}

saveHandler(){
    const val=this.countryOptions.map((item)=>item.value==this.selectedCounrtryOptions);
    if(this.addressId.length!=0){
        GetExtraEndAddress({'Id':this.addressId}).then((Respose)=>{
            const DT=JSON.parse(Respose);
            this.EndAddress=DT.Items;
            let getStateCode;
            let Line1=this.EndAddress[0].Line1?this.EndAddress[0].Line1+'\n':'';
            let Line2=this.EndAddress[0].Line2?this.EndAddress[0].Line2+'\n':'';
            let Line3=this.EndAddress[0].Line3?this.EndAddress[0].Line3+'\n':'';
            let Line4=this.EndAddress[0].Line4?this.EndAddress[0].Line4+'\n':'';
            this.LINE=Line1+Line2+Line3+Line4;
            if(this.EndAddress[0].ProvinceCode.length!=0){
                getStateCode=this.EndAddress[0].ProvinceCode;
            }
            else{
            getStateCode=this.stateMap.get(this.EndAddress[0].Province.replace(/[^A-Za-z]/g, ''));
            }

            this.accObj={
                'lqtId':this.EndAddress[0].Id,
                'accID':this.accID,
                'city':this.EndAddress[0].City,
                'street':this.LINE,
                'postalCode':this.EndAddress[0].PostalCode,
                'country':this.EndAddress[0].CountryIso2,
                'provience':getStateCode,
                'BuildingNumber':this.EndAddress[0].BuildingNumber,
            }
            CreateCustomerAddress(this.accObj).then((ID)=>{
                console.log("IDDD",ID);
                this.NavigationID=ID;
                const event = new ShowToastEvent({
                    title: 'Success',
                    message: 'Record created successfully  '+ID,
                    variant: 'success'
                });
                this.dispatchEvent(event);
                setTimeout(()=>{
                    this.HandleClose();
                },4000)  
                setTimeout(() => {
                    this.Navigate();
                }, 1000);

            }).catch((e)=>{
                
                const event = new ShowToastEvent({
                    mode: 'sticky',
                    title: 'Error',
                    message: e.body.message,
                    variant: 'error'
                });
                this.dispatchEvent(event);
            })
        }).catch(()=>console.log('Fail to fetch data')) 
    }
}

InputOnchange_Paste(e){
    this.address=e.clipboardData.getData('text');
    this.showAddress=false;
    this.EndAddress1={};
    if(this.address==''){
        this.RenderList=[];
        this.RenderList_Address=[];
    }
    this.addressId="";
    let ad=this.address;
    if(this.selectedCounrtryOptions.length!=0){
       GetAddress({'Text':this.address,'Country':this.selectedCounrtryOptions}).then((Response)=>{
        this.Fdata=JSON.parse(Response);
        this.RenderList=this.Fdata.Items;
       }).catch((Error)=>{
        throw new Error('Failed to Fetch');
       })        
    }
}

InputOnchange(e){ 
    this.address=e.detail.value;
    this.showAddress=false;
    this.EndAddress1={};
    this.addressId="";
    if(this.address==''){
        this.RenderList=[];
        this.RenderList_Address=[];
    }
    let ad=this.address;
    //this.address=this.address.replaceAll(' ','');
    if((this.address.length)%3===0 && this.selectedCounrtryOptions.length!=0){
       GetAddress({'Text':this.address,'Country':this.selectedCounrtryOptions}).then((Response)=>{
        this.Fdata=JSON.parse(Response);
        this.RenderList=this.Fdata.Items;
       }).catch((Error)=>{
        throw new Error('Failed to Fetch');
       })        
    }
}

HandleClose(){
    this.popUp=false;
    this.selectedCounrtryOptions="";
    this.SelectedValue="";
    this.SelectedID="";
    this.EndAddress1={};
    this.Fdata={};
    this.LINE="";
    this.address="";
    this.cache={};
    this.addressId="";
    this.showAddress=false;
    this.mainAddress=false;
    this.ExtraAddress=false;
    this.ShowAfterSave=false;
    this.LeadId="";
    this.accID="";
    this.AddressToShow="";
    this.dispatchEvent(new CloseActionScreenEvent());
}

}
