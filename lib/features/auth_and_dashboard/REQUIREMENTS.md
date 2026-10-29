# 🎯 Yêu cầu & Nhiệm vụ: Phân hệ Auth & Dashboard
**👤 Người phụ trách:** Hà Vũ Long

Phân hệ này đóng vai trò là "cửa ngõ" và "bộ não" điều khiển giao diện của toàn bộ ứng dụng. Nhiệm vụ của bạn là xử lý luồng xác thực người dùng, xây dựng bảng thống kê trực quan và đặc biệt là phát triển Engine tự động thích ứng giao diện (Adaptive UI).

## 📝 1. Chi tiết Yêu cầu (Requirements)

### 1.1. Xác thực & Hồ sơ (Authentication & Profile)
* Hoàn thiện màn hình `login_register_screen.dart`.
* Cấu hình logic Firebase OAuth 2.0 (Google/GitHub) bên trong `auth_provider.dart`.
* Lưu thông tin người dùng (tên, email, avatar) vào `UserModel` ngay sau khi đăng nhập thành công.
* Làm màn hình `profile_settings_screen.dart` cho phép người dùng tùy chỉnh `backlogThreshold` (Ngưỡng công việc tồn đọng để kích hoạt đổi màu UI).

### 1.2. Adaptive UI Engine (Giao diện Thích ứng)
* Viết logic tính toán trong `adaptive_theme_provider.dart`.
* Lắng nghe tổng số Task đang ở trạng thái `Todo`, `InProgress` và `Overdue`.
* So sánh với `backlogThreshold` của người dùng để trả về `ThemeData` tương ứng:
  * **Calm Mode:** Màu dịu mát (Mint/Indigo) khi task ít.
  * **Focus Mode:** Màu ấm (Amber) khi task gần chạm ngưỡng. Cảnh báo các task sắp hết hạn.
  * **Overload Mode:** Màu đỏ khẩn cấp (Red) khi task vượt ngưỡng. Tự động thu gọn các task mức ưu tiên thấp.

### 1.3. Bảng Thống kê (Analytics Dashboard)
* Sử dụng package `fl_chart` để vẽ biểu đồ trực quan trong `analytics_dashboard_screen.dart`.
* Thống kê phần trăm tiến độ công việc (Done vs In Progress vs Todo).
* Viết logic xử lý tính toán số liệu trong `statistics_provider.dart`.

## ⚠️ 2. Các Lưu ý Kỹ thuật (Technical Notes)
* **Performance:** Hạn chế re-build toàn bộ ứng dụng khi biểu đồ thống kê thay đổi. Chỉ dùng `ref.watch()` ở những Widget thực sự cần thiết.
* **Luồng Auth:** Đảm bảo khi người dùng mở app, nếu đã đăng nhập rồi thì `GoRouter` phải đá thẳng vào trang chủ, không được hiện màn hình Login nhấp nháy.
* **Adaptive Theme:** Chuyển đổi giữa các Theme nên sử dụng `AnimatedTheme` để có hiệu ứng chuyển màu mượt mà (fade), tránh đổi màu đột ngột gây chói mắt.

## 🏆 3. Kết quả Mong đợi (Expected Outcomes)
1. Đăng nhập/Đăng xuất mượt mà bằng Google mà không gặp lỗi crash.
2. Giao diện đổi màu sắc ngay lập tức (realtime) khi số lượng công việc thêm vào/hoàn thành vượt qua các ngưỡng quy định.
3. Biểu đồ thống kê hiển thị chính xác số liệu, hiệu ứng đẹp và tương tác tốt.