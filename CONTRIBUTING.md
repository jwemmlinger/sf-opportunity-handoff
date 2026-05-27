# Contributing to Salesforce Opportunity Handoff Component

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the community
- Show empathy towards other community members

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the behavior
- **Expected behavior**
- **Actual behavior**
- **Screenshots** if applicable
- **Salesforce org edition** (Developer, Enterprise, Unlimited, etc.)
- **API version**

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. Include:

- **Use case** - Why is this enhancement needed?
- **Proposed solution** - How should it work?
- **Alternatives considered** - What other approaches did you think about?

### Pull Requests

1. Fork the repo and create your branch from `main`
2. Make your changes
3. Add tests if applicable
4. Ensure all tests pass
5. Update documentation
6. Submit a pull request

#### Pull Request Guidelines

- Follow Salesforce coding conventions
- Include descriptive commit messages
- Update the README.md if needed
- Add yourself to CONTRIBUTORS.md

## Development Setup

```bash
# Clone your fork
git clone https://github.com/jwemmlinger/sf-opportunity-handoff.git
cd sf-opportunity-handoff

# Install dependencies
npm install

# Create a scratch org
sf org create scratch --definition-file config/project-scratch-def.json --alias dev-scratch --set-default

# Deploy to scratch org
sf project deploy start

# Open the org
sf org open
```

## Coding Standards

### Apex

- Use descriptive variable and method names
- Add JavaDoc comments to public methods
- Follow `with sharing` security model
- Use `WITH SECURITY_ENFORCED` in SOQL
- Check FLS with `Security.stripInaccessible()`
- Maximum method length: 50 lines
- Maximum class length: 500 lines

### Lightning Web Components

- Follow JavaScript ES6+ standards
- Use descriptive property names
- Add JSDoc comments to public properties and methods
- Maximum component size: 400 lines
- Use composition over inheritance
- Follow SLDS design patterns

### Testing

- Apex: Minimum 85% code coverage (aim for 90%+)
- LWC: Test all public methods and user interactions
- Use meaningful test method names
- Include positive, negative, and edge case tests

## Testing Your Changes

### Apex Tests

```bash
sf apex run test --test-level RunLocalTests --output-dir ./test-results --result-format human
```

### LWC Jest Tests

```bash
npm run test:unit
npm run test:unit:watch  # Run in watch mode during development
npm run test:unit:coverage  # Generate coverage report
```

### Manual Testing Checklist

- [ ] Component loads without errors
- [ ] Underwriter dropdown populates
- [ ] Action plan dropdown populates
- [ ] Task checklist displays correctly
- [ ] Progress bar calculates accurately
- [ ] Submit creates Case with tasks
- [ ] Opportunity stage updates
- [ ] Chatter notification posts
- [ ] Navigation to Case works
- [ ] Cancel button closes modal
- [ ] Error handling displays properly

## Documentation

- Update README.md for new features
- Add inline code comments for complex logic
- Update CHANGELOG.md following [Keep a Changelog](https://keepachangelog.com/)
- Include screenshots for UI changes

## Git Workflow

### Branch Naming

- `feature/short-description` - New features
- `bugfix/issue-number-description` - Bug fixes
- `docs/description` - Documentation only
- `refactor/description` - Code refactoring

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add email notification option
fix: resolve task completion calculation bug
docs: update installation instructions
refactor: simplify action plan template logic
test: add tests for handoff validation
```

## Release Process

Maintainers will:

1. Review and merge PRs
2. Update version in `sfdx-project.json`
3. Update CHANGELOG.md
4. Create GitHub release
5. Build and publish unlocked package (future)

## Questions?

- Open a [Discussion](https://github.com/jwemmlinger/sf-opportunity-handoff/discussions)
- Tag [@maintainer] in an issue
- Email: [your-email@example.com]

## Recognition

Contributors will be recognized in:
- CONTRIBUTORS.md file
- Release notes
- README.md acknowledgments

Thank you for contributing to make this component better! 🎉
