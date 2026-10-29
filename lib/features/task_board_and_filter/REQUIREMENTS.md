# 🎯 Yêu cầu & Nhiệm vụ: Phân hệ Task Board, Search & Gestures
**👤 Người phụ trách:** Vũ Hoàng Phúc

Phân hệ này là "trái tim" tương tác của ứng dụng, nơi người dùng sẽ dành 80% thời gian sử dụng. Yêu cầu lớn nhất đối với bạn là tạo ra một danh sách công việc cực kỳ mượt mà, phản hồi ngay lập tức với các thao tác cử chỉ (Gestures) và khả năng tìm kiếm đa chiều tốc độ cao.

## 📝 1. Chi tiết Yêu cầu (Requirements)

### 1.1. Core Task Board (Danh sách Công việc)
* Xây dựng giao diện chính `task_board_screen.dart` hiển thị danh sách các Task.
* Tích hợp cơ chế Kéo-Thả (Drag & Drop) thông qua thuộc tính `orderIndex` trong `TaskItem` để người dùng tự do sắp xếp độ ưu tiên thủ công.
* Xây dựng `category_project_drawer.dart` (Menu trượt bên trái) để chuyển đổi nhanh giữa các Project.

### 1.2. Smart Gestures (Cử chỉ Thông minh)
* Sử dụng package `flutter_slidable` trong component `slidable_task_card.dart`.
* **Vuốt phải:** Đổi nhanh trạng thái (`Todo` -> `In Progress` -> `Done`).
* **Vuốt trái:** Mở các hành động nhanh (Đổi độ ưu tiên, Hẹn giờ lại, Giao việc).
* **Multi-select:** Nhấn giữ để chọn nhiều Task cùng lúc (quản lý state bằng `multi_select_provider.dart`), và cho phép thao tác hàng loạt (Batch Actions).

### 1.3. Search, Filter & Sort Engine (Bộ lọc & Tìm kiếm)
* Hoàn thiện `search_filter_bar.dart` với giao diện trực quan (các Filter Chip).
* Xây dựng logic trong `task_filter_sort_provider.dart` để lọc danh sách realtime:
  * Lọc theo Trạng thái (Status), Độ ưu tiên (Priority), Nhãn (Tags).
  * Lọc theo Thời gian (Hôm nay, Tuần này, Quá hạn).
  * Tìm kiếm full-text (debounce search) theo tiêu đề (Title) và mô tả (Description).

## ⚠️ 2. Các Lưu ý Kỹ thuật (Technical Notes)
* **Haptic Feedback:** Hãy dùng `HapticFeedback.lightImpact()` hoặc `mediumImpact()` mỗi khi người dùng vuốt thẻ hoặc kéo thả xong để tạo cảm giác "chạm" vật lý (rất quan trọng cho UX).
* **State Management:** Kết hợp nhiều bộ lọc (vừa search text, vừa filter status) là một bài toán khó. Hãy dùng tính năng kết hợp các Provider (`ref.watch`) trong Riverpod một cách khéo léo để code không bị rối.
* **Tối ưu Danh sách:** Sử dụng `ListView.builder` hoặc `SliverList` để đảm bảo khi có 1000 tasks, app vẫn scroll mượt ở 60-120fps.

## 🏆 3. Kết quả Mong đợi (Expected Outcomes)
1. Danh sách công việc có thể vuốt thẻ hai chiều mượt mà, đổi trạng thái task trong nháy mắt.
2. Tìm kiếm và Lọc ra kết quả ngay lập tức khi gõ phím mà không bị giật lag (sử dụng Debounce).
3. Cho phép người dùng chọn cùng lúc 5 tasks và đánh dấu hoàn thành toàn bộ chỉ bằng 1 thao tác.