public with sharing class IntegrationLogs {
    private static List<Builder> integrationLogs = new List<Builder>();
    private String logInitiator; //the name of who launched the log

    public IntegrationLogs(Type initiator) {
        this(initiator?.getName());
    }

    public IntegrationLogs(String initiator) {
        this.logInitiator = initiator;
    }

    public IntegrationLogs() {
    }

    /**
     * @description It is used to create Log via Builder. Log fields can be set up dynamically.
     * The Builder - will set IntegrationLog__c fields. The method 'build()' returns IntegrationLog__c with populated fields.
     * @param calloutWrapper
     * @returns Builder
     */
    public Builder createLog(HTTPConnectionHandler.Result calloutWrapper) {
        Builder log = this.createLog();
        if (calloutWrapper == null) {
            return log;
        }

        return log.setFieldsFromCallout(calloutWrapper);
    }

    public IntegrationLogs resetLogInitiator(Type newInitiatorName) {
        this.logInitiator = newInitiatorName?.getName();
        return this;
    }

    /**
     * @description It is used to create Log wia Builder. Log fields can be set up dynamically.
     * The Builder - will build IntegrationLog__c. The method 'build()' returns IntegrationLog__c with populated fields.
     * @returns Builder
     */
    public Builder createLog() {
        Builder log = new Builder();

        if (String.isNotBlank(this.logInitiator)) {
            log.setLogInitiator(this.logInitiator);
        }

        integrationLogs.add(log);
        return log;
    }

    /**
     *@description It is used for retrieving a list of Logs
     */
    public List<IntegrationLog__c> getLogs() {
        List<IntegrationLog__c> logs = new List<IntegrationLog__c>();

        for (Builder logBuilder : integrationLogs) {
            logs.add(logBuilder.build());
        }

        return logs;
    }

    /**
     *@description It is used for upserting Log (IntegrationLog__c) records.
     * @return List<IntegrationLog__c> saved in DB
     */
    public List<IntegrationLog__c> commitLogs() {
        List<IntegrationLog__c> logs = this.getLogs();
        List<IntegrationLog__c> savedLogs = new List<IntegrationLog__c>();

        if (Lists.isEmpty(logs)) {
            return savedLogs;
        }

        Database.upsert(logs, false);
        savedLogs.addAll(logs);
        integrationLogs.clear();
        //TODO: Handle errors when the log can not be saved ( e.g field is too long)
        return savedLogs;
    }

    /**
     * Used to dynamically populate IntegrationLog__c fields.
     * To get the result record - simply call the 'build()' method.
     */
    public class Builder {
        private IntegrationLog__c log;
        private List<String> errorMessages = new List<String>();

        public Builder() {
            this.log = new IntegrationLog__c();
        }

        /**
         *@description Can be called to return IntegrationLog__c with populated fields
         */
        public IntegrationLog__c build() {
            this.populateErrorMessagesInField();
            return this.log;
        }

        public String getLogInitiator() {
            return this.log.LogInitiator__c;
        }

        public Builder setFieldsFromCallout(HTTPConnectionHandler.Result calloutWrapper) {
            if (calloutWrapper == null) {
                return this;
            }

            this.setRequestPayload(calloutWrapper.request?.getBody())
                .setResponsePayload(calloutWrapper.httpResponse?.getBody())
                .setErrorMessage(calloutWrapper.except)
                .setStatus(calloutWrapper.httpResponse?.getStatusCode())
                .setResponseStatusCode(calloutWrapper.httpResponse?.getStatusCode())
                .setOperationType(calloutWrapper)
                .setObjectType(calloutWrapper);

            return this;
        }

        // Set Operation Type
        public Builder setOperationType(HTTPConnectionHandler.Result calloutWrapper) {
            if (calloutWrapper == null) {
                return this;
            } 

            this.setOperationType(this.getParsedCalloutRequest(calloutWrapper?.request)?.Operation);
            return this;
        }

        public Builder setOperationType(String operationType) {
            if (String.isBlank(operationType)) {
                return this;
            }

            log.OperationType__c = operationType;
            return this;
        }

        // Set Object Type
        public Builder setObjectType(HTTPConnectionHandler.Result calloutWrapper) {
            if (calloutWrapper == null) {
                return this;
            }

            this.setObjectType(this.getParsedCalloutRequest(calloutWrapper?.request)?.type);
            return this;
        }

        public Builder setObjectType(String objectType) {
            if (String.isBlank(objectType)) {
                return this;
            }

            log.ObjectType__c = objectType;
            return this;
        }

        // Set Log Initiator
        public Builder addAdditionalLogInitiatorAtTheBeginning(String additionalInitiator) {
            if (String.isBlank(additionalInitiator)) {
                return this;
            }

            return this.setLogInitiator(additionalInitiator + '--' + this.log.LogInitiator__c);
        }

        public Builder setLogInitiator(Type initiator) {
            if (initiator == null) {
                return this;
            }

            return this.setLogInitiator(initiator.getName());
        }

        public Builder setLogInitiator(String initiator) {
            this.log.LogInitiator__c = initiator;
            return this;
        }

        // Set Log Status
        public Builder setStatus(String status) {
            this.log.Status__c = status;
            return this;
        }

        public Builder setStatus(Integer statusCode) {
            return this.setStatus(
                statusCode == 200
                    ? Constants.IntegrationLog.STATUS_SUCCESS
                    : Constants.IntegrationLog.STATUS_ERROR
            );
        }

        // Set Response Status Code
        public Builder setResponseStatusCode(Integer statusCode) {
            this.log.ResponseStatusCode__c = statusCode;
            return this;
        }

        // Set Error Message
        /**
         *@description The message will be aggregated with previous messages if they exist
         * @returns Builder
         */
        public Builder setErrorMessage(Exception ex) {
            if (ex == null) {
                return this;
            }

            return this.setErrorMessage(
                '\n Error Type: ' +
                    ex?.getTypeName() +
                    '\n Error Message: ' +
                    ex?.getMessage() +
                    ' \n Stack Trace: \n' +
                    ex?.getStackTraceString()
            );
        }

        /**
         *@description The message will be aggregated with previous messages if they exist
         * @returns Builder
         */
        public Builder setErrorMessage(String errorMsg) {
            if (String.isBlank(errorMsg)) {
                return this;
            }

            this.errorMessages.add(errorMsg);
            return this;
        }

        public Builder setNumberOfRecords(Integer numberOfRecords) {
            this.log.NumberofRecords__c = numberOfRecords;
            return this;
        }

        public Builder setRequestPayload(String payload) {
            this.log.RequestPayload__c = payload;
            return this;
        }

        public Builder setResponsePayload(String payload) {
            this.log.ResponsePayload__c = payload;
            return this;
        }

        // Helpers
        private void populateErrorMessagesInField() {
            if (Lists.isEmpty(this.errorMessages)) {
                return;
            }

            this.log.ErrorMessage__c = String.join(this.errorMessages, '\n\n');
            this.errorMessages.clear();
        }

        private RequestBodyWrapper getParsedCalloutRequest(HttpRequest request) {
            if (request == null) {
                return null;
            }

            RequestBodyWrapper bodyWrapper;

            try {
                bodyWrapper = (RequestBodyWrapper) JSON.deserialize(
                    request.getBody(),
                    RequestBodyWrapper.class
                );
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, e.getStackTraceString());
                this.setErrorMessage(e);
            }

            return bodyWrapper;
        }
    }

    private class RequestBodyWrapper {
        public String type;
        public String Operation;
    }

    public class BuilderException extends Exception {
    }

    public class IntegrationLogsException extends Exception {
    }
}
