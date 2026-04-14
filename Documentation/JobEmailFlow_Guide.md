# Job Opportunity Email Flow - Implementation Guide

## New workflows
- Main orchestration (dispatcher): `Main.xaml`
- Legacy REFramework backup: `Main_REFrameworkLegacy.xaml`
- Dedicated email main: `Main_JobEmail.xaml`
- Mode dispatcher: `Workflows\CandidateEmail\Dispatch_JobEmail.xaml`
- Reusable sender: `Workflows\CandidateEmail\Process_SendEmail.xaml`
- Existing sender updated: `Workflows\CandidateEmail\SendWeeklyEmail.xaml`

## Design
- `Main.xaml`:
  - Read config from `Data\Config.xlsx` (Settings + Constants)
  - Decide branch:
  - `MainDispatcherMode=JOBEMAIL` -> invoke `Dispatch_JobEmail.xaml`
  - `MainDispatcherMode=LEGACY` -> invoke `Main_REFrameworkLegacy.xaml`
- `Dispatch_JobEmail.xaml`:
  - Decide mode from config: `AUTO` or `MANUAL`
  - Read jobs file
  - Build recipient list (Excel in AUTO, Input Dialog in MANUAL)
  - Deduplicate + validate emails
  - Loop recipients and call reusable `Process_SendEmail.xaml`
  - Add delay between sends
  - Write logs to `Logs.xlsx`
- `Process_SendEmail.xaml`:
  - Build HTML email body from predefined jobs
  - Filter jobs by optional Job IDs (manual mode)
  - Send email
  - Return status/error/result job IDs for logging

## Required Config keys (add in `Config.xlsx` -> Settings)
- `MainDispatcherMode` = `JOBEMAIL` or `LEGACY`
- `JobEmail_Mode` = `AUTO` or `MANUAL`
- `JobEmail_EmailListPath` = `Data\Input\EmailList.xlsx`
- `JobEmail_EmailSheet` = `Sheet1`
- `JobEmail_JobsPath` = `Data\Input\Jobs.xlsx`
- `JobEmail_JobsSheet` = `Sheet1`
- `JobEmail_LogsPath` = `Data\Output\Logs.xlsx`
- `JobEmail_LogsSheet` = `Logs`
- `JobEmail_DelayMs` = `3000`
- `JobEmail_SubjectTemplate` = `Weekly Job Opportunities`
- `JobEmail_AttachmentPath` = optional (blank allowed)
- `GmailConnectionId` = your Integration Service connection id

## Data format
### Jobs.xlsx (required columns)
- `JobID`
- `Title`
- `Description`
- `Link`

### EmailList.xlsx (required columns)
- `Email`

### Logs.xlsx output columns
- `Email`
- `JobIDs`
- `Timestamp`
- `Status`
- `Error Message`

## Running
- Run process entrypoint: `Main.xaml`
- For email campaign flow: set `MainDispatcherMode=JOBEMAIL`
- For old REFramework flow: set `MainDispatcherMode=LEGACY`
- Schedule weekly in Orchestrator using `Main.xaml` + `MainDispatcherMode=JOBEMAIL` + `JobEmail_Mode=AUTO`
- For on-demand run, set `JobEmail_Mode=MANUAL`.
