# 🎯 Yêu cầu & Nhiệm vụ: Phân hệ Task Detail & Collaboration
**👤 Người phụ trách:** Nguyễn Hải Đăng

Phân hệ này đảm nhận chiều sâu của ứng dụng. Bạn có nhiệm vụ giúp người dùng phân rã công việc lớn thành các công việc nhỏ (Checklist), lên lịch nhắc nhở, và đặc biệt là biến một app To-do thông thường thành một công cụ làm việc nhóm thông qua hệ thống Bình luận (Comments).

## 📝 1. Chi tiết Yêu cầu (Requirements)

### 1.1. Task CRUD & Bottom Sheet (Tạo/Sửa Công việc)
* Xây dựng form nhập liệu nhanh tại `task_form_bottom_sheet.dart` (mở lên từ dưới đáy màn hình) để tạo Task siêu tốc (Title, Priority, Deadline).
* Xây dựng màn hình chi tiết `task_detail_screen.dart` để xem và chỉnh sửa mọi thông tin của Task (Mô tả, Nhãn, Giao việc, ...).
* Quản lý trạng thái gọi API tạo/sửa/xóa thông qua `task_crud_provider.dart`.

### 1.2. Subtasks (Checklist)
* Code giao diện `checklist_section_widget.dart` bên trong màn hình chi tiết.
* Cho phép người dùng thêm các mục con, đánh dấu tick hoàn thành.
* (Tùy chọn nâng cao): Cho phép kéo thả (Drag & Drop) để sắp xếp vị trí các mục checklist (sử dụng `orderIndex` của `SubTask`).
* Tự động tính toán lại `%` hoàn thành của toàn bộ Task dựa trên số checklist đã tick.

### 1.3. Collaboration (Làm việc nhóm)
* Xây dựng component `comment_timeline_widget.dart`.
* Giao diện cần hiển thị giống một đoạn chat (Timeline), cho phép các thành viên (Project Members) thảo luận trong từng công việc.
* Đọc dữ liệu từ `TaskComment` và định dạng thời gian đẹp mắt (VD: "2 giờ trước", "Vừa xong").

### 1.4. Reminders (Hẹn giờ Nhắc nhở)
* Tích hợp package `flutter_local_notifications` trong `reminder_notification_service.dart`.
* Cấu hình đẩy thông báo Local Push Notification (Rung máy, kêu chuông) khi một task tới giờ `reminderAt` hoặc sắp quá hạn.

## ⚠️ 2. Các Lưu ý Kỹ thuật (Technical Notes)
* **Form Validation:** Đảm bảo Title không được bỏ trống. Deadline không được chọn ngày trong quá khứ.
* **Quyền truy cập (Permissions):** Notification trên Android 13+ và iOS yêu cầu phải xin quyền người dùng trước khi đặt lịch nhắc nhở. Hãy code luồng xin quyền chuẩn chỉ.
* **Thời gian (DateTime):** Luôn xử lý ngày giờ kết hợp với múi giờ (Timezone) chuẩn bằng package `intl` để tránh sai lệch khi hẹn giờ.

## 💡 3. Hướng dẫn Code Độc lập (Không bị block)
Nếu Long chưa làm xong Đăng nhập và Phúc chưa làm xong List, bạn KHÔNG CẦN phải ngồi chờ:
1. Mở `lib/core/router/app_router.dart` và thiết lập `initialLocation: '/task-detail'`. App sẽ vào thẳng màn hình chi tiết của bạn mà không cần bấm vào danh sách.
2. Để có dữ liệu giả vẽ giao diện, hãy lấy task đầu tiên bằng cách gọi `final fakeTask = MockRepository.mockTasks.first;` và truyền nó vào màn hình. (Task này đã chứa sẵn các Subtask và Comment mẫu).
3. Bạn có thể tự do code UI, bắt sự kiện click dựa trên `fakeTask` này. Code xong cứ Push lên nhánh cá nhân thoải mái!

## 🏆 4. Kết quả Mong đợi (Expected Outcomes)
1. Tạo một Task mới và thêm Checklist chỉ trong vòng chưa tới 10 giây nhờ Bottom Sheet trực quan.
2. Thông báo nhắc nhở đẩy xuống điện thoại chính xác tới từng phút.
3. Chức năng bình luận hoạt động mượt mà, phân biệt rõ ràng comment của "Mình" (bên phải) và "Người khác" (bên trái).