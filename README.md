# HỆ THỐNG THI TRỰC TUYẾN TOEIC READING (GIỮA KỲ)

Hệ thống thi TOEIC Reading gồm 2 phân hệ độc lập:
1. **Backend (Web Admin - Quản trị viên)**: Xây dựng bằng **ASP.NET Core (.NET 9 / EF Core)** kết nối **Microsoft SQL Server**, phục vụ cho Giảng viên tải lên file Word (.docx), kiểm tra cú pháp thẻ XML, xem trước cấu trúc phân cấp (Part 5, 6, 7) và chỉnh sửa trực tiếp nội dung đề thi.
2. **Frontend (Mobile/Web App - Thí sinh)**: Xây dựng bằng **Flutter + Dart** theo thiết kế Figma, hoạt động độc lập (Standalone / Offline-ready), phục vụ học viên làm bài thi 100 câu đọc với đồng hồ đếm ngược 75 phút, xem bài đọc, chọn câu hỏi nhanh và tự động tính điểm theo thang chuẩn ETS TOEIC Reading (5 – 495 điểm).

---

## 🎬 VIDEO DEMO HOẠT ĐỘNG HỆ THỐNG

<!-- markdownlint-disable-next-line MD034 -->
https://github.com/user-attachments/assets/2ce9a2d7-4884-4f08-b1a7-a4f48af21f1a

> 💡 *Trường hợp mạng chậm hoặc trình duyệt không nạp trước, bạn cũng có thể mở trực tiếp file lưu trữ trong repo:* 🎥 **[videos/Demo.mp4](./videos/Demo.mp4)**

---

## ⚙️ 1. HƯỚNG DẪN CẤU HÌNH CHUỖI KẾT NỐI (CONNECTION STRINGS)

Phần này hướng dẫn chi tiết vị trí các file cấu hình để người khác khi clone/chuyển máy có thể dễ dàng thay đổi thông tin kết nối CSDL và địa chỉ máy chủ.

### 1.1. Cấu hình Chuỗi kết nối CSDL SQL Server (Phía Web Backend - DUY NHẤT 1 FILE)

Web Backend chỉ đọc chuỗi kết nối từ **duy nhất 1 file**:

