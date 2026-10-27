# 🚀 Smart Workflow & Adaptive Todo App (Flutter)

Ứng dụng quản lý công việc cá nhân và cộng tác nhóm theo quy trình (Workflow-based Todo App) được phát triển trên nền tảng **Flutter & Dart**. Dự án nổi bật với khả năng **tự động thích ứng giao diện (Adaptive UI)** dựa trên số lượng công việc tồn đọng do người dùng tự cấu hình, kết hợp hệ thống cử chỉ thao tác nhanh (Gestures) và nút hành động theo ngữ cảnh (Contextual Actions).

---

## 👥 1. Thành viên Nhóm Phát triển

| Họ và tên | Vai trò & Phân hệ phụ trách | Nhánh làm việc chính (Git Branch) |
| :--- | :--- | :--- |
| **Hà Vũ Long** | Identity (OAuth, Profile), Adaptive UI Engine & Dashboard Analytics | `feat/long-auth-adaptive-ui`, `feat/long-dashboard` |
| **Vũ Hoàng Phúc** | Core Task Board, Search/Filter/Sort Engine, Gestures & Contextual UI | `feat/phuc-task-list-gesture`, `feat/phuc-search-filter` |
| **Nguyễn Hải Đăng** | Task CRUD, Sub-tasks/Checklist, Collaboration (Assign/Comment) & Reminders | `feat/dang-task-detail-subtask`, `feat/dang-comment-reminder` |

---

## 🌟 2. Tổng quan Tính năng Hệ thống

### 2.1. Quản lý Tài khoản & Cá nhân hóa
* **Xác thực người dùng:** Đăng ký, đăng nhập, đăng xuất và tích hợp đăng nhập nhanh qua **OAuth** (Google / GitHub / Apple).
* **Quản lý hồ sơ (Profile):** Cập nhật ảnh đại diện, tên hiển thị, thông tin liên hệ.
* **Cấu hình cá nhân hóa:** Tùy chỉnh ngưỡng số lượng công việc tồn đọng (Backlog Threshold) để kích hoạt chế độ biến đổi giao diện thông minh.

### 2.2. Quản lý Công việc & Quy trình (Core Workflow)
* **Thao tác CRUD:** Tạo mới, chỉnh sửa, xóa và xem chi tiết toàn bộ thông tin công việc.
* **Trạng thái quy trình (Status):**
  * `Todo`: Công việc mới khởi tạo, chờ thực hiện.
  * `In Progress`: Công việc đang trong quá trình xử lý.
  * `Done`: Công việc đã hoàn thành.
  * `Cancelled`: Công việc đã hủy bỏ.
* **Mức độ ưu tiên (Priority):** Phân loại trực quan theo 4 cấp độ `Low`, `Medium`, `High`, `Urgent`.
* **Phân loại & Tổ chức:** Gắn công việc vào `Category` (Danh mục), `Project` (Dự án) và nhiều `Tag` (Nhãn).
* **Sub-task & Checklist:** Chia nhỏ một công việc lớn thành danh sách các bước nhỏ (Checklist), hỗ trợ đánh dấu hoàn thành từng phần và tự động tính phần trăm tiến độ (`%`) trên thẻ công việc chính.

### 2.3. Quản lý Thời gian & Nhắc việc
* **Mốc thời gian:** Thiết lập Ngày bắt đầu (`startDate`) và Hạn chót (`deadline`).
* **Hệ thống cảnh báo & Nhắc việc:**
  * Hẹn giờ gửi thông báo nhắc việc (Local Push Notifications).
  * Tự động phát hiện và gắn nhãn cảnh báo **Sắp hết hạn (Due Soon)** và **Quá hạn (Overdue)**.

### 2.4. Tìm kiếm, Bộ lọc & Sắp xếp Đa chiều
* **Tìm kiếm tức thời (Real-time Search):** Tìm theo tên công việc hoặc nội dung mô tả.
* **Bộ lọc kết hợp (Multi-criteria Filter):** Lọc đồng thời theo `Status`, `Priority`, `Deadline` (Hôm nay, Tuần này, Quá hạn) và `Tag`.
* **Sắp xếp linh hoạt (Sort):** Sắp xếp danh sách theo hạn chót (`Deadline`), ngày tạo (`Created Date`), hoặc mức độ ưu tiên (`Priority`).

