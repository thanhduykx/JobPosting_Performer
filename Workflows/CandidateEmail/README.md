# 📧 Candidate Email Workflow - Cấu trúc dự án

## 📁 Tổ chức thư mục

### 1️⃣ **1_Entry** - Điểm vào chính
Workflows khởi động và điều phối toàn bộ quy trình.

- **`Dispatcher.xaml`** - Main dispatcher, điều phối toàn bộ flow
- **`JobSelection.xaml`** - Dashboard chọn job, mode (Auto/Manual), template

---

### 2️⃣ **2_Processing** - Xử lý logic chính
Workflows xử lý nghiệp vụ gửi email và tạo PDF.

- **`ProcessBatch.xaml`** - Xử lý batch gửi email (loop qua danh sách recipients)
- **`Process_SendEmail.xaml`** - Gửi 1 email đến 1 recipient cụ thể
- **`GeneratePDF.xaml`** - Tạo PDF từ template HTML (chỉ chạy 1 lần/batch)

**Luồng hoạt động:**
```
ProcessBatch → GeneratePDF (1 lần) → Loop: Process_SendEmail (N lần)
```

---

### 3️⃣ **3_Review** - Xác nhận trước khi gửi
Workflows cho phép user review và confirm trước khi thực thi.

- **`ReviewPhase.xaml`** - Hiển thị preview email, cho phép user xác nhận hoặc quay lại chỉnh sửa

---

### 4️⃣ **4_Monitoring** - Theo dõi & báo cáo
Workflows kiểm tra trạng thái gửi email và tạo báo cáo.

- **`CheckEmailStatus.xaml`** - Entry point để kiểm tra email status
- **`Process_DeliveryStatusNotifications.xaml`** - Xử lý Delivery Status Notifications từ Gmail, tạo HTML dashboard

**Tính năng:**
- Lấy DSN emails từ Gmail INBOX
- Phân tích thành công/thất bại + lý do
- Tạo HTML dashboard tương tác với filter, search
- Tự động mở browser hiển thị kết quả

---

### 5️⃣ **5_Modules** - Module dùng chung
Các module có thể tái sử dụng.

- **`Module_SendGmail.xaml`** - Module gửi email qua Gmail API (có attachment)

---

## 🔄 Luồng hoạt động tổng thể

```
Main.xaml
    ↓
Dispatcher.xaml (1_Entry)
    ↓
┌─────────────────────────────────────┐
│ Loop: User Selection & Review       │
│                                     │
│  JobSelection.xaml (1_Entry)        │
│       ↓                             │
│  ReviewPhase.xaml (3_Review)        │
│       ↓                             │
│  [User confirms: Yes/No]            │
└─────────────────────────────────────┘
    ↓ (if confirmed)
ProcessBatch.xaml (2_Processing)
    ↓
GeneratePDF.xaml (2_Processing) ← Tạo PDF 1 lần
    ↓
┌─────────────────────────────────────┐
│ Loop: Gửi từng email                │
│                                     │
│  Process_SendEmail.xaml             │
│       ↓                             │
│  Module_SendGmail.xaml (5_Modules)  │
└─────────────────────────────────────┘
    ↓
[Hoàn thành]

[Riêng biệt - Theo dõi]
CheckEmailStatus.xaml (4_Monitoring)
    ↓
Process_DeliveryStatusNotifications.xaml
    ↓
[Mở HTML Dashboard trong browser]
```

---

## 🎯 Tính năng chính

### ✅ Gửi Email
- **Auto mode**: Lấy danh sách từ Google Drive
- **Manual mode**: Nhập email thủ công
- **Template**: Individual/Group templates
- **PDF attachment**: Tạo 1 lần, dùng chung cho tất cả emails
- **Font BR Omega**: Đảm bảo trong PDF

### 📊 Monitoring
- Dashboard HTML hiển thị delivery status
- Filter: All / Delivered / Failed
- Search by email address
- Chi tiết lý do lỗi

### 🎨 UI/UX
- Modern dashboard với gradient, shadows
- Responsive design
- Real-time filtering
- BR Omega font throughout

---

## 📝 Lưu ý khi bảo trì

1. **Thay đổi workflow paths**: Nếu di chuyển files, cập nhật `WorkflowFileName` trong các `InvokeWorkflowFile`
2. **Template HTML**: Đặt trong `Templates/Individual` hoặc `Templates/Group`
3. **Font files**: Phải có trong `Data/Fonts/`
4. **Config**: Chỉnh trong `Data/Config.xlsx`
5. **Gmail Connection**: Cập nhật `GmailConnectionId` trong Config

---

## 🔧 Dependencies

- UiPath.GSuite.Activities (Gmail API)
- UiPath.Excel.Activities
- Microsoft Edge (để generate PDF)
- BR Omega font files

---

**Tạo bởi:** FPT Software Recruitment Team  
**Phiên bản:** 2.0 - Optimized PDF Generation  
**Ngày cập nhật:** 2026-04-17
