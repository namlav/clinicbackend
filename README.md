# Serene Health - Admin Dashboard
# [![Nam Lav](https://img.shields.io/badge/Author-Nam_Lav-0D9488?style=for-the-badge&logo=github&logoColor=white)](https://github.com/namlav)

Trang quản trị (Admin Dashboard) dành cho hệ thống phòng khám **Serene Health**, được xây dựng trên nền tảng **Flutter Web** và sử dụng **Supabase** làm backend (Database & Authentication).

## 🌟 Tính Năng Nổi Bật

- **Bảo Mật & Phân Quyền**: Hệ thống đăng nhập an toàn, chỉ cho phép tài khoản có vai trò `admin` truy cập vào giao diện quản trị.
- **Bảng Điều Khiển (Dashboard)**: 
  - Xem nhanh thống kê tổng quan trong ngày (số ca khám, doanh thu, số bác sĩ hoạt động).
  - Biểu đồ trực quan thống kê doanh thu và số lượng ca khám theo ngày, tháng hoặc một khoảng thời gian tùy chọn.
- **Quản Lý Bác Sĩ**: 
  - Hiển thị danh sách bác sĩ cùng với thông tin chi tiết (chuyên khoa, số năm kinh nghiệm, liên hệ).
  - Khóa/Mở khóa tài khoản bác sĩ nhanh chóng.
- **Quản Lý Dịch Vụ Khám**: 
  - Xem, thêm mới và chỉnh sửa các dịch vụ khám bệnh.
  - Tùy chỉnh giá tiền, mô tả và trạng thái hoạt động của dịch vụ.
- **Quản Lý Người Dùng**: 
  - Quản lý danh sách bệnh nhân và bác sĩ.
  - Xem chi tiết thông tin bệnh nhân, bao gồm tổng số ca khám đã hoàn thành.
  - Khóa/Mở khóa tài khoản người dùng để hạn chế quyền truy cập hệ thống khi cần.
- **Cập Nhật Dữ Liệu Thời Gian Thực (Realtime)**: Các thay đổi từ cơ sở dữ liệu sẽ được phản ánh lập tức lên giao diện thông qua tính năng Realtime của Supabase.

## 🛠 Công Nghệ Sử Dụng

- **Frontend**: [Flutter](https://flutter.dev/) (phiên bản Web)
- **Backend / Database**: [Supabase](https://supabase.com/) (PostgreSQL, Authentication, Realtime)
- **Thư viện chính**:
  - `supabase_flutter`: Kết nối và thao tác với Supabase.
  - `fl_chart`: Vẽ biểu đồ thống kê.
  - `flutter_dotenv`: Quản lý biến môi trường an toàn.

## ⚙️ Cài Đặt & Chạy Dự Án

### Yêu Cầu Hệ Thống
- Đã cài đặt [Flutter SDK](https://docs.flutter.dev/get-started/install).
- Có project Supabase với các bảng đã được thiết lập.

### Bước 1: Clone & Cài Đặt Package
```bash
git clone <repo_url>
cd clinicbackend
flutter pub get
```

### Bước 2: Thiết Lập Biến Môi Trường
Tạo file `.env` ở thư mục gốc của dự án và thêm thông tin kết nối Supabase của bạn:
```env
SUPABASE_URL=https://<your_project_ref>.supabase.co
SUPABASE_ANON_KEY=<your_anon_key>
```

### Bước 3: Cấu Hình Supabase (Quan trọng)
Đảm bảo bạn đã thiết lập đúng schema và đặc biệt là các hàm kiểm tra quyền (RLS) để cho phép Admin thao tác.
Bạn cần chạy đoạn SQL sau trong Supabase SQL Editor để thiết lập quyền truy cập cho Admin trên bảng `users` mà không bị lỗi *Infinite Recursion*:

```sql
-- Tạo hàm kiểm tra admin an toàn bỏ qua RLS
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE authid = auth.uid() AND role = 'admin'
  );
$$;

-- Thiết lập RLS trên bảng users
CREATE POLICY "Users: admin read all, user read self"
  ON public.users FOR SELECT
  USING ( public.is_admin() OR authid = auth.uid() );

CREATE POLICY "Users: admin can update"
  ON public.users FOR UPDATE
  USING ( public.is_admin() )
  WITH CHECK ( public.is_admin() );
```
*(Tương tự cho các bảng `doctors`, `services`, `appointments`, `payments` tuỳ theo RLS policy của bạn).*

### Bước 4: Chạy Ứng Dụng
```bash
flutter run -d chrome
```

## 📁 Cấu Trúc Thư Mục

```
lib/
├── models/         # Các Data Models tương ứng với DB
├── services/       # File supabase_service.dart xử lý logic API & Auth
├── views/          # Các màn hình chính (Dashboard, Quản lý...)
├── widgets/        # Các UI component dùng chung (Sidebar, Card...)
└── main.dart       # Điểm bắt đầu, thiết lập theme & Supabase
```

## Happy Coding! 🚀