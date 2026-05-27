# Salesforce Opportunity Handoff Component

A Lightning Web Component (LWC) that enables loan officers to hand off opportunities to underwriters with action plan templates and task management.

![Opportunity Handoff Component](docs/images/handoff-screenshot.png)

## Features

- **Pre-Handoff Task Checklist** - Visual progress tracking with completion percentage
- **Underwriter Selection** - Choose from available underwriters in your org
- **Action Plan Templates** - Select from Standard, Expedited, or Complex review workflows
- **Task Preview** - See what tasks will be created before handoff
- **Smart Validation** - Warning indicators for incomplete or overdue tasks
- **Automated Case Creation** - Creates underwriting case with tasks
- **Stage Automation** - Updates opportunity stage to "Underwriting"
- **Chatter Notifications** - Notifies assigned underwriter

## Use Cases

- **Mortgage Lending** - Hand off loan applications to underwriting teams
- **Commercial Lending** - Route business loan opportunities
- **Insurance Underwriting** - Transfer policy applications
- **Any Opportunity Handoff** - Adaptable to any business process requiring opportunity transfer

## Installation

### Option 1: Deploy from Source

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/sf-opportunity-handoff.git
cd sf-opportunity-handoff

# Authenticate to your org
sf org login web --alias myorg

# Deploy to your org
sf project deploy start --target-org myorg
```

### Option 2: Deploy Using Metadata API

1. Download the ZIP file from the [Releases](https://github.com/YOUR_USERNAME/sf-opportunity-handoff/releases) page
2. Navigate to Setup → Deploy → Deploy in your Salesforce org
3. Upload the ZIP file and deploy

### Option 3: Use Unlocked Package (Coming Soon)

```bash
sf package install --package 04t...
```

## Post-Installation Setup

### 1. Add to Opportunity Page Layout

1. Navigate to Setup → Object Manager → Opportunity
2. Go to Lightning Record Pages
3. Select your Opportunity Record Page
4. Add the component or create a Quick Action (see below)

### 2. Create Quick Action (Recommended)

1. Navigate to Setup → Object Manager → Opportunity → Buttons, Links, and Actions
2. Click **New Action**
3. Action Type: **Lightning Component**
4. Lightning Component: **c:opportunityHandoff**
5. Label: **Hand Off to Underwriter**
6. Icon: Choose an appropriate icon
7. Save and add to Page Layout

### 3. (Optional) Create Custom Fields

For enhanced functionality, create these optional custom fields on Opportunity:

- `Underwriter__c` (Lookup to User) - Stores assigned underwriter
- `Handoff_Date__c` (Date) - Records when handoff occurred
- `Action_Plan_Template__c` (Text) - Stores selected template name

Update the Apex controller to reference these fields:

```apex
// Line 311 in OpportunityHandoffController.cls
opp.Underwriter__c = underwriterId;
opp.Handoff_Date__c = Date.today();
opp.Action_Plan_Template__c = actionPlanTemplateId;
```

### 4. Configure Opportunity Stages

Ensure your Opportunity has an "Underwriting" stage, or update line 310 in the controller:

```apex
opp.StageName = 'Your_Stage_Name_Here';
```

## Configuration

### Customize Action Plan Templates

Edit `OpportunityHandoffController.cls` (lines 158-209) to customize templates:

```apex
List<ActionPlanTask> customTasks = new List<ActionPlanTask>{
    new ActionPlanTask('Your Task Name', 1, 'High'),  // Due in 1 day
    new ActionPlanTask('Another Task', 3, 'Normal')   // Due in 3 days
};
templates.add(new ActionPlanTemplate(
    'custom_template_id',
    'Custom Template Name',
    'Description of this workflow',
    customTasks
));
```

### Filter Underwriters

By default, the component shows all active users. To filter by profile or role, update line 102:

```apex
List<User> underwriters = [
    SELECT Id, Name, Email
    FROM User
    WHERE IsActive = true
      AND (Profile.Name LIKE '%Underwriter%' 
           OR UserRole.Name LIKE '%Underwriter%')
    WITH SECURITY_ENFORCED
    ORDER BY Name
    LIMIT 200
];
```

### Customize Notification

Modify the Chatter notification in `sendHandoffNotification()` method (line 418) or replace with email:

```apex
Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
mail.setToAddresses(new String[] { underwriter.Email });
mail.setSubject('New Underwriting Case Assigned');
mail.setPlainTextBody('You have been assigned case: ' + underwrightCase.CaseNumber);
Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
```

## Architecture

### Component Structure

```
force-app/main/default/
├── lwc/
│   └── opportunityHandoff/
│       ├── opportunityHandoff.html      # Component template
│       ├── opportunityHandoff.js        # Component logic
│       ├── opportunityHandoff.css       # Styling
│       ├── opportunityHandoff.js-meta.xml  # Metadata config
│       └── __tests__/                   # Jest tests
└── classes/
    ├── OpportunityHandoffController.cls      # Apex controller
    └── OpportunityHandoffController.cls-meta.xml