👉 [`Backend/aspnet-core/src/ToeicExam.Web.Mvc/appsettings.json`](file:///home/dazvo/Projects/www/KiemTraGiuaKy/Backend/aspnet-core/src/ToeicExam.Web.Mvc/appsettings.json)

```json
{
  "ConnectionStrings": {
    "Default": "Server=localhost,1433; Database=ToeicExamDb; User Id=sa; Password=Password123; TrustServerCertificate=True; MultipleActiveResultSets=True;"
  }
}
```

> **Ý nghĩa các tham số cần sửa khi đổi máy**:
> - `Server`: Địa chỉ máy chủ SQL Server (VD: `localhost,1433` hoặc `127.0.0.1,1433` hoặc tên instance `.\\SQLEXPRESS`).
> - `Database`: Tên cơ sở dữ liệu (`ToeicExamDb`).
> - `User Id`: Tên tài khoản đăng nhập SQL Server (VD: `sa`).
> - `Password`: Mật khẩu tài khoản SQL Server.
> - `TrustServerCertificate=True`: Cho phép kết nối an toàn không cần chứng chỉ SSL riêng.
>
> *(Lưu ý: Các thư mục `ToeicExam.Migrator` và `ToeicExam.Web.Host` là project mẫu sinh sẵn của template ASP.NET Boilerplate, hệ thống chạy thực tế bằng `ToeicExam.Web.Mvc` nên bạn chỉ cần sửa duy nhất 1 file `appsettings.json` tại `ToeicExam.Web.Mvc`)*

---

### 1.2. Cấu hình Chuỗi kết nối API Máy chủ (Phía App Flutter - DUY NHẤT 1 FILE)

App kết nối và đồng bộ đề thi trực tiếp với CSDL SQL Server của Web qua **duy nhất 1 file**:

👉 [`Frontend/lib/services/api_service.dart`](file:///home/dazvo/Projects/www/KiemTraGiuaKy/Frontend/lib/services/api_service.dart)

Dòng số 12:
```dart
static String baseUrl = 'http://localhost:5000/api/exams';
```

> **Cách sửa khi đổi môi trường chạy App**:
> - **Chạy trên cùng máy tính (Trình duyệt Chrome / Linux Desktop)**: Giữ nguyên `http://localhost:5000/api/exams`
> - **Chạy trên máy ảo Android (Android Emulator)**: Sửa thành `http://10.0.2.2:5000/api/exams` *(10.0.2.2 là địa chỉ loopback của Android Studio tới máy chủ của bạn)*
> - **Chạy trên điện thoại di động thật**: Sửa thành `http://<IP_LAN_MAY_TINH>:5000/api/exams` *(ví dụ `http://192.168.1.15:5000/api/exams`)*
>
> *(Lưu ý: Ứng dụng đã có sẵn cơ chế dự phòng Offline: nếu Web Backend chưa bật, App vẫn tự động nạp đề từ `local_exam_data.dart` để tránh lỗi màn hình)*

---

## 🗄️ 2. MÔ HÌNH CƠ SỞ DỮ LIỆU (CSDL QUẢN LÝ ĐỀ THI)

CSDL SQL Server `ToeicExamDb` gồm **5 bảng chuẩn hóa** quản lý cấu trúc đề thi phân cấp:

1. **`Exams`**: Lưu thông tin bài thi (Tiêu đề, thời gian 75 phút, tổng số câu 100, ngày tạo).
2. **`Parts`**: Lưu các phần thi (Part 5, Part 6, Part 7) thuộc về bài thi.
3. **`QuestionGroups`**: Lưu nhóm câu hỏi (Đoạn văn đọc hiểu, hình ảnh, mã nhóm).
4. **`Questions`**: Lưu câu hỏi cụ thể (Số thứ tự câu 101–200, nội dung câu hỏi, đáp án đúng A/B/C/D).
5. **`QuestionOptions`**: Lưu 4 lựa chọn (Label A/B/C/D và nội dung đáp án).

---

## 🚀 3. HƯỚNG DẪN KHỞI CHẠY HỆ THỐNG

### 3.1. Khởi chạy Backend (Web Quản trị Admin)

Thư mục: `Backend/aspnet-core`

```bash
cd Backend/aspnet-core

# 1. Build dự án Backend
DOTNET_ROLL_FORWARD=Major dotnet build

# 2. Khởi chạy Web Admin trên cổng 5000
DOTNET_ROLL_FORWARD=Major dotnet run --project src/ToeicExam.Web.Mvc
```

Sau khi chạy thành công:
* Mở trình duyệt truy cập: **`http://localhost:5000`** (hoặc `http://localhost:5000/Exam`)
* **Chức năng Admin**:
  * **Danh sách đề thi (`/Exam`)**: Xem danh sách đề thi hiện có, xóa đề thi.
  * **Import đề thi từ file Word (`/Exam/Upload`)**: Tải file `Reading_v07.docx`. Hệ thống tự động kiểm tra tag `<QUESTION>`, `<OPTION>`, `<ANSWER>` và báo lỗi nếu file sai cấu trúc.
  * **Xem trước & Chỉnh sửa (`/Exam/Preview?id={id}`)**: Xem trước đề phân cấp và popup sửa trực tiếp nội dung từng câu hỏi.

---

### 3.2. Khởi chạy Frontend (App Flutter)

Thư mục: `Frontend`

```bash
cd Frontend

# 1. Cài đặt các gói thư viện
flutter pub get

# 2. Chạy ứng dụng trên trình duyệt Chrome
flutter run -d chrome

# Hoặc chạy trên Linux Desktop
flutter run -d linux
```

Sau khi chạy thành công:
* **Chức năng Học viên**:
  * **Trang chủ (`HomeScreen`)**: Hiển thị thẻ đề thi TOEIC Reading, tổng quan số câu và thời gian.
  * **Màn hình làm bài (`ExamScreen`)**: Đồng hồ đếm ngược 75 phút, chuyển đổi nhanh giữa Part 5, 6, 7, hiển thị đoạn văn đọc hiểu, bảng câu hỏi nhanh (Question Palette), đánh dấu câu cần xem lại (Flag for review) và cho phép chọn/hủy chọn đáp án linh hoạt.
  * **Chấm điểm tự động (`ResultScreen`)**: Khi nộp bài (Submit), hệ thống tự động tính điểm theo thang chuẩn ETS (5 – 495), thống kê số câu đúng, câu sai, câu bỏ qua và tỉ lệ chính xác từng phần.

---

## 📋 4. BẢNG TỔNG HỢP LỆNH NHANH (CHEATSHEET)

| Thao tác | Thư mục | Lệnh thực thi |
| :--- | :--- | :--- |
| **Build Web Backend** | `Backend/aspnet-core` | `DOTNET_ROLL_FORWARD=Major dotnet build` |
| **Chạy Web Backend** | `Backend/aspnet-core` | `DOTNET_ROLL_FORWARD=Major dotnet run --project src/ToeicExam.Web.Mvc` |
| **Kiểm tra cú pháp Flutter** | `Frontend` | `flutter analyze` |
| **Chạy App Flutter (Chrome)** | `Frontend` | `flutter run -d chrome` |
| **Chạy App Flutter (Linux)** | `Frontend` | `flutter run -d linux` |

---

## 📁 5. CẤU TRÚC THƯ MỤC CHÍNH

```text
KiemTraGiuaKy/
├── Demo.mp4                                 # Video quay màn hình demo toàn bộ chức năng
├── Reading_v07.docx                         # Đề thi TOEIC Reading chuẩn hóa gắn thẻ XML
├── Đề thi giữa kỳ.pdf                       # Đề bài yêu cầu của Giảng viên
├── BaoCao-VoVanDat-2380600478.docx          # Báo cáo nộp bài theo mẫu
├── README.md                                # Hướng dẫn tổng thể & cấu hình chuỗi kết nối
├── Backend/
│   └── aspnet-core/
│       └── src/
│           ├── ToeicExam.Core/              # Các Entity CSDL (5 bảng đề thi)
│           ├── ToeicExam.Application/       # Parser bóc tách XML Word, Service quản lý đề
│           ├── ToeicExam.EntityFrameworkCore# Cấu hình EF Core DbContext SQL Server
│           └── ToeicExam.Web.Mvc/           # Web Admin Razor Pages & appsettings.json
└── Frontend/
    ├── lib/
    │   ├── data/                            # Dataset đề thi nội bộ (local_exam_data.dart, exam_test_7.json)
    │   ├── models/                          # Data models bài thi và kết quả chấm điểm
    │   ├── services/                        # Service chấm điểm & lưu lịch sử thiết bị
    │   ├── screens/                         # Màn hình giao diện: Home, Exam, Result, Question Palette
    │   └── main.dart                        # Entry point của App Flutter
    └── pubspec.yaml                         # Cấu hình thư viện Flutter
```
