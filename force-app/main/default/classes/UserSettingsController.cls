public class UserSettingsController {
	 
    @AuraEnabled(cacheable=true)
    public static Map<String,Map<String,String>> getSettingsData(){
        Map<String,Map<String,String>> mapResult = new Map<String,Map<String,String>>();
        
        Map<String,String> mapLanguage = new Map<String,String>();
        Schema.DescribeFieldResult fieldResultLanguageLocaleKey = User.LanguageLocaleKey.getdescribe();
        List<Schema.PicklistEntry> ple1 = fieldResultLanguageLocaleKey.getPicklistValues();
        for(Schema.PicklistEntry p : ple1)
        {
        	//system.debug('###'+p.getlabel()+'****'+p.getValue()+'\n');
            mapLanguage.put(p.getlabel(),p.getValue());
        }
        mapResult.put('Language',mapLanguage);
        
        Map<String,String> mapLocale = new Map<String,String>();
        Schema.DescribeFieldResult fieldResultLocaleSidKey = User.LocaleSidKey.getdescribe();
        List<Schema.PicklistEntry> ple2 = fieldResultLocaleSidKey.getPicklistValues();
        for(Schema.PicklistEntry p : ple2)
        {
        	//system.debug('###'+p.getlabel()+'****'+p.getValue()+'\n');
            mapLocale.put(p.getlabel(),p.getValue());
        }
        mapResult.put('Locale',mapLocale);
        
        Map<String,String> mapTimeZone = new Map<String,String>();
        Schema.DescribeFieldResult fieldResultTimeZoneSidKey = User.TimeZoneSidKey.getdescribe();
        List<Schema.PicklistEntry> ple3 = fieldResultTimeZoneSidKey.getPicklistValues();
        for(Schema.PicklistEntry p : ple3)
        {
        	//system.debug('###'+p.getlabel()+'****'+p.getValue()+'\n');
            mapTimeZone.put(p.getlabel(),p.getValue());
        }
        mapResult.put('TimeZone',mapTimeZone);
        
        String userId = UserInfo.getUserId();
        User currentUser = [SELECT toLabel(LanguageLocaleKey),toLabel(LocaleSidKey),toLabel(TimeZoneSidKey) FROM User WHERE id=:userId LIMIT 1];
        Map<String,String> userMap = new Map<String,String>();
        userMap.put('Language',currentUser.LanguageLocaleKey);
        userMap.put('Locale',currentUser.LocaleSidKey);
        userMap.put('TimeZone',currentUser.TimeZoneSidKey);
        mapResult.put('User',userMap);
        
        return mapResult;
    }  
    
    @AuraEnabled(cacheable=false)
    public static void setNewPassword(String newPassword){
        system.debug(newPassword);
        String userId = UserInfo.getUserId();
        System.setPassword(userId,newPassword); 
    }
    /*
    @AuraEnabled(cacheable=true)
    public static Map<String,String> getTimeZone(){
        Map<String,String> mapTimeZone = new Map<String,String>();
        Schema.DescribeFieldResult fieldResult = User.TimeZoneSidKey.getdescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry p : ple)
        {
        	//system.debug('###'+p.getlabel()+'****'+p.getValue()+'\n');
            mapTimeZone.put(p.getlabel(),p.getValue());
        }
        return mapTimeZone;
		}
    
    @AuraEnabled(cacheable=true)
    public static Map<String,String> getLocale(){
        Map<String,String> mapLocale = new Map<String,String>();
        Schema.DescribeFieldResult fieldResult = User.LocaleSidKey.getdescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry p : ple)
        {
        	//system.debug('###'+p.getlabel()+'****'+p.getValue()+'\n');
            mapLocale.put(p.getlabel(),p.getValue());
        }
        return mapLocale;
		}
    
    @AuraEnabled(cacheable=true)
    public static Map<String,String> getLanguage(){
        Map<String,String> mapLanguage = new Map<String,String>();
        Schema.DescribeFieldResult fieldResult = User.LanguageLocaleKey.getdescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry p : ple)
        {
        	//system.debug('###'+p.getlabel()+'****'+p.getValue()+'\n');
            mapLanguage.put(p.getlabel(),p.getValue());
        }
        return mapLanguage;
		}
	*/
    
}