### 2.5. Cộng tác Nhóm & Thống kê
* **Giao việc (Task Assignment):** Phân công công việc cho các thành viên khác trong dự án.
* **Bình luận (Comments):** Trao đổi, thảo luận trực tiếp theo dòng thời gian (Timeline) bên trong từng công việc.
* **Báo cáo & Thống kê (Analytics Dashboard):** Tổng hợp trực quan số lượng công việc đã hoàn thành (`Done`), đang làm (`In Progress`), và quá hạn (`Overdue`) kèm tỷ lệ hoàn thành.

---

## 🎨 3. Điểm nhấn Thiết kế UI/UX Đặc thù

### 3.1. Giao diện Thích ứng theo Số Task Đang Đọng (Adaptive Backlog UI)
Ứng dụng sử dụng `AnimatedTheme` để thay đổi màu sắc chủ đạo và bố cục hiển thị dựa trên số lượng công việc chưa hoàn thành (`Todo` + `In Progress` + `Overdue`) so với ngưỡng cá nhân (N) do người dùng cài đặt:

| Trạng thái | Điều kiện kích hoạt | Màu sắc Chủ đạo (Theme) | Thay đổi trên Giao diện (UX Behavior) |
| :--- | :--- | :--- | :--- |
| **Calm Mode (Thư giãn)** | Số task đọng < `0.6 * N` | Xanh Mint / Indigo dịu (`#10B981` / `#4F46E5`), nền sáng thoáng (`#F8FAFC`) | Hiển thị đầy đủ mô tả phụ, biểu đồ thống kê mở rộng, thông điệp khích lệ nhẹ nhàng. |
| **Focus Mode (Tập trung)** | `0.6 * N` ≤ Số task đọng < `N` | Vàng Hổ phách (`#F59E0B`), nền ấm (`#FFFBEB`) | Xuất hiện Banner nhắc các task sắp đến hạn hôm nay; ưu tiên đẩy các task `High`/`Urgent` lên đầu. |
| **Overload Mode (Khẩn cấp)** | Số task đọng ≥ `N` hoặc có nhiều task quá hạn | Cam Đỏ dịu (`#EF4444`), nền cảnh báo nhẹ (`#FEF2F2`) | Tự động thu gọn (collapse) các task `Low Priority`; ghim danh sách **Quá hạn / Sắp hết hạn** lên đầu kèm nút **"Dời lịch nhanh (Batch Reschedule)"**. |

### 3.2. Cử chỉ Thao tác nhanh (Smart Gestures)
* **Vuốt sang phải (Swipe Right):** Chuyển nhanh công việc sang bước tiếp theo trong quy trình (`Todo` → `In Progress` → `Done`) kèm phản hồi xúc giác (`HapticFeedback.lightImpact()`).
* **Vuốt sang trái (Swipe Left):** Mở nhanh 3 nút: *Hẹn lại giờ nhắc (Snooze)*, *Đổi mức ưu tiên (Priority)*, và *Giao việc (Assign)*.
* **Nhấn giữ (Long Press):** Kích hoạt chế độ chọn nhiều công việc (Multi-select) hoặc kéo thả sắp xếp thứ tự.

### 3.3. Nút Hành động theo Ngữ cảnh (Contextual Action Button)
* **Tại màn hình Danh sách:** Hiển thị nút `+ Tạo Task nhanh` mở Bottom Sheet có sẵn các chip chọn nhanh *Deadline, Priority, Tag, Assignee*.
* **Khi đang chọn nhiều Task:** Nút tự động biến đổi thành thanh công cụ nổi ở đáy màn hình: *Đổi Status hàng loạt | Gán Tag | Xóa*.
* **Khi xem Chi tiết Task:** Nút chính thay đổi theo trạng thái hiện tại của công việc (VD: Đang ở `Todo` hiển thị **"Bắt đầu làm"**, đang ở `In Progress` hiển thị **"Hoàn thành"**, khi quá hạn hiển thị **"Gia hạn Deadline"**).

---

## 🛠️ 4. Công nghệ, Thư viện & Bộ Asset Chuẩn

### 4.1. Danh sách Packages trong `pubspec.yaml`

