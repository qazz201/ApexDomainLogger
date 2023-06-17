# ApexDomainLogger
Create log records

### Use Case #1
```java
        IntegrationLogs integrationLogs = new IntegrationLogs(SomeClassInitiator.class);

        // Log #1: with delayed log finish
        IntegrationLogs.Builder log1 = integrationLogs.startLogging()
            .setStatus(SUCCESS_STATUS)
            .setResponseStatusCode(200)
            .setNumberOfRecords(2)
            .setErrorMessage(new TestException(EXCEPTION_MESSAGE)) //the messages will be aggregated in one message
            .setErrorMessage('Some new error Message') //the messages will be aggregated in one message
            .setRequestPayload(REQUEST_BODY)
            .setResponsePayload(RESPONSE_BODY)

        // log can be finished at any time
        log1.finishLogging(); // adds current log in integrationLogs list

        // Log #2: finish logging immediately
        integrationLogs.startLogging()
            .setStatus(400)
            .setResponseStatusCode(400)
            .setNumberOfRecords(1)
            .setErrorMessage(EXCEPTION_MESSAGE)
            .setRequestPayload(REQUEST_BODY)
            .setResponsePayload(RESPONSE_BODY)
            .finishLogging(); // adds current log in integrationLogs list

     
        // saves logs in the DB
        integrationLogs.commitLogs();
```
    
 ### Use Case #2
```java
        IntegrationLogs integrationLogs = new IntegrationLogs();

        // Log #1
        IntegrationLogs.Builder log1 = integrationLogs.startLogging()
            .setLogInitiator(SomeClassInitiator.class)
            .setStatus(SUCCESS_STATUS)
            .setResponseStatusCode(200)
            .setNumberOfRecords(2)
            .setErrorMessage(EXCEPTION_MESSAGE)
            .setRequestPayload(REQUEST_BODY)
            .setResponsePayload(RESPONSE_BODY);

        // Log #2
        IntegrationLogs.Builder log2 = integrationLogs.startLogging()
            .setLogInitiator('SomeAnotherClassInitiator')
            .setStatus(400)
            .setResponseStatusCode(400)
            .setNumberOfRecords(1)
            .setErrorMessage(EXCEPTION_MESSAGE)
            .setRequestPayload(REQUEST_BODY)
            .setResponsePayload(RESPONSE_BODY);

        //When
        integrationLogs.finishLogging(new List<IntegrationLogs.Builder>{ log1, log2 }); // this method adds logs in the Log list for saving
        // saves logs in the DB
        integrationLogs.commitLogs();
```
    
 ### Use Case #3
 ```java
        IntegrationLogs integrationLogs = new IntegrationLogs('SomeClassInitiator');

        // Log #1: The record already prepared for saving in db (can be saved via commitLogs())
        IntegrationLog__c log1 = integrationLogs.startLogging()
            .setStatus(SUCCESS_STATUS)
            .setResponseStatusCode(200)
            .setNumberOfRecords(2)
            .setErrorMessage(EXCEPTION_MESSAGE)
            .setRequestPayload(REQUEST_BODY)
            .setResponsePayload(RESPONSE_BODY)
            .build();

        // Log #2: Just Builder
        IntegrationLogs.Builder log2 = integrationLogs.startLogging()
            .setStatus(400)
            .setResponseStatusCode(400)
            .setNumberOfRecords(1)
            .setErrorMessage(EXCEPTION_MESSAGE)
            .setRequestPayload(REQUEST_BODY)
            .setResponsePayload(RESPONSE_BODY);

        integrationLogs.finishLogging(log1); // this method adds log in the Log list for saving
        integrationLogs.finishLogging(log2); // this method adds log Builder in the Log list for saving

        // saves logs in the DB
        integrationLogs.commitLogs();
```
