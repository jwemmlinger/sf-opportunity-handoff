import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import getUnderwriters from '@salesforce/apex/OpportunityHandoffController.getUnderwriters';
import getActionPlanTemplates from '@salesforce/apex/OpportunityHandoffController.getActionPlanTemplates';
import getOpportunityTasks from '@salesforce/apex/OpportunityHandoffController.getOpportunityTasks';
import handoffToUnderwriter from '@salesforce/apex/OpportunityHandoffController.handoffToUnderwriter';

export default class OpportunityHandoff extends NavigationMixin(LightningElement) {
    @api recordId; // Opportunity ID from quick action context

    // Component state
    @track selectedUnderwriterId;
    @track selectedActionPlanId;
    @track handoffNotes = '';
    @track isLoading = false;

    // Data from wire services
    underwriters = [];
    actionPlanTemplates = [];
    actionPlanTemplatesRaw = []; // Store full data with tasks
    taskSummary = null; // Existing opportunity tasks
    error;

    // Wire underwriters list
    @wire(getUnderwriters)
    wiredUnderwriters({ data, error }) {
        if (data) {
            this.underwriters = data.map(u => ({
                label: `${u.name} (${u.email})`,
                value: u.id
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.underwriters = [];
            this.showToast('Error', 'Failed to load underwriters', 'error');
        }
    }

    // Wire action plan templates
    @wire(getActionPlanTemplates)
    wiredActionPlans({ data, error }) {
        if (data) {
            this.actionPlanTemplatesRaw = data; // Store full data
            this.actionPlanTemplates = data.map(template => ({
                label: template.name,
                value: template.id,
                description: template.description
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.actionPlanTemplates = [];
            this.showToast('Error', 'Failed to load action plans', 'error');
        }
    }

    // Wire existing opportunity tasks
    @wire(getOpportunityTasks, { opportunityId: '$recordId' })
    wiredOpportunityTasks({ data, error }) {
        if (data) {
            this.taskSummary = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.taskSummary = null;
            console.error('Error loading tasks:', error);
        }
    }

    // Computed properties
    get hasUnderwriters() {
        return this.underwriters && this.underwriters.length > 0;
    }

    get hasActionPlans() {
        return this.actionPlanTemplates && this.actionPlanTemplates.length > 0;
    }

    get isFormValid() {
        return this.selectedUnderwriterId && this.selectedActionPlanId;
    }

    get submitDisabled() {
        return !this.isFormValid || this.isLoading;
    }

    get selectedActionPlanDetails() {
        if (!this.selectedActionPlanId || !this.actionPlanTemplatesRaw) {
            return null;
        }
        return this.actionPlanTemplatesRaw.find(t => t.id === this.selectedActionPlanId);
    }

    get hasSelectedActionPlan() {
        return this.selectedActionPlanDetails !== null;
    }

    get actionPlanTasks() {
        if (!this.selectedActionPlanDetails) {
            return [];
        }
        return this.selectedActionPlanDetails.tasks.map(task => ({
            subject: task.subject,
            dueDate: this.calculateDueDate(task.dayOffset),
            priority: task.priority,
            priorityClass: this.getPriorityClass(task.priority)
        }));
    }

    get hasTasks() {
        return this.taskSummary && this.taskSummary.totalTasks > 0;
    }

    get hasNoTasks() {
        return this.taskSummary && this.taskSummary.totalTasks === 0;
    }

    get allTasksComplete() {
        return this.taskSummary && this.taskSummary.incompleteTasks === 0 && this.taskSummary.totalTasks > 0;
    }

    get hasIncompleteTasks() {
        return this.taskSummary && this.taskSummary.incompleteTasks > 0;
    }

    get hasOverdueTasks() {
        return this.taskSummary && this.taskSummary.overdueTasks > 0;
    }

    get completionStatusClass() {
        if (!this.taskSummary || this.taskSummary.totalTasks === 0) {
            return 'slds-text-color_weak';
        }
        if (this.taskSummary.completionPercentage === 100) {
            return 'slds-text-color_success';
        }
        if (this.taskSummary.completionPercentage >= 50) {
            return 'slds-text-color_default';
        }
        return 'slds-text-color_error';
    }

    get progressBarStyle() {
        if (!this.taskSummary) {
            return 'width: 0%';
        }
        return `width: ${this.taskSummary.completionPercentage}%`;
    }

    get overdueLabel() {
        return this.taskSummary ? `${this.taskSummary.overdueTasks} Overdue` : '0 Overdue';
    }

    get incompleteLabel() {
        return this.taskSummary ? `${this.taskSummary.incompleteTasks} Incomplete` : '0 Incomplete';
    }

    get submitButtonLabel() {
        let label = 'Hand Off to Underwriter';

        if (this.selectedActionPlanDetails) {
            const taskCount = this.selectedActionPlanDetails.tasks.length;
            label += ` (${taskCount} tasks will be created)`;
        }

        return label;
    }

    get submitButtonVariant() {
        // Change button color based on task completion
        if (!this.taskSummary || this.taskSummary.totalTasks === 0) {
            return 'brand'; // Default blue
        }
        if (this.allTasksComplete) {
            return 'success'; // Green when all tasks complete
        }
        if (this.hasOverdueTasks) {
            return 'destructive'; // Red when overdue tasks exist
        }
        return 'brand'; // Default blue
    }

    get existingTasks() {
        if (!this.taskSummary || !this.taskSummary.tasks) {
            return [];
        }
        return this.taskSummary.tasks.map(task => ({
            ...task,
            statusClass: task.isCompleted ? 'slds-text-color_success' :
                         task.isOverdue ? 'slds-text-color_error' : 'slds-text-color_default',
            statusIcon: task.isCompleted ? 'utility:check' :
                        task.isOverdue ? 'utility:warning' : 'utility:clock',
            formattedDate: task.activityDate ? new Date(task.activityDate).toLocaleDateString('en-US', {
                month: 'short',
                day: 'numeric',
                year: 'numeric'
            }) : 'No due date'
        }));
    }

    // Event handlers
    handleUnderwriterChange(event) {
        this.selectedUnderwriterId = event.detail.value;
    }

    handleActionPlanChange(event) {
        this.selectedActionPlanId = event.detail.value;
    }

    handleNotesChange(event) {
        this.handoffNotes = event.target.value;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleSubmit() {
        if (!this.isFormValid) {
            this.showToast('Validation Error', 'Please select an underwriter and action plan', 'error');
            return;
        }

        this.isLoading = true;

        try {
            const result = await handoffToUnderwriter({
                opportunityId: this.recordId,
                underwriterId: this.selectedUnderwriterId,
                actionPlanTemplateId: this.selectedActionPlanId,
                notes: this.handoffNotes
            });

            if (result.success) {
                this.showToast('Success', result.message, 'success');

                // Navigate to the created case
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result.caseId,
                        objectApiName: 'Case',
                        actionName: 'view'
                    }
                });

                // Close the action screen
                this.dispatchEvent(new CloseActionScreenEvent());
            } else {
                this.showToast('Handoff Failed', result.message, 'error');
            }
        } catch (error) {
            this.showToast(
                'Error',
                'An unexpected error occurred: ' + this.reduceErrors(error),
                'error'
            );
        } finally {
            this.isLoading = false;
        }
    }

    // Utility methods
    calculateDueDate(dayOffset) {
        const date = new Date();
        date.setDate(date.getDate() + dayOffset);
        return date.toLocaleDateString('en-US', {
            month: 'short',
            day: 'numeric',
            year: 'numeric'
        });
    }

    getPriorityClass(priority) {
        switch(priority) {
            case 'High':
                return 'slds-text-color_error';
            case 'Normal':
                return 'slds-text-color_default';
            case 'Low':
                return 'slds-text-color_weak';
            default:
                return 'slds-text-color_default';
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    reduceErrors(error) {
        if (!error) {
            return 'Unknown error';
        }
        if (Array.isArray(error.body)) {
            return error.body.map(e => e.message).join(', ');
        }
        if (error.body && typeof error.body.message === 'string') {
            return error.body.message;
        }
        if (typeof error.message === 'string') {
            return error.message;
        }
        return JSON.stringify(error);
    }
}