```

### Data Flow

1. User opens component from Opportunity quick action
2. Component loads:
   - List of underwriters (via `getUnderwriters()`)
   - Action plan templates (via `getActionPlanTemplates()`)
   - Existing opportunity tasks (via `getOpportunityTasks()`)
3. User selects underwriter, action plan, and adds notes
4. On submit, `handoffToUnderwriter()`:
   - Creates a Case assigned to the underwriter
   - Creates tasks from the action plan template
   - Updates Opportunity stage
   - Posts Chatter notification
   - Navigates user to the new Case

### Security

- All SOQL queries use `WITH SECURITY_ENFORCED`
- FLS (Field-Level Security) is checked using `Security.stripInaccessible()`
- Apex class is `with sharing` to respect record access

## Testing

### Run Apex Tests

```bash
sf apex run test --test-level RunLocalTests --output-dir ./test-results --result-format human
```

### Run LWC Jest Tests

```bash
npm install
npm run test:unit
```

## Troubleshooting

### "No underwriters found"

- Ensure you have active users in your org
- Check the underwriter filter query (line 102 in controller)
- Verify users have necessary permissions

### "Could not update Opportunity stage"

- Add the "Underwriting" stage to your Opportunity sales process
- Or customize the stage name in line 310 of the controller

### Tasks not creating

- Verify the action plan template ID matches the method logic (lines 378-395)
- Check that users have permission to create Tasks on Cases

### Quick Action not appearing

- Ensure you added the action to the Opportunity page layout
- Verify the component is set as `isExposed` in the metadata
- Check Lightning App Builder permissions

## Customization Examples

### Add Custom Fields to Case

```apex
// Line 283 in OpportunityHandoffController.cls
Case underwrightCase = new Case(
    Subject = 'Underwriting Review: ' + opp.Name,
    Description = buildCaseDescription(opp, underwriter, notes),
    Status = 'New',
    Priority = 'Medium',
    OwnerId = underwriterId,
    AccountId = opp.AccountId,
    Origin = 'Loan Officer Handoff',
    Type = 'Underwriting Review',  // Add custom fields
    Loan_Amount__c = opp.Amount
);
```

### Change Submit Button Behavior

Edit `handleSubmit()` method in `opportunityHandoff.js` (line 221) to:
- Show confirmation modal
- Add validation logic
- Navigate to different record page

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/sf-opportunity-handoff/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YOUR_USERNAME/sf-opportunity-handoff/discussions)
- **Trailblazer Community**: Tag your questions with `opportunity-handoff`

## Changelog

### v1.0.0 (2026-05-27)
- Initial release
- Core handoff functionality
- Three action plan templates
- Task management and progress tracking
- Chatter notifications

## Roadmap

- [ ] Unlocked package distribution
- [ ] Email notifications option
- [ ] Custom object support (not just Opportunity)
- [ ] Bulk handoff capability
- [ ] Action plan template builder UI
- [ ] Analytics dashboard
- [ ] Mobile optimization

## Credits

Built with ❤️ for the Salesforce community

---

**Keywords**: Salesforce, Lightning Web Component, LWC, Opportunity Management, Underwriting, Loan Origination, Action Plans, Task Management
