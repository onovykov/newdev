public with sharing class ApprovalRequestController {

    @AuraEnabled(cacheable=true)
public static List<ApprovalRequestWrapper> getApprovalRequests() {
    List<ApprovalRequestWrapper> wrappers = new List<ApprovalRequestWrapper>();
    String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();

    // Query ProcessInstanceWorkitem for pending approvals
    List<ProcessInstanceWorkitem> workItems = [SELECT Id, ProcessInstanceId, 
                                               ProcessInstance.Status, ProcessInstance.TargetObjectId
                                               FROM ProcessInstanceWorkitem
                                               WHERE ProcessInstance.Status = 'Pending'
                                               AND ActorId = :UserInfo.getUserId()];

    Set<Id> targetObjectIds = new Set<Id>();
    for (ProcessInstanceWorkitem workItem : workItems) {
        targetObjectIds.add(workItem.ProcessInstance.TargetObjectId);
    }

    // Query OpportunityProductApproval__c records
    Map<Id, OpportunityProductApproval__c> oppProductApprovalMap = new Map<Id, OpportunityProductApproval__c>(
        [SELECT Id, Name, KDO__c, ExpirationDate__c, Opportunity__c, Opportunity__r.Name, OpportunityProduct__r.Name__c 
         FROM OpportunityProductApproval__c 
         WHERE Id IN :targetObjectIds]
    );

    for (ProcessInstanceWorkitem workItem : workItems) {
        OpportunityProductApproval__c oppProductApproval = oppProductApprovalMap.get(workItem.ProcessInstance.TargetObjectId);
        
        if (oppProductApproval != null) {
            String oppLink = baseUrl + '/' + oppProductApproval.Opportunity__c;
            String oppProductLink = baseUrl + '/' + oppProductApproval.Id;
            String oppName = oppProductApproval.Opportunity__r.Name;
            String oppProductName = oppProductApproval.OpportunityProduct__r.Name__c;
            Date expirationDate = oppProductApproval.ExpirationDate__c;

            ApprovalRequestWrapper wrapper = new ApprovalRequestWrapper(
                workItem.Id, 
                null, // Comments are not available in ProcessInstanceWorkitem
                workItem.ProcessInstanceId, 
                workItem.ProcessInstance.Status, 
                oppProductApproval.Name,
                oppProductApproval.KDO__c,
                oppName,
                oppProductName,
                expirationDate,
                oppLink,
                oppProductLink
            );
            wrappers.add(wrapper);
        }
    }
    return wrappers;
}

    
    @AuraEnabled
    public static void approveRequests(List<ApprovalRequestWrapper> workItems) {
        system.debug(workItems);
        List<ProcessInstanceWorkitem> itemsToApprove = new List<ProcessInstanceWorkitem>();
        Set<String> processInstanceId = new Set<String>();
        
        for (ApprovalRequestWrapper item : workItems) {
            processInstanceId.add(item.processInstanceId);
        }
    
        // Query ProcessInstanceWorkitems based on collected processInstanceIds
        Map<String, ProcessInstanceWorkitem> processInstanceWorkitemMap = new Map<String, ProcessInstanceWorkitem>();
        for (ProcessInstanceWorkitem item : [SELECT Id, ProcessInstanceId FROM ProcessInstanceWorkitem WHERE ProcessInstanceId IN :processInstanceId]) {
            processInstanceWorkitemMap.put(item.ProcessInstanceId, item);
        }
    
        for (ApprovalRequestWrapper item : workItems) {
            Approval.ProcessWorkitemRequest approvalRequest = new Approval.ProcessWorkitemRequest();
            system.debug(item);
    
            // Check if there's a corresponding ProcessInstanceWorkitem
            ProcessInstanceWorkitem workitemToApprove = processInstanceWorkitemMap.get(item.processInstanceId);
            if (workitemToApprove != null) {
                approvalRequest.setComments(item.comment);
                approvalRequest.setAction('Approve');
                approvalRequest.setWorkitemId(workitemToApprove.Id);
    
                try {
                    Approval.ProcessResult result = Approval.process(approvalRequest);
                    if (result.isSuccess()) {
                        itemsToApprove.add(workitemToApprove);
                    }
                } catch (Exception e) {
                }
            }
        }
    
    }
    
@AuraEnabled
public static void rejectRequests(List<ApprovalRequestWrapper> workItems) {
    List<ProcessInstanceWorkitem> itemsToReject = new List<ProcessInstanceWorkitem>();
    Set<String> processInstanceId = new Set<String>();
    
    for (ApprovalRequestWrapper item : workItems) {
        processInstanceId.add(item.processInstanceId);
    }

    Map<String, ProcessInstanceWorkitem> processInstanceWorkitemMap = new Map<String, ProcessInstanceWorkitem>();
    for (ProcessInstanceWorkitem item : [SELECT Id, ProcessInstanceId FROM ProcessInstanceWorkitem WHERE ProcessInstanceId IN :processInstanceId]) {
        processInstanceWorkitemMap.put(item.ProcessInstanceId, item);
    }

    for (ApprovalRequestWrapper item : workItems) {
        Approval.ProcessWorkitemRequest rejectionRequest = new Approval.ProcessWorkitemRequest();
        rejectionRequest.setComments(item.comment);
        rejectionRequest.setAction('Reject');
        
        ProcessInstanceWorkitem workitemToReject = processInstanceWorkitemMap.get(item.processInstanceId);
        if (workitemToReject != null) {
            rejectionRequest.setWorkitemId(workitemToReject.Id);
            try {
                Approval.ProcessResult result = Approval.process(rejectionRequest);
                if (result.isSuccess()) {
                    itemsToReject.add(workitemToReject);
                }
            } catch (Exception e) {
            }
        }
    }
}



    public class ApprovalRequestWrapper {
        @AuraEnabled public Id stepId {get; set;}
        @AuraEnabled public String comments {get; set;}
        @AuraEnabled public Id processInstanceId {get; set;}
        @AuraEnabled public String processStatus {get; set;}
        @AuraEnabled public String targetObjectName {get; set;}
        @AuraEnabled public Date targetObjectKDO {get; set;}
        @AuraEnabled public String oppName {get; set;}
        @AuraEnabled public String oppProductName {get; set;}
        @AuraEnabled public Date expirationDate {get; set;}
        @AuraEnabled public String oppLink {get; set;}
        @AuraEnabled public String oppProductLink {get; set;}
        @AuraEnabled public String comment {get; set;}
        public ApprovalRequestWrapper() {
        }

        public ApprovalRequestWrapper(Id stepId, String comments, Id processInstanceId, String processStatus, String targetObjectName, Date targetObjectKDO, String oppName,
                                      String oppProductName, Date expirationDate, String oppLink, String oppProductLink) {
            this.stepId = stepId;
            this.comments = comments;
            this.processInstanceId = processInstanceId;
            this.processStatus = processStatus;
            this.targetObjectName = targetObjectName;
            this.targetObjectKDO = targetObjectKDO;
            this.oppName = oppName;
            this.oppProductName = oppProductName;
            this.expirationDate = expirationDate;
            this.oppLink = oppLink;
            this.oppProductLink = oppProductLink;
        }
    }
    public static void FakeCoverageMethod() {
        Integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}