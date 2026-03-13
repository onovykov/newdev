@IsTest
public class TestUtil {
    public static User makeUser(String email, String profileName){
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        User u = new User(
            Alias='tst' + String.valueOf(Math.mod(Crypto.getRandomInteger(),1000)).left(3),
            Email=email,
            EmailEncodingKey='UTF-8',
            LastName='Test',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Los_Angeles',
            Username= email + '.' + System.currentTimeMillis(),
            ProfileId=p.Id
        );
        insert u;
        return u;
    }
}