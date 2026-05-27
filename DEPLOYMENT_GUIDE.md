# Deployment Guide

This guide walks through deploying the Opportunity Handoff component to your Salesforce org.

## Prerequisites

- Salesforce CLI (sf) installed - [Install Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_install_cli.htm)
- Git installed
- Access to a Salesforce org (Developer, Sandbox, Production, etc.)
- Sufficient permissions to deploy metadata and create Quick Actions

## Quick Start (5 minutes)

### 1. Clone and Deploy

```bash
# Clone the repository
git clone https://github.com/jwemmlinger/sf-opportunity-handoff.git
cd sf-opportunity-handoff

# Authenticate to your org
sf org login web --alias myorg --set-default

# Deploy to your org
sf project deploy start --target-org myorg

# Open your org
sf org open --target-org myorg
```

### 2. Create Quick Action

1. In Setup, navigate to: **Object Manager → Opportunity → Buttons, Links, and Actions**
2. Click **New Action**
3. Configure:
   - Action Type: **Lightning Component**
   - Lightning Component: **c:opportunityHandoff**
   - Height: **600**
   - Label: **Hand Off to Underwriter**
   - Name: **Hand_Off_to_Underwriter**
   - Icon: Search for "handoff" or "share"
4. Click **Save**

### 3. Add to Page Layout

1. Navigate to: **Object Manager → Opportunity → Page Layouts**
2. Edit your default Opportunity Layout
3. In the **Salesforce Mobile and Lightning Experience Actions** section:
   - Click the wrench icon
   - Drag **Hand Off to Underwriter** to the actions list
   - Click **Save**

### 4. Test It Out

1. Open any Opportunity record
2. Click the **Hand Off to Underwriter** action in the highlights panel
3. Select an underwriter and action plan
4. Click **Hand Off to Underwriter**
5. You'll be navigated to the newly created Case!

## Detailed Deployment Options

### Option A: Scratch Org (for development/testing)

```bash
# Create scratch org
sf org create scratch --definition-file config/project-scratch-def.json \
  --alias handoff-scratch --set-default --duration-days 7

# Deploy code
sf project deploy start

# Generate test data (optional)
sf apex run --file scripts/apex/generate-test-data.apex

# Open scratch org
sf org open
```

### Option B: Sandbox

```bash
# Login to sandbox
sf org login web --alias my-sandbox --instance-url https://test.salesforce.com

# Deploy with tests
sf project deploy start --target-org my-sandbox --test-level RunLocalTests

# Check deployment status
sf project deploy report --target-org my-sandbox
```

### Option C: Production

**⚠️ Important: Test thoroughly in Sandbox first!**

```bash
# Validate deployment (doesn't actually deploy)
sf project deploy validate --target-org production \
  --test-level RunLocalTests

# If validation succeeds, deploy
sf project deploy start --target-org production \
  --test-level RunLocalTests
```

### Option D: Change Set

1. Deploy to sandbox first
2. In Sandbox Setup: **Outbound Change Sets**
3. Create new Change Set: "Opportunity Handoff Component"
4. Add components:
   - Lightning Component: **opportunityHandoff**
   - Apex Class: **OpportunityHandoffController**
5. Upload to Production
6. In Production Setup: **Inbound Change Sets**
7. Deploy the change set

## Post-Deployment Configuration

### Create Underwriting Stage

1. Setup → **Object Manager → Opportunity**
2. **Fields & Relationships → Stage**
3. Click the Stage field
4. Add a new picklist value: **Underwriting**
5. Add to your Opportunity Record Type sales processes

### Optional: Create Custom Fields

For enhanced tracking, create these fields on Opportunity:

#### Underwriter Field
- Label: **Underwriter**
- API Name: **Underwriter__c**
- Type: **Lookup(User)**
- Help Text: "The underwriter assigned to review this opportunity"

#### Handoff Date Field
- Label: **Handoff Date**
- API Name: **Handoff_Date__c**
- Type: **Date**
- Help Text: "Date when opportunity was handed off to underwriting"

#### Action Plan Template Field
- Label: **Action Plan Template**
- API Name: **Action_Plan_Template__c**
- Type: **Text(255)**
- Help Text: "Name of action plan template used for underwriting"

