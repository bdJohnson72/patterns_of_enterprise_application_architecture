/**
 * Created by Brooks Johnson on 4/24/2022.
 */

@IsTest
private class BasicUOW_Tests {
    @IsTest
    static void testBasicUOW(){
        //given
        List<SObjectType> types = new List<SObjectType>{Account.SObjectType, Contact.SObjectType};
        BasicUOW uow = new BasicUOW(types);
        uow.registerNew(new Account(Name = 'Test Acc'));
        uow.registerNew(new Contact(FirstName = 'Test', LastName = 'Contact'));
        //when
        uow.commitWork();
        Contact testCon = [SELECT FirstName, LastName
        FROM Contact LIMIT 1];
        //then
        System.assertEquals('Test', testCon.FirstName, 'It should commit new work');
    }

    @IsTest
    static void itDoesUpdate(){
        //given
        Account acc = new Account(Name = 'Test Acc');
        insert acc;
        List<SObjectType> types = new List<SObjectType>{Account.SObjectType, Contact.SObjectType};
        BasicUOW uow = new BasicUOW(types);
        acc.Name = 'changed name';
        uow.registerChange(acc);
        //when
        uow.commitWork();
        Account updatedAcc = [SELECT Name FROM Account LIMIT 1];
        //then
        System.assertEquals('changed name', updatedAcc.Name, 'It should update the record');
    }

    @IsTest
    static void registerRelationship(){
        //given
        Account acc = new Account(Name = 'Test Acc');
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact');
        BasicUOW uow = new BasicUOW(new List<SObjectType>{Account.SObjectType, Contact.SObjectType});
        uow.registerNew(acc);
        uow.registerNew(con);
        uow.registerRelationship(con, Contact.AccountId, acc);
        //when
        uow.commitWork();
        //then
        Contact updatedCon = [SELECT Name, AccountId FROM Contact LIMIT 1];
        System.assert(updatedCon.AccountId == acc.Id, 'It should register the relationship');
    }
}