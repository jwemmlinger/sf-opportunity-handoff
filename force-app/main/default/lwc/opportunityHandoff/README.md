# Opportunity Handoff Component

## Overview
Lightning Web Component that allows loan officers to hand off opportunities to underwriters with integrated action plan task creation.

## Features
- **Underwriter Selection**: Dynamically loads active users with Underwriter profile/role
- **Action Plan Templates**: Choose from predefined underwriting workflows
- **Case Creation**: Automatically creates a Case linked to the Opportunity
- **Task Generation**: Creates action plan tasks on the case based on selected template
- **Opportunity Update**: Updates opportunity stage to "Underwriting"
- **Navigation**: Automatically navigates to the newly created case after handoff

## Components

### LWC Component
- **opportunityHandoff.js** - Main component logic
- **opportunityHandoff.html** - UI template
- **opportunityHandoff.css** - Styling
- **opportunityHandoff.js-meta.xml** - Metadata configuration

### Apex Controller
- **OpportunityHandoffController.cls** - Server-side logic
  - `getUnderwriters()` - Fetches available underwriters
  - `getActionPlanTemplates()` - Returns action plan templates
  - `handoffToUnderwriter()` - Executes the handoff process

## Setup Instructions

### 1. Deploy the Component
```bash
sf project deploy start --source-dir force-app/main/default/lwc/opportunityHandoff
sf project deploy start --source-dir force-app/main/default/classes/OpportunityHandoffController.cls
```

### 2. Create Custom Fields (Optional)
Add these fields to enhance functionality:

**On Opportunity:**
- `Underwriter__c` (Lookup to User) - Tracks assigned underwriter

**On Case:**
- `Opportunity__c` (Lookup to Opportunity) - Links case to opportunity
- `Loan_Officer__c` (Lookup to User) - Tracks originating loan officer
- `Action_Plan_Template__c` (Text/Picklist) - Stores selected template

Uncomment the corresponding lines in `OpportunityHandoffController.cls` after creating these fields.

### 3. Add Quick Action to Opportunity
1. Navigate to **Setup → Object Manager → Opportunity → Buttons, Links, and Actions**
2. Click **New Action**
3. Select **Lightning Web Component** as action type
4. Choose `c:opportunityHandoff`
5. Label: "Hand Off to Underwriter"
6. Click **Save**
7. Add the action to the Opportunity page layout

### 4. Configure Underwriter Access
Ensure underwriters have a profile or role with "Underwriter" in the name, or modify the SOQL query in `getUnderwriters()` to match your org's configuration.

### 5. Customize Action Plans
Edit the `getActionPlanTemplates()` and `createActionPlanTasks()` methods to align with your organization's underwriting workflows.

## Usage

### For Loan Officers
1. Open an Opportunity record
2. Click the **"Hand Off to Underwriter"** quick action button
3. Select an underwriter from the dropdown
4. Choose an action plan template
5. Optionally add handoff notes
6. Click **"Hand Off to Underwriter"**
7. You'll be navigated to the newly created Case

### What Happens Behind the Scenes
1. A new Case is created with:
   - Subject: "Underwriting Review: [Opportunity Name]"
   - Owner: Selected underwriter
   - Status: New
   - Description: Includes opportunity details and notes
2. Action plan tasks are created on the Case
3. Opportunity stage is updated to "Underwriting"
4. Opportunity's Underwriter field is populated (if custom field exists)
5. Chatter notification is posted to the Case (optional)

## Action Plan Templates

### Standard Review
- Review Loan Application (Day 1)
- Verify Income Documentation (Day 2)
- Credit History Review (Day 3)
- Property Appraisal Review (Day 4)
- Final Approval Decision (Day 5)

### Expedited Review
- Fast Track Document Review (Day 1)
- Automated Credit Check (Day 2)
- Express Approval (Day 3)

### Complex Review
- Comprehensive Application Review (Day 1)
- Advanced Income Verification (Day 2)
- Risk Assessment Analysis (Day 3)
- Compliance Review (Day 4)
- Senior Underwriter Consultation (Day 5)
- Final Decision & Documentation (Day 6)

## Customization Options

### Modify Underwriter Query
In `OpportunityHandoffController.cls`, update the query in `getUnderwriters()`:

```apex
List<User> underwriters = [
    SELECT Id, Name, Email
    FROM User
    WHERE IsActive = true
      AND Profile.Name = 'Underwriter'  // Adjust as needed
    WITH SECURITY_ENFORCED
    ORDER BY Name
    LIMIT 200
];
```

### Add Email Notifications
Implement in the `sendHandoffNotification()` method:

```apex
Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
email.setTargetObjectId(underwriter.Id);
email.setSubject('New Underwriting Case Assigned');
email.setPlainTextBody('You have been assigned case: ' + underwrightCase.CaseNumber);
Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
```

### Integrate with Standard Action Plans
If your org uses Salesforce Action Plans (package), uncomment the ActionPlanTemplate query in `getActionPlanTemplates()`.

## Testing

Run Jest tests:
```bash
npm test -- opportunityHandoff
```

## Accessibility
- ARIA labels on all interactive elements
- Keyboard navigation support
- Screen reader compatible
- SLDS 2.0 compliant styling

## Browser Support
- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

## Known Limitations
- Underwriter query limited to 200 users
- Action plan templates are hardcoded (can be replaced with dynamic query)
- Requires Case object write access

## Future Enhancements
- Bulk handoff for multiple opportunities
- Email template configuration
- Custom notification channels (Slack, Teams)
- Document attachment from Opportunity to Case
- Real-time status tracking dashboard

## Support
For issues or questions, contact your Salesforce administrator.
