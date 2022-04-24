/**
 * Created by brooks.johnson on 4/20/2022.
 */

public with sharing class BasicUOW {

    List<SObjectType> types;
    Map<String, List<SObject>> newListByType;
    Map<String, List<SObject>> changedListByType;
    Map<String, Relationships> relationships;


    public BasicUOW(List<SObjectType> types){
        this.types = types;
        this.newListByType = new Map<String, List<SObject>>();
        this.changedListByType = new Map<String, List<SObject>>();
        this.relationships = new Map<String, Relationships>();
        for( SObjectType type : types){
            handleRegisterType(type);
        }
    }

    /**
     * @description called from the constructor. For each of the SObject types that were passed to the constructor
     * this method will populate the member variable maps with a key of the sobjectType and an empty list or
     * an instance of the Relationships class.
     * @param sobjType the Sobject Types that the UOW will handle
     */
    private void handleRegisterType(Schema.SObjectType sobjType){
        newListByType.put(sobjType.getDescribe().getName(), new List<SObject>());
        changedListByType.put(sobjType.getDescribe().getName(), new List<SObject>());
        relationships.put(sobjType.getDescribe().getName(), new Relationships());
    }

    /**
     * @description Register new SObject to insert to the database.
     * @param sobj The sobject to be inserted
     */
    public void registerNew(SObject sobj){
        //what is the sobject type
        String sobjType = sobj.getSObjectType().getDescribe().getName();
        //add it to the map
        newListByType.get(sobjType).add(sobj);
    }

    /**
     * @description The sobject that will be updated.
     * @param sobj the SObject that will be updated.
     */
    public void registerChange(SObject sobj){
        String sobjType = sobj.getSObjectType().getDescribe().getName();
        changedListByType.get(sobjType).add(sobj);
    }

    /**
     * @description registers a relationship between two SObject before they are inserted
     * into the database. The configure of our application is important here. Our accounts have to be inserted
     * before our contacts, etc..
     * @param record the child record
     * @param relationshipField the field on the child record that contains the relationship
     * @param relatedTo the parent recod
     */
    public void registerRelationship(SObject record, Schema.SObjectField relationshipField, SObject relatedTo){
        //get the sobj type
        String sobjectType = record.getSObjectType().getDescribe().getName();
        //We are get getting the appropriate instance of the relationship class from the map and
        //callings the add method. This creates a new relationship class
        relationships.get(sobjectType).add(record, relationshipField, relatedTo);
    }

    /**
     * @description commit all work to the database.
     */
    public void commitWork(){
        Savepoint sp = Database.setSavepoint();
        try {

            doInsert();
            doUpdate();
        } catch (Exception e) {
            System.debug(e);
            Database.rollback(sp);
        }
    }

    private void doInsert() {
        for(SObjectType type : types){
            //iterate over all the types
            //if there are relationships to resolve get the appropriate instance of the relationship class
            //and call the resolve method
            this.relationships.get(String.valueOf(type)).resolve();
            insert newListByType.get(String.valueOf(type));
        }
    }

    private void doUpdate(){
        //iterate over all the types
        //get the list from the map and update
        for( SObjectType type : types){
            update changedListByType.get(String.valueOf(type));
        }
    }

    private class Relationships {
        List<Relationship> relationshipList;

        public Relationships(){
            this.relationshipList = new List<BasicUOW.Relationship>();
        }

        public void add(SObject record, SObjectField relatedField, SObject relatedTo){
            Relationship relationship = new Relationship(record, relatedField, relatedTo);
            relationshipList.add(relationship);
        }

        public void resolve(){
            for(Relationship relationship : relationshipList){
                //delegates to the resolve method of the child class
                relationship.resolve();
            }
        }
    }



    private class Relationship {
        public SObject record;
        public SObjectField relatedToField;
        public SObject relatedTo;

        public Relationship(Sobject record, SObjectField relatedToField, SObject relatedTo){
            this.record = record;
            this.relatedToField = relatedToField;
            this.relatedTo = relatedTo;
        }

        public void resolve(){
            this.record.put(this.relatedToField, this.relatedTo.Id);
        }

    }

}