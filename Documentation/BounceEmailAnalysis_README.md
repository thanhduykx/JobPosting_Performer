# 📧 Email Bounce Analysis System - Hướng dẫn sử dụng

## Tổng quan

Hệ thống phân tích bounce emails với dashboard real-time giúp theo dõi và xử lý các email bị trả lại (bounce) do lỗi SMTP.

## Components

### 1. **Process_BounceEmailAnalysis.xaml**
Workflow chính để phân tích bounce emails với các tính năng:
- Kết nối với Gmail qua GSuite API
- Lấy bounce emails từ inbox
- Parse SMTP error codes (550, 421, 552, 554, etc.)
- Trích xuất thông tin lỗi bằng Regex
- Phân loại lỗi: Permanent vs Temporary
- Đề xuất hành động xử lý

### 2. **CheckEmailStatus_WithDashboard.xaml**
Workflow tích hợp đầy đủ:
- Load danh sách emails đã gửi
- Gọi Process_BounceEmailAnalysis
- Tạo dashboard HTML với dữ liệu real-time
- Khởi động HTTP server tự động
- Mở browser hiển thị dashboard

### 3. **BounceEmailDashboard.html**
Dashboard HTML responsive với:
- Thống kê tổng quan (Success/Failed/Temporary errors)
- Bảng chi tiết kết quả gửi email
- Filter theo trạng thái
- Search functionality
- Chart phân loại lỗi
- Modern UI với animations

### 4. **start_dashboard_server.py**
Python HTTP server:
- Serve dashboard trên localhost:8080
- Auto-open browser
- Graceful shutdown

## Cấu trúc dữ liệu

### Input Arguments

#### Process_BounceEmailAnalysis.xaml
```
in_str_ConnectionId (String): Gmail connection ID
in_list_SentEmails (List<String>): Danh sách emails đã gửi
in_str_MailFolder (String): Mail folder name (default: "INBOX")
```

#### CheckEmailStatus_WithDashboard.xaml
```
in_Config (Dictionary<String, Object>): Configuration dictionary
in_str_ConnectionId (String): Gmail connection ID (optional)
in_str_SentEmailsFile (String): Path to sent emails file (optional)
```

### Output

#### DataTable: out_dt_ResultReport
| Column | Type | Description |
|--------|------|-------------|
| Email | String | Email address |
| Status | String | Success/Failed |
| ErrorCode | String | SMTP error code (550, 421, etc.) |
| Reason | String | Full error message |
| ErrorType | String | Error classification |
| Action | String | Recommended action |
| Timestamp | String | Processing timestamp |

## Bảng mã lỗi SMTP

| Mã | Ý nghĩa | Loại | Hành động |
|----|---------|------|-----------|
| 550 5.1.1 | Email không tồn tại | Permanent | Xóa khỏi danh sách |
| 550 5.2.1 | Hộp thư bị vô hiệu hóa | Permanent | Xóa khỏi danh sách |
| 550 5.4.1 | Domain không tồn tại | Permanent | Kiểm tra lại tên miền |
| 552 5.2.2 | Hộp thư đầy (quota) | Temporary | Thử lại sau 24 giờ |
| 421 4.7.0 | Server từ chối tạm thời | Temporary | Thử lại sau vài giờ |
| 450 4.2.1 | Hộp thư tạm thời không khả dụng | Temporary | Thử lại |
| 554 5.7.1 | Bị chặn bởi spam filter | Permanent | Kiểm tra nội dung mail |

## Regex Patterns

### 1. Trích xuất email bị lỗi
```vb
System.Text.RegularExpressions.Regex.Match(
    mail.Body,
    "tried to reach\s+([\w.\-+]+@[\w.\-]+\.[a-z]{2,})",
    System.Text.RegularExpressions.RegexOptions.IgnoreCase
).Groups(1).Value
```

### 2. Trích xuất mã lỗi SMTP
```vb
System.Text.RegularExpressions.Regex.Match(
    mail.Body,
    "\b([45]\d{2})\s+[\d.]+"
).Groups(1).Value
```

### 3. Trích xuất lý do đầy đủ
```vb
System.Text.RegularExpressions.Regex.Match(
    mail.Body,
    "([45]\d{2}\s+[\d.]+\s+.+?)(?:\r|\n|$)"
).Value.Trim()
```

### 4. Lấy email từ Subject (backup)
```vb
System.Text.RegularExpressions.Regex.Match(
    mail.Subject,
    "([\w.\-+]+@[\w.\-]+\.[a-z]{2,})"
).Value
```

## Cách sử dụng

### Bước 1: Chuẩn bị dữ liệu
Tạo file `Data\Output\SentEmails.txt` với danh sách emails đã gửi (mỗi email một dòng):
```
candidate1@example.com
candidate2@example.com
test@company.com
```

