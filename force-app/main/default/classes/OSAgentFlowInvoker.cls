public with sharing class OSAgentFlowInvoker {

    @TestVisible private static final String PACKAGED_FLOW_API_NAME = 'Omniscript_Step_Chart_Agent';

    public class FlowResponse {
        @AuraEnabled public String sessionId;
        @AuraEnabled public String response;

        public FlowResponse(String sessionId, String response) {
            this.sessionId = sessionId;
            this.response = response;
        }
    }

    @AuraEnabled(cacheable=false)
    public static FlowResponse invokeFlow(String recordId, String sessionId, String requestText, String sessionHistoryJSON, String osJSON, String flowApiName) {
        String apiNameToInvoke = String.isBlank(flowApiName) ? PACKAGED_FLOW_API_NAME : flowApiName;
        if (apiNameToInvoke != PACKAGED_FLOW_API_NAME) {
            throw new AuraHandledException('Unsupported flow.');
        }

        OmniProcess authorized = OSAgentAuthz.resolveAuthorizedOmniProcess(osJSON);

        Map<String, Object> inputParams = new Map<String, Object>{
            'recordId'   => String.isBlank(recordId)  ? '' : recordId,
            'Session_Id' => String.isBlank(sessionId) ? '' : sessionId,
            'Request'    => String.isBlank(requestText) ? '' : requestText,
            'OmniscriptJSON' => String.isBlank(osJSON) ? '' : osJSON,
            'OmniscriptName' => authorized == null ? '' : authorized.Name
        };
        if (String.isBlank(sessionId) && !String.isBlank(requestText)) {
            inputParams.put('Initial_Request', requestText);
        }

        Flow.Interview interview = Flow.Interview.createInterview(apiNameToInvoke, inputParams);
        interview.start();

        String outSessionId = (String) interview.getVariableValue('Session_Id');
        String outResponse  = (String) interview.getVariableValue('Response');
        return new FlowResponse(outSessionId, outResponse);
    }
}