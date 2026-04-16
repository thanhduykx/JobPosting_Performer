# 📧 Bounce Email Analysis - Integration Guide

## Tổng quan

Tính năng bounce email analysis đã được **tích hợp vào hệ thống hiện có** sử dụng pattern giống như Dashboard.html và Review.html.

## Workflow đã cập nhật

### 1. CheckEmailStatus.xaml (Main workflow)
**Location**: `Workflows\CandidateEmail\4_Monitoring\CheckEmailStatus.xaml`

**Flow mới**:
```
1. Get delivery status notifications (existing)
   ↓
2. Load sent emails from Data\Output\SentEmails.txt
   ↓
3. Invoke Process_BounceEmailAnalysis.xaml
   ↓
4. Generate email_status_data.js
   ↓
5. Open EmailStatusReport.html in browser
```

**Variables added**:
- `list_SentEmails` (List<String>)
- `dt_BounceReport` (DataTable)
- `str_HtmlPath` (String)
- `str_SentEmailsFile` (String)

### 2. Process_BounceEmailAnalysis.xaml (Core logic)
**Location**: `Workflows\CandidateEmail\4_Monitoring\Process_BounceEmailAnalysis.xaml`

**Functionality**:
- ✅ Connect to Gmail via GSuite
- ✅ Get bounce emails (filter: mailer-daemon, postmaster, delivery failed)
- ✅ Parse SMTP error codes with Regex
- ✅ Match bounces with sent emails
- ✅ Classify errors (Permanent/Temporary)
- ✅ Generate recommendations
- ✅ Create email_status_data.js file
- ✅ Return HTML path

**Arguments**:
```
IN:
  - in_str_ConnectionId (String)
  - in_list_SentEmails (List<String>)
  - in_str_MailFolder (String) - default "INBOX"

OUT:
  - out_dt_ResultReport (DataTable)
  - out_str_HtmlPath (String)
```

**DataTable columns**:
1. Email (String)
2. Status (String) - "Success" or "Failed"
3. ErrorCode (String) - SMTP code (550, 421, etc.)
4. Reason (String) - Full error message
5. ErrorType (String) - Classification
6. Action (String) - Recommended action
7. Timestamp (String)

## Dashboard được nâng cấp

### EmailStatusReport.html
**Location**: `Data\UI\EmailStatusReport.html`

**Changes made**:
- ✅ Added 3 new table columns: Error Code, Error Type, Recommended Action
- ✅ Added Temporary Errors stat card
- ✅ Color-coded error code badges
- ✅ Permanent/Temporary classification styling
- ✅ Action badges for recommendations

**CSS classes added**:
```css
.error-code          - Blue badge for SMTP codes
.error-type          - Error classification text
.error-type.permanent - Red color for permanent errors
.error-type.temporary - Orange color for temporary errors
.action-badge        - Yellow badge for recommendations
```

### email_status_data.js
**Location**: `Data\UI\email_status_data.js`

**Format**:
```javascript
var emailStatusData = [
  {
    "email": "user@example.com",
    "status": "Failed",
    "errorCode": "550",
    "errorType": "Permanent - Mailbox Not Found",
    "reason": "550 5.1.1 User unknown",
    "action": "Remove from list",
    "time": "2026-04-17 03:27:00"
  }
];
```

## SMTP Error Code Mapping

### Regex Patterns

**1. Extract failed email**:
```regex
tried to reach\s+([\w.\-+]+@[\w.\-]+\.[a-z]{2,})
```

**2. Extract SMTP code**:
```regex
\b([45]\d{2})\s+[\d.]+
```

**3. Extract error reason**:
```regex
([45]\d{2}\s+[\d.]+\s+.+?)(?:\r|\n|$)
```

**4. Backup from subject**:
```regex
([\w.\-+]+@[\w.\-]+\.[a-z]{2,})
```

### Error Classification Logic

