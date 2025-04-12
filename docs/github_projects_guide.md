
# GitHub Projects Guide for Dayliz App

This guide explains how to use GitHub Projects to manage the Dayliz App development process.

## Project Board Structure

Our GitHub Project board follows a Kanban-style workflow with the following columns:

1. **Backlog**: All planned tasks that are not yet ready to be worked on
2. **Ready**: Tasks that are ready to be picked up by team members
3. **In Progress**: Tasks currently being worked on
4. **Review**: Tasks that need review (code review, design review, etc.)
5. **Done**: Completed tasks

## Phases

The Dayliz App is being developed in five sequential phases:

1. **Foundation Setup**: Authentication, design system, components, navigation, backend scaffolding
2. **Product Browsing + UI Polish**: Product catalog, UI implementation, cart functionality, animations
3. **Checkout & Payment**: Address management, cart & order flow, payment integration, order management
4. **User Profile + Order History**: User profile, order history, delivery tracking, notifications
5. **Polish & Launch Prep**: UI finalization, error handling, performance optimization, launch preparation

## Issue Labels

We use the following labels to categorize issues:

- `phase-1`, `phase-2`, `phase-3`, `phase-4`, `phase-5`: Development phase
- `effort-1`, `effort-2`, `effort-3`, `effort-5`: Effort estimation
- `frontend`, `backend`, `database`, `devops`, `documentation`: Component
- `bug`, `feature`, `task`: Issue type
- `priority-low`, `priority-medium`, `priority-high`, `priority-critical`: Priority level

## Creating Issues

1. Go to the Issues tab in the repository
2. Click "New Issue"
3. Select the appropriate template (Feature, Bug, or Task)
4. Fill in the required information
5. Submit the issue

Our automated workflow will add appropriate labels based on your selections.

## Working with GitHub Projects

### Adding Issues to the Project

1. Navigate to the issue
2. In the right sidebar, click "Projects"
3. Select the Dayliz App project
4. The issue will be automatically added to the Backlog column

### Moving Issues Between Columns

1. Navigate to the Project board
2. Drag and drop issues between columns as they progress
3. Alternatively, click on the issue card and update the Status field

### Creating a Sprint

1. Filter the Backlog by phase (e.g., `phase-1`)
2. Prioritize issues by dragging them to the top
3. Move the top priority issues to the Ready column
4. Assign team members to issues

## Pull Requests

When creating a pull request:

1. Reference the related issue with "Fixes #issue_number"
2. Fill out the pull request template completely
3. Assign reviewers
4. Link the pull request to the project

## Tips for Effective Project Management

1. **Regular Updates**: Update issue status daily
2. **Clear Descriptions**: Write clear descriptions and acceptance criteria
3. **Link Related Issues**: Use "Related to #issue_number" to link related issues
4. **Use Milestones**: Create milestones for each phase to track progress
5. **Add Comments**: Keep all relevant discussions in the issue comments for documentation

## Workflow Example

1. Issue "Implement Login Screen" is created and added to Backlog
2. Issue is moved to Ready when it's prioritized for the current sprint
3. Developer assigns themselves and moves it to In Progress
4. Developer creates a branch, implements the feature, and creates a PR
5. PR is reviewed, and the issue is moved to Review
6. After review and testing, the PR is merged and the issue is moved to Done 