| Nhóm chức năng | Tên Package | Mục đích sử dụng |
| :--- | :--- | :--- |
| **State Management** | `flutter_riverpod` | Quản lý trạng thái toàn cục, bộ lọc và Adaptive Theme theo thời gian thực. |
| **Routing** | `go_router` | Điều hướng màn hình theo URL/ID (`context.push('/task/:id')`), tách biệt các phân hệ. |
| **Typography & Icons** | `google_fonts`, `lucide_icons_flutter`, `icons_plus` | Font chữ *Plus Jakarta Sans / Inter* sắc nét, bộ icon nét mảnh hiện đại và logo OAuth. |
| **Gestures & Animations** | `flutter_slidable`, `flutter_animate`, `animations` | Hiệu ứng vuốt thẻ 2 chiều, chuyển cảnh mượt 60-120fps và micro-interactions. |
| **Charts & Visuals** | `fl_chart`, `percent_indicator`, `lottie`, `flutter_svg` | Vẽ biểu đồ thống kê Dashboard, thanh tiến độ Checklist và hiển thị ảnh động/SVG. |
| **Time & Notifications** | `intl`, `flutter_local_notifications` | Định dạng ngày giờ chuẩn tiếng Việt và hẹn giờ thông báo nhắc deadline. |

### 4.2. Bảng màu Ngữ nghĩa (Semantic Color Tokens)
* **Background & Surface:** Nền chính `#F8FAFC`, Thẻ nổi `#FFFFFF`, Viền phân cách `#E2E8F0`.
* **Priority Colors:**
  * `Low`: ⚪ `#64748B` (Slate Grey)
  * `Medium`: 🔵 `#3B82F6` (Royal Blue)
  * `High`: 🟠 `#F59E0B` (Amber Orange)
  * `Urgent`: 🔴 `#EF4444` (Crimson Red)
* **Status Colors:**
  * `Todo`: `#475569` (Nền `#F1F5F9`)
  * `In Progress`: `#2563EB` (Nền `#EFF6FF`)
  * `Done`: `#10B981` (Nền `#ECFDF5`)
  * `Cancelled`: `#94A3B8` (Chữ gạch ngang, nền `#F8FAFC`)

---

## 📁 5. Kiến trúc Thư mục Chống Xung đột (Feature-First Architecture)

Dự án được tổ chức theo mô hình **Feature-First** để 3 thành viên làm việc độc lập trên từng thư mục riêng biệt mà không gây xung đột (conflict) khi gộp code:

```text
lib/
├── main.dart                              # Điểm khởi chạy ứng dụng (Khóa sau khi cấu hình)
├── core/                                  # THƯ MỤC DÙNG CHUNG (Thống nhất từ Ngày 1)
│   ├── theme/
│   │   ├── app_colors.dart                # Bảng màu ngữ nghĩa & Adaptive Palettes
│   │   └── adaptive_theme_provider.dart   # Logic tự động đổi ThemeData theo backlog
│   ├── models/
│   │   ├── user_model.dart                # Model người dùng & cấu hình threshold
│   │   ├── task_model.dart                # Model công việc chính (Data Contract)
│   │   ├── subtask_model.dart             # Model checklist con
│   │   └── comment_model.dart             # Model bình luận trong task
│   ├── data/
│   │   └── mock_repository.dart           # Dữ liệu mẫu dùng chung để test độc lập
│   ├── widgets/
│   │   ├── priority_badge.dart            # Chip hiển thị mức độ ưu tiên
│   │   ├── status_chip.dart               # Chip hiển thị trạng thái quy trình
│   │   └── contextual_fab.dart            # Nút hành động biến thiên theo ngữ cảnh
│   └── router/
│       └── app_router.dart                # Khai báo đường dẫn điều hướng chung
│
└── features/                              # KHÔNG GIAN LÀM VIỆC RIÊNG CỦA 3 THÀNH VIÊN
    ├── auth_and_dashboard/                # [PHÂN HỆ 1 - HÀ VŨ LONG]
    │   ├── presentation/
    │   │   ├── login_register_screen.dart
    │   │   ├── profile_settings_screen.dart
    │   │   └── analytics_dashboard_screen.dart
    │   └── providers/
    │       ├── auth_provider.dart
    │       └── statistics_provider.dart
    │
    ├── task_board_and_filter/             # [PHÂN HỆ 2 - VŨ HOÀNG PHÚC]
    │   ├── presentation/
    │   │   ├── task_board_screen.dart
    │   │   ├── search_filter_bar.dart
    │   │   ├── category_project_drawer.dart
    │   │   └── slidable_task_card.dart
    │   └── providers/
    │       ├── task_filter_sort_provider.dart
    │       └── multi_select_provider.dart
    │
    └── task_detail_and_collab/            # [PHÂN HỆ 3 - NGUYỄN HẢI ĐĂNG]
        ├── presentation/
        │   ├── task_detail_screen.dart
        │   ├── task_form_bottom_sheet.dart
        │   ├── checklist_section_widget.dart
        │   └── comment_timeline_widget.dart
        └── providers/
            ├── task_crud_provider.dart
            └── reminder_notification_service.dart
```