```vb
Select Case errorCode
    Case "550"
        If Contains("user") Or Contains("mailbox") Then
            errorType = "Permanent - Mailbox Not Found"
            action = "Remove from list"
        ElseIf Contains("domain") Then
            errorType = "Permanent - Domain Invalid"
            action = "Check domain name"
        ElseIf Contains("spam") Or Contains("blocked") Then
            errorType = "Permanent - Spam Filter"
            action = "Review email content"
        End If
        
    Case "552"
        errorType = "Temporary - Mailbox Full"
        action = "Retry after 24 hours"
        
    Case "421"
        errorType = "Temporary - Server Busy"
        action = "Retry after few hours"
        
    Case "450"
        errorType = "Temporary - Mailbox Unavailable"
        action = "Retry later"
        
    Case "554"
        errorType = "Permanent - Policy Rejection"
        action = "Check content & sender reputation"
End Select
```

## Cách sử dụng

### 1. Chuẩn bị file SentEmails.txt

**Location**: `Data\Output\SentEmails.txt`

**Format** (1 email per line):
```
john@example.com
jane@company.com
test@domain.com
```

**Tích hợp tự động** (trong Process_SendEmail.xaml):
```vb
If out_Status = "Success" Then
    File.AppendAllText(
        Path.Combine(Environment.CurrentDirectory, "Data\Output\SentEmails.txt"),
        in_Email + vbCrLf
    )
End If
```

### 2. Run CheckEmailStatus.xaml

Workflow sẽ:
1. Check delivery status (existing functionality)
2. Load sent emails list
3. Get bounce emails from Gmail
4. Parse và match
5. Generate JS file
6. Open dashboard in browser

### 3. View dashboard

Dashboard hiển thị:
- **Total emails**: Tổng số emails
- **Delivered**: Số emails thành công
- **Failed**: Số emails thất bại
- **Temporary Errors**: Số lỗi tạm thời (có thể retry)

**Table columns**:
- Recipient Email
- Status badge
- Error Code badge (nếu có)
- Error Type (Permanent/Temporary)
- Reason/Details
- Recommended Action badge
- Timestamp

## Pattern tích hợp

Giống như Dashboard.html và Review.html:

```
Workflow
   ↓
Generate .js data file
   ↓
HTML loads .js file
   ↓
JavaScript renders UI
   ↓
Open HTML in browser
```

**Benefits**:
- ✅ No external dependencies (Python, server)
- ✅ Consistent với architecture hiện có
- ✅ Simple deployment
- ✅ Works offline
- ✅ Fast loading

## Files được thay đổi/tạo mới

### Modified:
1. `Data\UI\EmailStatusReport.html` - Thêm columns và styling
2. `Workflows\CandidateEmail\4_Monitoring\CheckEmailStatus.xaml` - Thêm bounce analysis

### Created:
1. `Workflows\CandidateEmail\4_Monitoring\Process_BounceEmailAnalysis.xaml` - Core logic

### Removed:
1. `Data\Output\BounceEmailDashboard.html` - Không cần
2. `Data\Output\start_dashboard_server.py` - Không cần
3. `Workflows\...\CheckEmailStatus_WithDashboard.xaml` - Không cần
4. `Workflows\...\Demo_BounceAnalysis_Standalone.xaml` - Không cần

## Best Practices

### 1. Email List Management
```vb
' Clear old entries periodically
File.WriteAllText(sentEmailsPath, String.Empty)

' Or keep only recent emails (last 7 days)
Dim recentEmails = allEmails.Where(Function(e) 
    e.Timestamp > Now.AddDays(-7)
).ToList()
```

### 2. Error Handling
```vb
' In Process_BounceEmailAnalysis
Try
    ' Parse logic
Catch ex As Exception
    errorType = "Parse Error"
    recommendedAction = "Manual review required"
End Try
```

### 3. Performance
- Limit bounce email retrieval: `MaxNumberOfResults="100"`
- Run during off-peak hours
- Archive old bounce reports

## Maintenance

### Adding new SMTP error codes

Edit `Process_BounceEmailAnalysis.xaml`:
```vb
Case "510"  ' Your custom code
    errorType = "Your Error Type"
    recommendedAction = "Your Action"
```

### Updating dashboard styling

Edit `Data\UI\EmailStatusReport.html`:
```css
.error-code {
    background: #YOUR_COLOR;
}
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No data in dashboard | Check email_status_data.js was generated |
| Parse errors | Verify bounce email format matches regex |
| Missing emails | Check SentEmails.txt exists and has data |
| Connection errors | Verify Gmail connection ID in Config.xlsx |

---

**Version**: 1.0  
**Last Updated**: 2026-04-17  
**Integration**: Seamless với existing dashboard pattern
