# 🏗️ Job Posting Automation - Cấu trúc dự án

## 📊 Tổng quan

Hệ thống tự động hóa gửi email thông báo việc làm cho ứng viên, bao gồm:
- ✅ Chọn jobs và recipients (Auto/Manual)
- ✅ Preview và confirm trước khi gửi
- ✅ Generate PDF với BR Omega font
- ✅ Gửi email hàng loạt
- ✅ Theo dõi delivery status

---

## 📁 Cấu trúc thư mục

```
JobPosting_FINAL/
│
├── 📂 Workflows/                          [WORKFLOWS CHÍNH]
│   └── 📂 CandidateEmail/
│       ├── 📂 1_Entry/                    Entry points
│       │   ├── Dispatcher.xaml            Main dispatcher
│       │   └── JobSelection.xaml          Job & mode selection
│       │
│       ├── 📂 2_Processing/               Business logic
│       │   ├── ProcessBatch.xaml          Batch processing
│       │   ├── Process_SendEmail.xaml     Send single email
│       │   └── GeneratePDF.xaml           PDF generation (1x per batch)
│       │
│       ├── 📂 3_Review/                   Review & confirm
│       │   └── ReviewPhase.xaml           Email preview
│       │
│       ├── 📂 4_Monitoring/               Status tracking
│       │   ├── CheckEmailStatus.xaml      Entry point
│       │   ├── Process_DeliveryStatusNotifications.xaml
│       │   ├── Process_BounceEmailAnalysis.xaml        NEW: Bounce analysis
│       │   ├── CheckEmailStatus_WithDashboard.xaml     NEW: Main bounce workflow
│       │   └── Demo_BounceAnalysis_Standalone.xaml     NEW: Demo with samples
│       │
│       ├── 📂 5_Modules/                  Reusable modules
│       │   └── Module_SendGmail.xaml      Gmail sender
│       │
│       └── README.md                      Workflow documentation
│
├── 📂 Data/                               [DỮ LIỆU & UI]
│   ├── 📂 UI/                             HTML dashboards
│   │   ├── Dashboard.html                 Main dashboard
│   │   ├── dashboard_data.js              Jobs data
│   │   ├── Review.html                    Email preview
│   │   ├── review_data.js                 Preview data
│   │   ├── EmailStatusReport.html         Delivery status
│   │   └── email_status_data.js           Status data
│   │
│   ├── 📂 Fonts/                          BR Omega fonts
│   │   ├── BROmega-Regular-*.otf
│   │   ├── BROmega-Medium-*.otf
│   │   └── BROmega-Bold-*.otf
│   │
│   ├── 📂 Input/                          Input files
│   │   ├── Jobs_Local.xlsx                Jobs list
│   │   ├── Emails_Local.xlsx              Emails list
│   │   └── Job_Description.pdf            Generated PDF
│   │
│   ├── 📂 Output/                         Execution reports
│   │   ├── ExecutionReport_*.xlsx
│   │   ├── BounceEmailDashboard.html      NEW: Bounce analysis dashboard
│   │   ├── start_dashboard_server.py      NEW: HTTP server
│   │   └── SentEmails.txt                 NEW: Sent emails list
│   │
│   ├── 📂 Temp/                           Temporary files
│   │   └── temp_email.html
│   │
│   ├── Config.xlsx                        Configuration
│   └── README.md                          Data documentation
│
├── 📂 Templates/                          [EMAIL TEMPLATES]
│   ├── 📂 Individual/
│   │   └── SummerTemplate.html
│   └── 📂 Group/
│       ├── AutumnTemplate.html
│       ├── SummerTemplate.html
│       └── WinterTemplate.html
│
├── 📂 Framework/                          [FRAMEWORK FILES]
│   └── (UiPath framework components)
│
├── 📂 Tests/                              [TEST FILES]
│   └── (Test workflows)
│
├── 📂 Documentation/                      [DOCS]
│   ├── BounceEmailAnalysis_README.md      NEW: Bounce analysis guide
│   └── (Other documentation)
│
├── Main.xaml                              Main entry point
├── project.json                           UiPath project config
├── README.md                              Project README
├── QUICKSTART_BounceAnalysis.md           NEW: Bounce analysis quick start
└── SUMMARY_BounceAnalysis_Solution.md     NEW: Solution overview
```

---

## 🔄 Luồng hoạt động

### 1. Main Flow
```
Main.xaml
    ↓
Dispatcher.xaml (1_Entry)
    ↓
┌─────────────────────────────────────────┐
│ User Interaction Loop                   │
│                                         │
│  JobSelection.xaml                      │
│  ├─ Load jobs from Google Drive        │
│  ├─ User selects: Jobs, Mode, Template │
│  └─ Generate dashboard_data.js         │
│      ↓                                  │
│  ReviewPhase.xaml                       │
│  ├─ Preview email with data            │
│  ├─ User confirms: Yes/No/Back         │
│  └─ Generate review_data.js            │
│      ↓                                  │
│  [User Decision]                        │
│  ├─ Back → Return to JobSelection      │
│  ├─ No → Exit                           │
│  └─ Yes → Continue to ProcessBatch     │
└─────────────────────────────────────────┘
    ↓
ProcessBatch.xaml (2_Processing)
    ↓
GeneratePDF.xaml (1 time only)
├─ Build email body from template
├─ Write temp_email.html
├─ Edge headless → PDF
└─ Return PDF path
    ↓
┌─────────────────────────────────────────┐
│ Email Sending Loop                      │
│                                         │
│  For each recipient:                    │
│    Process_SendEmail.xaml               │
│    ├─ Use shared PDF                    │
│    ├─ Build email body                  │
│    └─ Module_SendGmail.xaml             │
│        ├─ Attach PDF                    │
│        └─ Send via Gmail API            │
└─────────────────────────────────────────┘
    ↓
Save ExecutionReport_*.xlsx
```