---

## 📜 6. Hợp đồng Dữ liệu Cốt lõi (Core Data Contract)

Cả 3 thành viên sử dụng chung cấu trúc dữ liệu chuẩn dưới đây trong `lib/core/models/task_model.dart` để đảm bảo ráp nối các màn hình khớp 100%:

```dart
enum TaskStatus { todo, inProgress, done, cancelled }
enum TaskPriority { low, medium, high, urgent }

class SubTask {
  final String id;
  final String title;
  final bool isCompleted;

  const SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });
}

class TaskComment {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  const TaskComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });
}

class TaskItem {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? deadline;
  final DateTime? reminderAt;
  final String? categoryId;
  final String? projectId;
  final List<String> tags;
  final String? assigneeId;
  final List<SubTask> subtasks;
  final List<TaskComment> comments;

  const TaskItem({
    required this.id,
    required this.title,
    this.description = '',
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    required this.createdAt,
    this.startDate,
    this.deadline,
    this.reminderAt,
    this.categoryId,
    this.projectId,
    this.tags = const [],
    this.assigneeId,
    this.subtasks = const [],
    this.comments = const [],
  });

  bool get isOverdue =>
      deadline != null &&
      status != TaskStatus.done &&
      status != TaskStatus.cancelled &&
      deadline!.isBefore(DateTime.now());

  bool get isDueSoon =>
      deadline != null &&
      !isOverdue &&
      status != TaskStatus.done &&
      deadline!.difference(DateTime.now()).inHours <= 24;

  double get checklistProgress => subtasks.isEmpty
      ? 0.0
      : subtasks.where((s) => s.isCompleted).length / subtasks.length;
}
```

---

## 🤝 7. Quy trình Phối hợp Git & Phòng tránh Conflict

1. **Nguyên tắc Phân nhánh (Branching Strategy):**
   * `main`: Nhánh chứa bản build hoàn chỉnh, ổn định để demo và nộp bài.
   * `dev`: Nhánh tích hợp chung của cả nhóm.
   * Nhánh tính năng (`feat/<tên>-<tính-năng>`): Mỗi thành viên tạo nhánh riêng từ `dev` khi bắt đầu làm một tính năng mới.
2. **Nguyên tắc Cô lập Thư mục:**
   * Mỗi thành viên chỉ tạo và chỉnh sửa file bên trong thư mục `lib/features/<phân_hệ_của_mình>/`.
   * Không tự ý sửa các file trong `lib/core/` hoặc `pubspec.yaml` mà không thông báo trên nhóm chat chung.
3. **Giao tiếp Liên màn hình qua ID và Provider:**
   * Các màn hình không import trực tiếp Widget của nhau mà điều hướng thông qua `GoRouter` (ví dụ: `context.push('/task/${task.id}')`) và đọc dữ liệu từ `Provider` chung.
4. **Quy trình Merge hàng ngày:**

```bash
# Bước 1: Lưu code trên nhánh cá nhân
git add .
git commit -m "feat(phuc): implement slidable task card and multi-filter"

# Bước 2: Kéo code mới nhất từ nhánh dev về và rebase
git pull origin dev --rebase

# Bước 3: Đẩy nhánh cá nhân lên GitHub/GitLab và tạo Pull Request vào nhánh dev
git push origin feat/phuc-task-list-gesture
```

---

## 💻 8. Hướng dẫn Cài đặt & Khởi chạy Dự án

```bash
# 1. Clone repository về máy
git clone <url-repository-cua-nhom>
cd flutter_adaptive_todo_app

# 2. Chuyển sang nhánh tích hợp chung
git checkout dev

# 3. Cài đặt toàn bộ thư viện
flutter pub get

# 4. Chạy ứng dụng trên thiết bị ảo hoặc máy thật
flutter run
```