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

        // Log #1
        IntegrationLogs.Builder log1 = integrationLogs.createLog()
            .setStatus(200)
            .setResponseStatusCode(200)
            .setNumberOfRecords(2)
            .setErrorMessage('Some new error Message') // the error messages are aggregated
            .setErrorMessage('Some new error Message#2') // the error messages are aggregated
            .setFieldsFromCallout(
                new HTTPConnectionHandler.Result(
                    null,
                    null,
                    null,
                    new TestException(EXCEPTION_MESSAGE)
                )
            );

        log1.setStatus(SUCCESS_STATUS);

        // Log #2:
        integrationLogs.createLog(
                new HTTPConnectionHandler.Result(
                    null,
                    null,
                    null,
                    new TestException(EXCEPTION_MESSAGE)
                )
            )
            .setLogInitiator(INITIATOR_NAME)
            .setStatus(400)
            .setResponseStatusCode(400)
            .setNumberOfRecords(1)
            .setErrorMessage('Some Log 2 error Message')
            .setErrorMessage(EXCEPTION_MESSAGE)
            .setRequestPayload(REQUEST_BODY)
            .setResponsePayload(RESPONSE_BODY);

        // Log #3:
        integrationLogs.createLog()
            .setLogInitiator(IntegrationLogs.class)
            .setStatus('Error')
            .setNumberOfRecords(10);

        Integer logsSizeBeforeCommit = integrationLogs.getLogs().size();

        //When
        // saves logs in the DB
        integrationLogs.commitLogs();

        Integer logsSizeAfterCommit = integrationLogs.getLogs().size();

        //Then
        System.assertEquals(3, [SELECT COUNT() FROM IntegrationLog__c]);
        System.assertEquals(3, logsSizeBeforeCommit);
        System.assertEquals(0, logsSizeAfterCommit);
    }

    public class TestException extends Exception {
    }
}
