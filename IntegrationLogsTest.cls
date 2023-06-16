@IsTest
private class IntegrationLogsTest {
    private static final String SUCCESS_STATUS = 'Success';
    private static final String INITIATOR_NAME = 'Some initiator Name';
    private static final String REQUEST_BODY = 'Some request body';
    private static final String RESPONSE_BODY = 'Some request body';
    private static final String EXCEPTION_MESSAGE = 'Some Exception Message';

    @IsTest
    static void mainUseCase() {
        //Given
        IntegrationLogs integrationLogs = new IntegrationLogs(IntegrationLogsTest.class);
        TestException ex = new TestException();
        ex.setMessage(EXCEPTION_MESSAGE);

        // Log #1: with delayed log finish
        IntegrationLogs.Builder log1 = integrationLogs.startLogging()
            .setStatus(SUCCESS_STATUS)
            .setResponseStatusCode(200)
            .setNumberOfRecords(2)
            .setErrorMessage(ex)
            .setRequestPayload(REQUEST_BODY)
            .setResponsePayload(RESPONSE_BODY)
            .setFieldsFromCallout(new HTTPConnectionHandler.Result(null, null, null, null));

        // log can be finished at any time
        log1.finishLogging(); // adds current log in integrationLogs list

        // Log #2: finish logging immediately
        integrationLogs.startLogging(new HTTPConnectionHandler.Result(null, null, null, null))
            .setStatus(400)
            .setResponseStatusCode(400)
            .setNumberOfRecords(1)
            .setErrorMessage(EXCEPTION_MESSAGE)
            .setRequestPayload(REQUEST_BODY)
            .setResponsePayload(RESPONSE_BODY)
            .finishLogging(); // adds current log in integrationLogs list

        //When
        Integer logsBeforeCommitSize = integrationLogs.getLogs().size();
        // saves logs in the DB
        integrationLogs.commitLogs();

        Integer logsAfterCommitSize = integrationLogs.getLogs().size();

        //Then
        System.assertEquals(2, [SELECT COUNT() FROM IntegrationLog__c]);
        System.assertEquals(2, logsBeforeCommitSize);
        System.assertEquals(0, logsAfterCommitSize);
    }

    @IsTest
    static void useCase2() {
        //Given
        IntegrationLogs integrationLogs = new IntegrationLogs();

        // Log #1
        IntegrationLogs.Builder log1 = integrationLogs.startLogging()
            .setLogInitiator(IntegrationLogsTest.class)
            .setStatus(SUCCESS_STATUS)
            .setResponseStatusCode(200)
            .setNumberOfRecords(2)
            .setErrorMessage(EXCEPTION_MESSAGE)
            .setRequestPayload(REQUEST_BODY)
            .setResponsePayload(RESPONSE_BODY);

        // Log #2
        IntegrationLogs.Builder log2 = integrationLogs.startLogging()
            .setLogInitiator(INITIATOR_NAME)
            .setStatus(400)
            .setResponseStatusCode(400)
            .setNumberOfRecords(1)
            .setErrorMessage(EXCEPTION_MESSAGE)
            .setRequestPayload(REQUEST_BODY)
            .setResponsePayload(RESPONSE_BODY);

        //When
        integrationLogs.finishLogging(new List<IntegrationLogs.Builder>{ log1, log2 }); // this method adds logs in the Log list for saving
        Integer logsBeforeCommitSize = integrationLogs.getLogs().size();
        // saves logs in the DB
        integrationLogs.commitLogs();

        Integer logsAfterCommitSize = integrationLogs.getLogs().size();

        //Then
        System.assertEquals(2, [SELECT COUNT() FROM IntegrationLog__c]);
        System.assertEquals(2, logsBeforeCommitSize);
        System.assertEquals(0, logsAfterCommitSize);
    }

    @IsTest
    static void useCase3() {
        //Given
        IntegrationLogs integrationLogs = new IntegrationLogs(INITIATOR_NAME);

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

        //When
        integrationLogs.finishLogging(log1); // this method adds log in the Log list for saving
        integrationLogs.finishLogging(log2); // this method adds log Builder in the Log list for saving

        Integer logsBeforeCommitSize = integrationLogs.getLogs().size();
        // saves logs in the DB
        integrationLogs.commitLogs();

        Integer logsAfterCommitSize = integrationLogs.getLogs().size();

        //Then
        System.assertEquals(2, [SELECT COUNT() FROM IntegrationLog__c]);
        System.assertEquals(2, logsBeforeCommitSize);
        System.assertEquals(0, logsAfterCommitSize);
    }

    public class TestException extends Exception {
    }
}
