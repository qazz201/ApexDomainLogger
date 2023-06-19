public with sharing class IntegrationLogs {
    private static List<IntegrationLog__c> integrationLogs = new List<IntegrationLog__c>();
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
     * If you  want to add log in Log list you should call the method 'finishLogging' and pass this log Builder
     * @param calloutWrapper
     * @returns Builder
     */
    public Builder startLogging(HTTPConnectionHandler.Result calloutWrapper) {
        Builder log = this.startLogging();
        if (calloutWrapper == null) {
            return log;
        }

        return log.setFieldsFromCallout(calloutWrapper);
    }

    /**
     * @description It is used to create Log wia Builder. Log fields can be set up dynamically.
     * The Builder - will build IntegrationLog__c. The method 'build()' returns IntegrationLog__c with populated fields.
     * If you  want to add log in Log list you should call the method 'finishLogging' and pass this log Builder
     * @returns Builder
     */
    public Builder startLogging() {
        Builder log = new Builder(this);

        if (String.isNotBlank(this.logInitiator)) {
            log.setLogInitiator(this.logInitiator);
        }

        return log;
    }

    /**
     *@description It is used for adding log Builder in the Log list.
     * To save logs in DB simply call the method 'commitLogs()'
     * @returns IntegrationLogs - used for chaining
     */
    public IntegrationLogs finishLogging(Builder log) {
        return this.finishLogging(new List<IntegrationLog__c>{ log.build() });
    }

    public IntegrationLogs finishLogging(List<Builder> logBuilders) {
        if (Lists.isEmpty(logBuilders)) {
            return this;
        }

        List<IntegrationLog__c> logs = new List<IntegrationLog__c>();

        for (Builder logBuilder : logBuilders) {
            logs.add(logBuilder.build());
        }

        return this.finishLogging(logs);
    }

    public IntegrationLogs finishLogging(IntegrationLog__c log) {
        return this.finishLogging(new List<IntegrationLog__c>{ log });
    }

    public IntegrationLogs finishLogging(List<IntegrationLog__c> logs) {
        integrationLogs.addAll(logs);
        return this;
    }

    /**
     *@description It is used for retrieving a list of Logs
     */
    public List<IntegrationLog__c> getLogs() {
        return integrationLogs;
    }

    /**
     *@description It is used for upserting Log (IntegrationLog__c) records.
     * Important! 
     * Call 'finishLogging(...)' method before committing logs. 
     * In this case logs are added to the list and can be committed.
     */
    public void commitLogs() {
        if (Lists.isEmpty(integrationLogs)) {
            return;
        }

        Database.upsert(integrationLogs, false);
        integrationLogs.clear();
        //TODO: Handle errors when the log can not be saved ( e.g field is too long)
    }

    public class Builder {
        private IntegrationLog__c log;
        private IntegrationLogs parent;
        private List<String> errorMessages = new List<String>();

        public Builder() {
            this.log = new IntegrationLog__c();
        }

        public Builder(IntegrationLogs parent) {
            this();
            this.parent = parent;
        }

        /**
         *@description Can be called to return IntegrationLog__c with populated fields
         */
        public IntegrationLog__c build() {
            this.populateErrorMessagesInField();
            return this.log;
        }

        /**
         *@description Adds current log in Parent Log list directly from Builder.
         * The result logs can be saved by calling 'commitLogs()' method on the parent.
         * Important! The parent(IntegrationLogs) instance should exist or an Exception will be thrown
         */
        public void finishLogging() {
            if (this.parent == null) {
                throw new BuilderException('The parent instance should exist');
            }

            parent?.finishLogging(this.build());
        }

        public Builder setFieldsFromCallout(HTTPConnectionHandler.Result calloutWrapper) {
            if (calloutWrapper == null) {
                return this;
            }

            this.setRequestPayload(calloutWrapper.request?.getBody())
                .setResponsePayload(calloutWrapper.httpResponse?.getBody())
                .setErrorMessage(calloutWrapper.except)
                .setStatus(calloutWrapper.httpResponse?.getStatusCode())
                .setResponseStatusCode(calloutWrapper.httpResponse?.getStatusCode());

            return this;
        }

        // Set Log Initiator
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
        public Builder setErrorMessage(Exception ex) {
            if (ex == null) {
                return this;
            }

            return this.setErrorMessage(
                '\n Error Type: ' +
                    ex?.getTypeName() +
                    '\n Error Message: ' +
                    ex?.getMessage() +
                    ' \n StackTrace: \n' +
                    ex?.getStackTraceString()
            );
        }

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

        private void populateErrorMessagesInField() {
            if (Lists.isEmpty(this.errorMessages)) {
                return;
            }

            this.log.ErrorMessage__c = String.join(this.errorMessages, '\n\n');
        }
    }
    public class BuilderException extends Exception {
    }

    public class IntegrationLogsException extends Exception {
    }
}