### Bước 2: Cấu hình Gmail Connection
1. Vào UiPath Studio
2. Mở Gmail connection settings
3. Copy Connection ID
4. Paste vào workflow hoặc Config dictionary

### Bước 3: Chạy Workflow
1. Mở `CheckEmailStatus_WithDashboard.xaml`
2. Điền các arguments cần thiết
3. Run workflow

### Bước 4: Xem Dashboard
- Browser sẽ tự động mở tại `http://localhost:8080/BounceEmailDashboard.html`
- Dashboard tự động refresh khi có dữ liệu mới

## Dashboard Features

### Thống kê Overview
- **Success Count**: Số email gửi thành công
- **Failed Count**: Số email thất bại
- **Temporary Errors**: Số lỗi tạm thời (có thể retry)
- **Total Count**: Tổng số emails

### Bảng chi tiết
- **Filter buttons**: Lọc theo All/Success/Failed/Permanent/Temporary
- **Search box**: Tìm kiếm theo email, error code, reason
- **Sortable columns**: Click header để sort
- **Hover effects**: Xem full reason text

### Error Chart
- Phân loại lỗi theo loại
- Color-coded legend
- Visual representation

## Tùy chỉnh

### Thay đổi Port
Sửa file `start_dashboard_server.py`:
```python
PORT = 8080  # Đổi sang port khác nếu cần
```

### Thay đổi Mail Folder
```vb
<InArgument x:TypeArguments="x:String" x:Key="in_str_MailFolder">[Spam]</InArgument>
```

### Thay đổi số lượng email lấy
Sửa trong `Process_BounceEmailAnalysis.xaml`:
```xml
MaxNumberOfResults="100"  <!-- Đổi số lượng -->
```

## Troubleshooting

### Lỗi: "Port already in use"
**Nguyên nhân**: Port 8080 đã được sử dụng  
**Giải pháp**: 
1. Stop server đang chạy
2. Hoặc đổi PORT trong Python script

### Lỗi: "Python not found"
**Nguyên nhân**: Python chưa được cài đặt hoặc không trong PATH  
**Giải pháp**: 
1. Install Python 3.x
2. Add Python to PATH
3. Restart UiPath Studio

### Lỗi: "Connection ID invalid"
**Nguyên nhân**: Gmail connection chưa được setup  
**Giải pháp**: 
1. Tạo Gmail connection mới trong UiPath
2. Copy đúng Connection ID
3. Test connection trước khi chạy

### Dashboard không hiển thị dữ liệu
**Nguyên nhân**: Placeholder không được replace  
**Giải pháp**: 
1. Check file HTML có chứa `__DATA_PLACEHOLDER__`
2. Verify Newtonsoft.Json package đã được install
3. Check log messages trong UiPath

## Best Practices

### 1. Email List Management
- Định kỳ update sent emails list
- Remove permanent bounce emails
- Track retry attempts for temporary errors

### 2. Performance
- Limit bounce email retrieval (100-200 max)
- Run analysis off-peak hours
- Archive old bounce reports

### 3. Error Handling
- Always log detailed error messages
- Implement retry logic for temporary errors
- Maintain bounce history for analytics

### 4. Security
- Don't hardcode credentials
- Use secure connections (OAuth)
- Protect sensitive email data

## Integration với workflow hiện tại

### Tích hợp sau khi gửi email
```vb
' Trong Process_SendEmail.xaml hoặc ProcessBatch.xaml
' Sau khi gửi email thành công, lưu email vào list

If out_Status = "Success" Then
    File.AppendAllText(
        Path.Combine(Environment.CurrentDirectory, "Data\Output\SentEmails.txt"),
        in_Email + vbCrLf
    )
End If
```

### Scheduled Analysis
Tạo schedule để chạy analysis định kỳ (VD: mỗi 6 giờ):
1. Add workflow vào Orchestrator
2. Create schedule trigger
3. Set thời gian chạy

## Requirements

### UiPath Packages
- `UiPath.GSuite.Activities` (latest)
- `UiPath.Mail.Activities` (latest)
- `Newtonsoft.Json` (13.0+)

### System Requirements
- Python 3.x
- Internet connection
- Gmail API access
- Modern web browser

## Changelog

### Version 1.0 (2026-04-17)
- Initial release
- Bounce email analysis
- Dashboard với real-time data
- HTTP server integration
- Comprehensive error code mapping

## Support

Liên hệ: UiPath Developer Team  
Documentation: [Project Documentation Folder]

---

**Lưu ý quan trọng**: 
- Đảm bảo Gmail connection đã được test
- Python phải có trong system PATH
- Port 8080 phải available
- Sent emails file phải tồn tại trước khi chạy