### 2. Monitoring Flow (Separate)
```
Dashboard "📊 Xem Trạng Thái Email" button
    ↓
CheckEmailStatus.xaml (4_Monitoring)
    ↓
Process_DeliveryStatusNotifications.xaml
├─ Get DSN emails from Gmail
├─ Parse delivery status
├─ Generate email_status_data.js
└─ Open EmailStatusReport.html
    ↓
Browser displays interactive dashboard
```

### 3. Bounce Analysis Flow (NEW)
```
CheckEmailStatus_WithDashboard.xaml
    ↓
Load SentEmails.txt
    ↓
Process_BounceEmailAnalysis.xaml
├─ Get bounce emails from Gmail
├─ Parse with Regex (SMTP codes)
├─ Match with sent emails
├─ Classify errors (Permanent/Temporary)
└─ Build result DataTable
    ↓
Convert to JSON
    ↓
Update BounceEmailDashboard.html
    ↓
Start Python HTTP server (localhost:8080)
    ↓
Auto-open browser → Interactive dashboard
```

---

## 🎯 Tính năng chính

### ✅ Email Sending
- **Auto Mode**: Load từ Google Drive
- **Manual Mode**: Nhập email thủ công
- **Templates**: Individual/Group với BR Omega font
- **PDF**: Generate 1 lần, reuse cho tất cả emails
- **Batch Processing**: Gửi hàng loạt với error handling

### 📊 Monitoring & Reporting
- **HTML Dashboard**: Modern UI với filter/search
- **Delivery Status**: Success/Failed với lý do chi tiết
- **Real-time**: Tự động refresh khi có data mới
- **Export**: Excel reports cho archiving
- **Bounce Analysis** (NEW): 
  - SMTP error code parsing (550, 421, 552, etc.)
  - Regex-based email extraction
  - Permanent vs Temporary classification
  - Recommended actions
  - Interactive dashboard with charts
  - Localhost HTTP server (Python)

### 🎨 UI/UX
- **BR Omega Font**: Consistent branding
- **Responsive**: Works on all screen sizes
- **Interactive**: Filter, search, sort
- **Modern Design**: Gradients, shadows, smooth transitions

---

## 🔧 Configuration

### Config.xlsx Keys
```
GmailConnectionId          → Gmail API connection
JobEmail_SubjectTemplate   → Email subject
JobEmail_AttachmentPath    → PDF path
GoogleDrive_JobsFileId     → Jobs spreadsheet ID
GoogleDrive_EmailsFileId   → Emails spreadsheet ID
```

### Environment Requirements
- UiPath Studio 2023.x+
- UiPath.GSuite.Activities
- Microsoft Edge (for PDF generation)
- Gmail API credentials
- Google Drive access
- Python 3.x (for bounce analysis dashboard server)
- Newtonsoft.Json package

---

## 📝 Maintenance Guide

### Adding New Template
1. Create HTML in `Templates/Individual/` or `Templates/Group/`
2. Include BR Omega font-face declarations
3. Use placeholders: `{{Role}}`, `{{CareerLevel}}`, etc.
4. Test with GeneratePDF.xaml

### Updating Workflows
1. **Entry workflows** (1_Entry): User interaction changes
2. **Processing** (2_Processing): Business logic changes
3. **Review** (3_Review): Preview UI changes
4. **Monitoring** (4_Monitoring): Status tracking changes
5. **Modules** (5_Modules): Reusable component changes

### Troubleshooting
| Issue | Check |
|-------|-------|
| PDF not generated | Fonts in `Data/Fonts/`, Edge installed |
| Email not sent | Gmail connection, API permissions |
| Dashboard blank | JS files generated, font paths correct |
| Wrong data | Config.xlsx values, Google Drive IDs |

---

## 🚀 Quick Start

1. **Setup**
   - Configure `Data/Config.xlsx`
   - Verify Gmail connection
   - Check Google Drive access

2. **Run**
   - Execute `Main.xaml`
   - Select jobs and mode in Dashboard
   - Review and confirm
   - Monitor execution

3. **Check Status**
   - Click "📊 Xem Trạng Thái Email" in Dashboard
   - View delivery status report
   - Export to Excel if needed

4. **Bounce Analysis** (NEW)
   - Run `Demo_BounceAnalysis_Standalone.xaml` for quick demo
   - Or run `CheckEmailStatus_WithDashboard.xaml` for real analysis
   - View dashboard at http://localhost:8080
   - Review SMTP error codes and recommendations

---

## 📚 Documentation

- **Workflows**: `Workflows/CandidateEmail/README.md`
- **Data**: `Data/README.md`
- **Bounce Analysis**: `Documentation/BounceEmailAnalysis_README.md` (NEW)
- **Quick Start**: `QUICKSTART_BounceAnalysis.md` (NEW)
- **Solution Summary**: `SUMMARY_BounceAnalysis_Solution.md` (NEW)
- **This file**: Overall project structure

---

**Version**: 3.0 - Added Bounce Email Analysis with Dashboard  
**Last Updated**: 2026-04-17 03:27 AM  
**Team**: FPT Software Recruitment Automation
