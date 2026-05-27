# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-05-27

### Added
- Initial release of Opportunity Handoff component
- Lightning Web Component for opportunity handoff UI
- Apex controller with security enforcement
- Pre-handoff task checklist with completion tracking
- Progress bar visualization
- Three action plan templates:
  - Standard Underwriting Review (5 tasks)
  - Expedited Review (3 tasks)
  - Complex Case Review (6 tasks)
- Underwriter selection from active users
- Task preview before handoff
- Automated Case creation with action plan tasks
- Opportunity stage update to "Underwriting"
- Chatter notification to assigned underwriter
- Warning badges for incomplete and overdue tasks
- Dynamic submit button styling based on task status
- Navigation to created Case after handoff
- Comprehensive error handling
- Security features:
  - WITH SECURITY_ENFORCED in SOQL queries
  - Field-Level Security checks
  - Sharing model enforcement
- Jest test suite for LWC
- ESLint configuration
- Prettier formatting
- GitHub Actions CI workflow
- Comprehensive README documentation
- MIT License
- Contributing guidelines

### Security
- All SOQL queries use `WITH SECURITY_ENFORCED`
- FLS validation with `Security.stripInaccessible()`
- Apex class implements `with sharing`

## [Unreleased]

### Planned
- Email notification option (in addition to Chatter)
- Unlocked package for easier distribution
- Custom object support (beyond Opportunity)
- Bulk handoff for multiple opportunities
- Action plan template builder UI
- Enhanced analytics dashboard
- Mobile-optimized responsive design
- Localization support (i18n)
- Additional action plan templates
- Integration with Salesforce Flows
- Custom field mapping configuration UI