After creating fields, update the Apex controller (line 311):

```apex
opp.Underwriter__c = underwriterId;
opp.Handoff_Date__c = Date.today();
opp.Action_Plan_Template__c = actionPlanTemplateId;
```

### Configure Permissions

Ensure users have these permissions:

- **Read** on Opportunity
- **Create** on Case
- **Create** on Task
- **Create** on FeedItem (for Chatter posts)
- Access to the Lightning Component

Create a Permission Set if needed:

1. Setup → **Permission Sets → New**
2. Name: **Opportunity Handoff User**
3. Add Object Settings:
   - Case: Create, Read
   - Task: Create, Read, Edit
   - Opportunity: Read, Edit
4. Assign to users

### Customize Action Plan Templates

Edit `OpportunityHandoffController.cls` method `getActionPlanTemplates()` (line 158):

```apex
// Add your custom template
List<ActionPlanTask> myTasks = new List<ActionPlanTask>{
    new ActionPlanTask('First Task', 1, 'High'),
    new ActionPlanTask('Second Task', 3, 'Normal')
};
templates.add(new ActionPlanTemplate(
    'my_custom_template',
    'My Custom Template',
    'Description here',
    myTasks
));
```

Then add task creation logic in `createActionPlanTasks()` (line 373):

```apex
else if (templateId == 'my_custom_template') {
    tasks.add(createTask(caseId, 'First Task', 1));
    tasks.add(createTask(caseId, 'Second Task', 3));
}
```

## Verification

### Test the Component

1. Navigate to an Opportunity
2. Add some Tasks to the Opportunity (to test the checklist)
3. Click **Hand Off to Underwriter**
4. Verify:
   - ✅ Underwriter dropdown populates
   - ✅ Action plan dropdown shows templates
   - ✅ Task checklist displays (if tasks exist)
   - ✅ Can select underwriter and action plan
   - ✅ Submit button enables when both selected
   - ✅ Clicking submit creates a Case
   - ✅ Case has Tasks from action plan
   - ✅ Opportunity stage updates to "Underwriting"
   - ✅ Navigates to the Case record

### Run Apex Tests

```bash
sf apex run test --class-names OpportunityHandoffController \
  --result-format human --code-coverage
```

Target: **85%+ code coverage**

## Troubleshooting

### Deploy Fails with "Cannot find Lightning Component"

- Ensure API version is 60.0+
- Check `opportunityHandoff.js-meta.xml` has `isExposed` set to `true`

### "No underwriters found" message

- Check users exist and are active
- Modify filter query in line 102 of controller if needed

### Quick Action doesn't appear

- Verify you added it to the page layout
- Check Lightning App permissions
- Try refreshing browser cache (Cmd+Shift+R / Ctrl+F5)

### Case creates but no tasks

- Check user has Create permission on Task
- Verify action plan template ID matches logic in controller
- Check debug logs for errors

### Stage update fails

- Add "Underwriting" stage to your sales process
- Or change the stage name in line 310 of controller

## Rollback

If you need to remove the component:

```bash
# Create destructiveChanges.xml
cat > destructiveChanges.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>opportunityHandoff</members>
        <name>LightningComponentBundle</name>
    </types>
    <types>
        <members>OpportunityHandoffController</members>
        <name>ApexClass</name>
    </types>
    <version>62.0</version>
</Package>
EOF

# Deploy destructive changes
sf project deploy start --metadata-dir . --pre-destructive-changes destructiveChanges.xml
```

Or manually:
1. Remove Quick Action from page layouts
2. Delete the Quick Action
3. Setup → Apex Classes → Delete OpportunityHandoffController
4. Setup → Lightning Components → Delete opportunityHandoff

## Next Steps

- Customize action plan templates for your business
- Add custom fields for better tracking
- Configure email notifications (optional)
- Create reports on underwriting metrics
- Set up list views for underwriting cases

## Support

Questions? Check:
- [README](README.md) - Full documentation
- [Issues](https://github.com/jwemmlinger/sf-opportunity-handoff/issues) - Known issues
- [Discussions](https://github.com/jwemmlinger/sf-opportunity-handoff/discussions) - Community help

---

**Estimated deployment time**: 15 minutes (including configuration)
