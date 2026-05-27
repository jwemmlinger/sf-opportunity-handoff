public with sharing class OpportunityHandoffController {

    /**
     * Wrapper for underwriter users
     */
    public class UnderwriterOption {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String email { get; set; }

        public UnderwriterOption(Id userId, String userName, String userEmail) {
            this.id = userId;
            this.name = userName;
            this.email = userEmail;
        }
    }

    /**
     * Wrapper for handoff response
     */
    public class HandoffResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String caseId { get; set; }
        @AuraEnabled public String caseNumber { get; set; }
        @AuraEnabled public String message { get; set; }

        public HandoffResult(Boolean success, String caseId, String caseNumber, String message) {
            this.success = success;
            this.caseId = caseId;
            this.caseNumber = caseNumber;
            this.message = message;
        }
    }

    /**
     * Wrapper for existing opportunity tasks
     */
    public class OpportunityTask {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String subject { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String priority { get; set; }
        @AuraEnabled public Boolean isCompleted { get; set; }
        @AuraEnabled public Date activityDate { get; set; }
        @AuraEnabled public Boolean isOverdue { get; set; }

        public OpportunityTask(Task t) {
            this.id = t.Id;
            this.subject = t.Subject;
            this.status = t.Status;
            this.priority = t.Priority;
            this.isCompleted = (t.Status == 'Completed');
            this.activityDate = t.ActivityDate;
            this.isOverdue = (!this.isCompleted && t.ActivityDate != null && t.ActivityDate < Date.today());
        }
    }

    /**
     * Wrapper for task summary statistics
     */
    public class TaskSummary {
        @AuraEnabled public Integer totalTasks { get; set; }
        @AuraEnabled public Integer completedTasks { get; set; }
        @AuraEnabled public Integer incompleteTasks { get; set; }
        @AuraEnabled public Integer overdueTasks { get; set; }
        @AuraEnabled public Decimal completionPercentage { get; set; }
        @AuraEnabled public List<OpportunityTask> tasks { get; set; }

        public TaskSummary(List<OpportunityTask> taskList) {
            this.tasks = taskList;
            this.totalTasks = taskList.size();
            this.completedTasks = 0;
            this.incompleteTasks = 0;
            this.overdueTasks = 0;

            for (OpportunityTask task : taskList) {
                if (task.isCompleted) {
                    this.completedTasks++;
                } else {
                    this.incompleteTasks++;
                    if (task.isOverdue) {
                        this.overdueTasks++;
                    }
                }
            }

            this.completionPercentage = this.totalTasks > 0
                ? (Decimal.valueOf(this.completedTasks) / Decimal.valueOf(this.totalTasks) * 100).setScale(0)
                : 0;
        }
    }

    /**
     * Get list of available underwriters (users with Underwriter profile or permission set)
     */
    @AuraEnabled(cacheable=true)
    public static List<UnderwriterOption> getUnderwriters() {
        try {
            // Query all active users (adjust criteria for production orgs)
            // For demo/dev orgs: show all users
            // For production: filter by Profile.Name LIKE '%Underwriter%' OR UserRole.Name LIKE '%Underwriter%'
            List<User> underwriters = [
                SELECT Id, Name, Email
                FROM User
                WHERE IsActive = true
                WITH SECURITY_ENFORCED
                ORDER BY Name
                LIMIT 200
            ];

            List<UnderwriterOption> options = new List<UnderwriterOption>();
            for (User u : underwriters) {
                options.add(new UnderwriterOption(u.Id, u.Name, u.Email));
            }

            return options;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching underwriters: ' + e.getMessage());
        }
    }

    /**
     * Wrapper for action plan template with tasks
     */
    public class ActionPlanTemplate {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public List<ActionPlanTask> tasks { get; set; }

        public ActionPlanTemplate(String id, String name, String description, List<ActionPlanTask> tasks) {
            this.id = id;
            this.name = name;
            this.description = description;
            this.tasks = tasks;
        }
    }

    /**
     * Wrapper for action plan task details
     */
    public class ActionPlanTask {
        @AuraEnabled public String subject { get; set; }
        @AuraEnabled public Integer dayOffset { get; set; }
        @AuraEnabled public String priority { get; set; }

        public ActionPlanTask(String subject, Integer dayOffset, String priority) {
            this.subject = subject;
            this.dayOffset = dayOffset;
            this.priority = priority;
        }
    }

    /**
     * Get available action plans with task details
     */
    @AuraEnabled(cacheable=true)
    public static List<ActionPlanTemplate> getActionPlanTemplates() {
        try {
            List<ActionPlanTemplate> templates = new List<ActionPlanTemplate>();

            // Standard Review
            List<ActionPlanTask> standardTasks = new List<ActionPlanTask>{
                new ActionPlanTask('Review Loan Application', 1, 'High'),
                new ActionPlanTask('Verify Income Documentation', 2, 'High'),
                new ActionPlanTask('Credit History Review', 3, 'Normal'),
                new ActionPlanTask('Property Appraisal Review', 4, 'Normal'),
                new ActionPlanTask('Final Approval Decision', 5, 'High')
            };
            templates.add(new ActionPlanTemplate(
                'standard_review',
                'Standard Underwriting Review',
                'Standard loan underwriting process with 5 key tasks',
                standardTasks
            ));

            // Expedited Review
            List<ActionPlanTask> expeditedTasks = new List<ActionPlanTask>{
                new ActionPlanTask('Fast Track Document Review', 1, 'High'),
                new ActionPlanTask('Automated Credit Check', 2, 'High'),
                new ActionPlanTask('Express Approval', 3, 'High')
            };
            templates.add(new ActionPlanTemplate(
                'expedited_review',
                'Expedited Review',
                'Fast-track underwriting for qualified applicants with 3 priority tasks',
                expeditedTasks
            ));

            // Complex Review
            List<ActionPlanTask> complexTasks = new List<ActionPlanTask>{
                new ActionPlanTask('Comprehensive Application Review', 1, 'High'),
                new ActionPlanTask('Advanced Income Verification', 2, 'High'),
                new ActionPlanTask('Risk Assessment Analysis', 3, 'High'),
                new ActionPlanTask('Compliance Review', 4, 'Normal'),
                new ActionPlanTask('Senior Underwriter Consultation', 5, 'Normal'),
                new ActionPlanTask('Final Decision & Documentation', 6, 'High')
            };
            templates.add(new ActionPlanTemplate(
                'complex_review',
                'Complex Case Review',
                'Enhanced review for non-standard cases with 6 comprehensive tasks',
                complexTasks
            ));

            return templates;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching action plan templates: ' + e.getMessage());
        }
    }

    /**
     * Get existing tasks for an opportunity with completion status
     */
    @AuraEnabled(cacheable=true)
    public static TaskSummary getOpportunityTasks(Id opportunityId) {
        try {
            if (opportunityId == null) {
                throw new AuraHandledException('Opportunity ID is required');
            }

            // Query all tasks related to this opportunity
            List<Task> tasks = [
                SELECT Id, Subject, Status, Priority, ActivityDate
                FROM Task
                WHERE WhatId = :opportunityId
                WITH SECURITY_ENFORCED
                ORDER BY ActivityDate ASC NULLS LAST, CreatedDate DESC
            ];

            // Convert to wrapper objects
            List<OpportunityTask> oppTasks = new List<OpportunityTask>();
            for (Task t : tasks) {
                oppTasks.add(new OpportunityTask(t));
            }

            return new TaskSummary(oppTasks);

        } catch (Exception e) {
            throw new AuraHandledException('Error fetching opportunity tasks: ' + e.getMessage());
        }
    }

    /**
     * Hand off opportunity to underwriter
     * Creates a Case linked to the Opportunity and assigns to underwriter
     */
    @AuraEnabled
    public static HandoffResult handoffToUnderwriter(
        Id opportunityId,
        Id underwriterId,
        String actionPlanTemplateId,
        String notes
    ) {
        try {
            // Validate inputs
            if (opportunityId == null) {
                throw new AuraHandledException('Opportunity ID is required');
            }
            if (underwriterId == null) {
                throw new AuraHandledException('Underwriter selection is required');
            }

            // Get Opportunity details
            Opportunity opp = [
                SELECT Id, Name, StageName, Amount, AccountId, Account.Name, OwnerId
                FROM Opportunity
                WHERE Id = :opportunityId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            // Get Underwriter details
            User underwriter = [
                SELECT Id, Name, Email
                FROM User
                WHERE Id = :underwriterId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            // Create Case for underwriting review
            Case underwrightCase = new Case(
                Subject = 'Underwriting Review: ' + opp.Name,
                Description = buildCaseDescription(opp, underwriter, notes),
                Status = 'New',
                Priority = 'Medium',
                OwnerId = underwriterId,
                AccountId = opp.AccountId,
                Origin = 'Loan Officer Handoff'
            );

            // Add custom fields if they exist in your org
            // Uncomment and adjust field API names as needed:
            // underwrightCase.put('Opportunity__c', opportunityId);
            // underwrightCase.put('Loan_Officer__c', UserInfo.getUserId());
            // underwrightCase.put('Action_Plan_Template__c', actionPlanTemplateId);

            // FLS check
            SObjectAccessDecision decision = Security.stripInaccessible(
                AccessType.CREATABLE,
                new List<Case>{ underwrightCase }
            );

            insert decision.getRecords();
            Case insertedCase = (Case) decision.getRecords()[0];

            // Update Opportunity stage (optional - adjust stage name as needed)
            try {
                opp.StageName = 'Underwriting';
                opp.put('Underwriter__c', underwriterId); // Custom field - add if exists
                update opp;
            } catch (Exception e) {
                System.debug('Note: Could not update Opportunity stage or underwriter field: ' + e.getMessage());
            }

            // Create action plan tasks (simplified version)
            if (String.isNotBlank(actionPlanTemplateId)) {
                createActionPlanTasks(insertedCase.Id, actionPlanTemplateId);
            }

            // Send notification (optional)
            sendHandoffNotification(underwriter, opp, insertedCase);

            // Reload case to get Case Number
            Case finalCase = [
                SELECT Id, CaseNumber
                FROM Case
                WHERE Id = :insertedCase.Id
                LIMIT 1
            ];

            return new HandoffResult(
                true,
                finalCase.Id,
                finalCase.CaseNumber,
                'Successfully handed off to ' + underwriter.Name
            );

        } catch (Exception e) {
            return new HandoffResult(
                false,
                null,
                null,
                'Error during handoff: ' + e.getMessage()
            );
        }
    }

    /**
     * Build case description with opportunity and handoff details
     */
    private static String buildCaseDescription(Opportunity opp, User underwriter, String notes) {
        String description = 'LOAN UNDERWRITING REQUEST\n\n';
        description += 'Opportunity: ' + opp.Name + '\n';
        description += 'Account: ' + opp.Account.Name + '\n';
        description += 'Amount: $' + (opp.Amount != null ? String.valueOf(opp.Amount.setScale(2)) : '0.00') + '\n';
        description += 'Current Stage: ' + opp.StageName + '\n';
        description += 'Assigned Underwriter: ' + underwriter.Name + '\n\n';

        if (String.isNotBlank(notes)) {
            description += 'LOAN OFFICER NOTES:\n' + notes + '\n\n';
        }

        description += 'Created via Opportunity Handoff on ' + System.now().format();

        return description;
    }

    /**
     * Create action plan tasks based on template
     */
    private static void createActionPlanTasks(Id caseId, String templateId) {
        List<Task> tasks = new List<Task>();

        // Create tasks based on template
        // This is a simplified version - adjust based on your action plan implementation
        if (templateId == 'standard_review') {
            tasks.add(createTask(caseId, 'Review Loan Application', 1));
            tasks.add(createTask(caseId, 'Verify Income Documentation', 2));
            tasks.add(createTask(caseId, 'Credit History Review', 3));
            tasks.add(createTask(caseId, 'Property Appraisal Review', 4));
            tasks.add(createTask(caseId, 'Final Approval Decision', 5));
        } else if (templateId == 'expedited_review') {
            tasks.add(createTask(caseId, 'Fast Track Document Review', 1));
            tasks.add(createTask(caseId, 'Automated Credit Check', 2));
            tasks.add(createTask(caseId, 'Express Approval', 3));
        } else if (templateId == 'complex_review') {
            tasks.add(createTask(caseId, 'Comprehensive Application Review', 1));
            tasks.add(createTask(caseId, 'Advanced Income Verification', 2));
            tasks.add(createTask(caseId, 'Risk Assessment Analysis', 3));
            tasks.add(createTask(caseId, 'Compliance Review', 4));
            tasks.add(createTask(caseId, 'Senior Underwriter Consultation', 5));
            tasks.add(createTask(caseId, 'Final Decision & Documentation', 6));
        }

        if (!tasks.isEmpty()) {
            insert tasks;
        }
    }

    /**
     * Helper to create a task
     */
    private static Task createTask(Id caseId, String subject, Integer dayOffset) {
        return new Task(
            WhatId = caseId,
            Subject = subject,
            Status = 'Not Started',
            Priority = 'Normal',
            ActivityDate = Date.today().addDays(dayOffset)
        );
    }

    /**
     * Send notification to underwriter (optional - implement based on your needs)
     */
    private static void sendHandoffNotification(User underwriter, Opportunity opp, Case underwrightCase) {
        // Implement email notification, Chatter post, or custom notification here
        // Example using FeedItem (Chatter):
        try {
            FeedItem post = new FeedItem(
                ParentId = underwrightCase.Id,
                Body = '@[' + underwriter.Id + '] - New underwriting case assigned for ' + opp.Name,
                Type = 'TextPost'
            );
            insert post;
        } catch (Exception e) {
            System.debug('Note: Could not create Chatter post: ' + e.getMessage());
        }
    }
}
