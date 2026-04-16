# 🚀 Quick Start - Email Bounce Analysis

## Cách sử dụng

### Bước 1: Chuẩn bị file emails đã gửi
Tạo file `Data\Output\SentEmails.txt` với danh sách emails (mỗi email một dòng):
```
john@example.com
jane@company.com
test@domain.com
```

### Bước 2: Chạy workflow
```
File: Workflows\CandidateEmail\4_Monitoring\CheckEmailStatus.xaml
```

### Bước 3: Xem kết quả
- Dashboard sẽ tự động mở trong browser
- Hiển thị SMTP error codes, error types, recommended actions
- Filter/search functionality

---

## Tính năng chính

### Dashboard được nâng cấp
- ✅ **EmailStatusReport.html** trong `Data/UI/`
- ✅ Tích hợp với pattern hiện có (dashboard.html, review.html)
- ✅ Không cần Python server - chạy trực tiếp trong browser
- ✅ Data từ `email_status_data.js`

### Workflow tích hợp
- ✅ **CheckEmailStatus.xaml** - workflow chính
- ✅ **Process_BounceEmailAnalysis.xaml** - core logic
- ✅ Tự động generate JS file và open HTML

---

## Cấu trúc Files

```
📁 JobPosting_FINAL/
├── 📁 Workflows/CandidateEmail/4_Monitoring/
│   ├── CheckEmailStatus.xaml                     ← Main workflow (updated)
│   └── Process_BounceEmailAnalysis.xaml          ← Core analysis logic
│
├── 📁 Data/UI/
│   ├── EmailStatusReport.html                    ← Dashboard (updated)
│   └── email_status_data.js                      ← Generated data
│
└── 📁 Data/Output/
    └── SentEmails.txt                            ← Email list
```

---

## SMTP Error Codes được phân tích

| Code | Meaning | Type | Action |
|------|---------|------|--------|
| 550 | Email/Domain không tồn tại | Permanent | Remove from list |
| 552 | Mailbox đầy | Temporary | Retry after 24h |
| 421 | Server busy | Temporary | Retry after few hours |
| 554 | Spam filter | Permanent | Review email content |
| 450 | Mailbox unavailable | Temporary | Retry later |

---

## Dashboard Features

- ✅ **Statistics Cards**: Total, Success, Failed, Temporary errors
- ✅ **SMTP Error Code Display**: Color-coded badges
- ✅ **Error Type Classification**: Permanent vs Temporary
- ✅ **Recommended Actions**: Auto-suggested next steps
- ✅ **Search & Filter**: Interactive table
- ✅ **Modern UI**: BR Omega font, responsive design

---

## Troubleshooting

### ❌ "Sent emails file not found"
**Fix**: Tạo file `Data\Output\SentEmails.txt` với danh sách emails

### ❌ "No bounce emails found"
**Fix**: Kiểm tra INBOX có bounce emails không (from: mailer-daemon, postmaster)

### ❌ "Connection failed"
**Fix**: Verify Gmail connection ID trong Config.xlsx

---

## Advanced Usage

### Tích hợp vào workflow hiện tại

**Sau khi gửi email thành công:**
```vb
' Add to Process_SendEmail.xaml
If out_Status = "Success" Then
    File.AppendAllText(
        Path.Combine(Environment.CurrentDirectory, "Data\Output\SentEmails.txt"),
        in_Email + vbCrLf
    )
End If
```

**Schedule định kỳ:**
1. Upload workflow to Orchestrator
2. Create scheduled trigger (VD: every 6 hours)
3. Auto-analyze và update dashboard

### Custom Error Handling
```vb
' Trong Process_BounceEmailAnalysis.xaml
' Thêm custom error codes vào Select Case:

Case "510"
    errorType = "Custom - Specific Error"
    recommendedAction = "Your custom action"
```

---

## Integration Points

### 📬 Get Email Connection
```
Activity: GSuite Application Card
Connection Type: Gmail
Scope: Read emails
```

### 📊 Output Format
```
DataTable với columns:
- Email (String)
- Status (String): "Success" | "Failed"
- ErrorCode (String): "550", "421", etc.
- Reason (String): Full SMTP message
- ErrorType (String): Classification
- Action (String): Recommended next step
- Timestamp (String): ISO format
```

---

## Tips & Best Practices

### ✅ DO:
- Run analysis sau khi batch email send
- Định kỳ clean up permanent bounces
- Monitor dashboard cho patterns
- Export data để long-term analytics

### ❌ DON'T:
- Retry permanent errors (550)
- Spam retry trên temporary errors
- Ignore spam filter warnings (554)
- Hardcode credentials

---

## Support & Resources

📖 **Full Documentation**: `Documentation\BounceEmailAnalysis_README.md`  
🔧 **Sample Data**: Chạy `Demo_BounceAnalysis_Standalone.xaml`  
💡 **SMTP Codes Reference**: [RFC 5321](https://tools.ietf.org/html/rfc5321)

---

## Next Steps

1. ✅ Chạy demo để làm quen
2. ✅ Setup Gmail connection
3. ✅ Test với real bounce emails
4. ✅ Tích hợp vào workflow chính
5. ✅ Schedule automated analysis

---

**Version**: 1.0  
**Last Updated**: 2026-04-17  
**Author**: UiPath Developer Team

🎉 **Happy Email Monitoring!**
