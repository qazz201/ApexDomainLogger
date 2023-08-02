# ApexDomainLogger
Create log records.

For example, we have an object called ```IntegrationLog__c``` with the fields:
- ErrorMessage__c - String
- NumberofRecords__c - Integer
- Status__c - String
- RequestPayload__c - String( Http request payload)
- ResponsePayload__c - String( Http response payload)

And we can dynamically create as many IntegrationLog__c records as we want during the transaction by using ```commitLogs()``` that saves records in the DB.

### Use Case #1
```java
        IntegrationLogs integrationLogs = new IntegrationLogs(SomeClassInitiator.class);

        // Log #1: 
        IntegrationLogs.Builder log1 = integrationLogs.createLog()
            .setStatus(SUCCESS_STATUS)
            .setResponseStatusCode(200)
            .setNumberOfRecords(2)
            .setErrorMessage(new TestException(EXCEPTION_MESSAGE)) //the messages will be aggregated in one message
            .setErrorMessage('Some new error Message') //the messages will be aggregated in one message
            .setRequestPayload(REQUEST_BODY)
            .setResponsePayload(RESPONSE_BODY);

       
        // Log #2: finish logging immediately
        integrationLogs.createLog()
            .setStatus(400)
            .setResponseStatusCode(400)
            .setNumberOfRecords(1)
            .setErrorMessage(EXCEPTION_MESSAGE)
            .setRequestPayload(REQUEST_BODY)
            .setResponsePayload(RESPONSE_BODY);

        // saves logs in the DB
        integrationLogs.commitLogs();
```
