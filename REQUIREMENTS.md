# Yêu Cầu Phát Triển: Serene Health - Admin Dashboard (Flutter Web)
# Toàn bộ giao diện trang web phải là tiếng Việt

## 1. Mục Tiêu Dự Án
Xây dựng trang Web Admin Dashboard bằng Flutter cho nền tảng quản lý phòng khám Serene Health. 
Ứng dụng sử dụng `supabase_flutter` để giao tiếp trực tiếp với cơ sở dữ liệu PostgreSQL.

## 2. Kiến Trúc Cơ Sở Dữ Liệu (Supabase Schema)
Dưới đây là cấu trúc chính xác của các bảng trong database. Mọi Model (Dart class) và câu lệnh gọi API `.from('table_name')` phải tuân thủ nghiêm ngặt định dạng chữ thường này (không dùng camelCase hay snake_case cho tên cột khi gọi API).

- **Bảng `users`**: `userid` (int), `authid` (uuid), `fullname` (text), `phone` (text), `email` (text), `role` (varchar, nhận giá trị: 'patient', 'doctor', 'admin'), `is_active` (bool).
- **Bảng `doctors`**: `doctorid` (int), `userid` (int - FK to users), `fullname` (text), `specialtyid` (int), `avatarurl` (text), `bio` (text), `experienceyears` (int).
- **Bảng `services`**: `serviceid` (int), `servicename` (text), `description` (text), `price` (numeric), `specialtyid` (int), `is_active` (bool).
- **Bảng `appointments`**: `appointmentid` (int), `userid` (int), `doctorid` (int), `serviceid` (int), `appointmentdate` (date), `starttime` (time), `status` (varchar: 'Pending', 'Confirmed', 'Cancelled', 'Completed').
- **Bảng `payments`**: `paymentid` (int), `appointmentid` (int), `amount` (numeric), `status` (varchar: 'Pending', 'Success', 'Failed').

## 3. Kiến Trúc Thư Mục (Folder Structure)
Yêu cầu tạo các thư mục sau trong `lib/`:
- `models/`: Chứa các Dart class map với cấu trúc Database ở trên (cần có hàm `fromJson` và `toJson`).
- `services/`: Chứa `supabase_service.dart` xử lý logic gọi API, Auth.
- `views/`: Chứa các màn hình UI.
- `widgets/`: Chứa các UI component dùng chung (Sidebar, Navbar, Card thống kê...).

## 4. Các Tính Năng Cốt Lõi Cần Implement (Thực hiện tuần tự)

### Phase 1: Authentication & Layout
- Tích hợp `supabase_flutter` trong `main.dart`.
- **Màn hình Đăng nhập (`login_screen.dart`)**: Đăng nhập bằng Email/Password. Sau khi login, BẮT BUỘC query bảng `users` để check `role`. NẾU `role == 'admin'` => Cho phép vào. NẾU KHÔNG => Báo lỗi "Bạn không có quyền quản trị" và đăng xuất (`.signOut()`).
- **Web Layout**: Xây dựng một layout cố định có `Sidebar` bên trái (chứa các menu: Dashboard, Quản lý Bác sĩ, Quản lý Dịch vụ) và khu vực `Main Content` bên phải để hiển thị nội dung thay đổi. Giao diện web phải đẹp, hiện đại, sang trọng phù hợp với phong cách của một phòng khám, có tính Responsive để tương thích với màn hình Desktop/Laptop.

### Phase 2: Màn Hình Dashboard (`dashboard_screen.dart`)
- **Top Cards**: Hiển thị 3 chỉ số tổng quan:
  1. Tổng số ca khám trong ngày (count từ bảng `appointments` với `appointmentdate` = hôm nay).
  2. Tổng doanh thu (sum cột `amount` từ bảng `payments` có status = 'Success').
  3. Tổng số bác sĩ đang hoạt động.
- **Biểu đồ**: Sử dụng thư viện `fl_chart` để vẽ biểu đồ đường (Line Chart) mô tả doanh thu hoặc số ca khám 7 ngày gần nhất.

### Phase 3: Quản Lý Bác Sĩ (`doctor_management_screen.dart`)
- Hiển thị danh sách bác sĩ dưới dạng `DataTable` (kéo data từ bảng `doctors` join với `users` để lấy trạng thái).
- Có nút Khóa/Mở Khóa tài khoản: Gọi lệnh `.update({'is_active': false/true})` vào bảng `users` với `userid` tương ứng.

### Phase 4: Quản Lý Dịch Vụ (`service_management_screen.dart`)
- Hiển thị danh sách từ bảng `services` dưới dạng `DataTable`.
- Nút "Thêm Dịch Vụ": Mở một Dialog chứa form nhập `servicename`, `price`, `specialtyid`.
- Nút "Chỉnh Sửa": Update giá tiền hoặc đổi trạng thái `is_active`.

## 5. Quy Tắc Code (Coding Standards)
- Luôn bọc các câu lệnh gọi API Supabase trong khối `try-catch` và hiển thị `SnackBar` nếu có lỗi.
- Code UI cần sử dụng các thành phần Material 3 hiện đại, có tính Responsive để tương thích với màn hình Desktop/Laptop.