# Job Opportunity Email Flow - Implementation Guide

## Workflows
- **Main orchestrator**: `Main.xaml` (Primary entry point)
- **Mode dispatcher**: `Workflows\CandidateEmail\Dispatch_JobEmail.xaml` (Handles Drive downloads and user interaction)
- **Job Logic & Resolver**: `Workflows\CandidateEmail\Process_SendEmail.xaml` (Builds HTML body from template and job data)
- **Gmail Sender Module**: `Workflows\CandidateEmail\Module_SendGmail.xaml` (Low-level send command via Integration Service)
- **Template Builder**: `Workflows\CandidateEmail\BuildEmailTemplate.xaml` (Helper to load HTML templates)

## Design & Workflow
1. **Source Data**:
   - Job list is dynamically downloaded from Google Drive to `Data\Input\Jobs_FromDrive.xlsx`.
   - Recipient group list is dynamically downloaded to `Data\Input\GroupEmails_FromDrive.xlsx` (if chosen).
2. **User Interaction**:
   - Prompt to select a specific Job ID or "ALL".
   - Prompt to choose between "Specific Recipient" (manual input) or "Drive Group".
   - Prompt to select the Email Template (Weekly, Spring, Summer, Autumn, Winter).
3. **Execution**:
   - Robot loops through all recipients.
   - For each recipient, it generates a personalized HTML body using the chosen template and job data.
   - Sends the email using Gmail Integration Service.
   - Logs results (Email, Job IDs, Status, Timestamp) to `Data\Output\Logs.xlsx`.

## Required Config keys (`Data\Config.xlsx`)
- `GmailConnectionId`: Integration Service connection ID for Gmail.
- `JobEmail_SubjectTemplate`: Default subject line (e.g., "Job Opportunities").
- `JobEmail_LogsPath`: Path to the log file (default: `Data\Output\Logs.xlsx`).
- `JobEmail_DelayMs`: Delay between sending emails to prevent flooding (default: `3000`).

## Email Templates (`Templates\`)
- Standard HTML files with placeholders like `{{Name}}`, `{{Email}}`, `{{JobsTableContent}}`, and `{{Qualifications}}`.
- Located in the `Templates` folder.

## Running the Process
- Simply run `Main.xaml`.
- Follow the interactive prompts in the UiPath Studio/Assistant interface to select jobs, recipients, and templates.
