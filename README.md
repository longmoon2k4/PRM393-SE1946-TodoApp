# 🚀 Smart Workflow & Adaptive Todo App

Ứng dụng quản lý công việc và cộng tác nhóm linh hoạt được phát triển bằng **Flutter**. Dự án tập trung vào trải nghiệm người dùng (UX) hiện đại với giao diện tự động thích ứng (Adaptive UI), cử chỉ thông minh (Smart Gestures) và luồng làm việc nhóm theo thời gian thực.

---

## 👥 1. Đội ngũ Phát triển & Phân công

Dự án được chia thành 3 phân hệ độc lập, ứng với 3 thành viên:

| Thành viên | Vai trò & Phân hệ | Nhánh (Branch) |
| :--- | :--- | :--- |
| **Hà Vũ Long** | Authentication (OAuth), Adaptive UI Engine, Analytics Dashboard | `feat/long-auth-adaptive-ui`<br>`feat/long-dashboard` |
| **Vũ Hoàng Phúc** | Task Board, Search/Filter Engine, Smart Gestures | `feat/phuc-task-list-gesture`<br>`feat/phuc-search-filter` |
| **Nguyễn Hải Đăng** | Task CRUD, Subtasks, Collaboration, Notifications | `feat/dang-task-detail-subtask`<br>`feat/dang-comment-reminder` |

---

## ✨ 2. Tính năng Nổi bật

* **Giao diện Thích ứng (Adaptive UI):** Giao diện tự động thay đổi màu sắc và bố cục dựa trên "độ tải" công việc (Số lượng task đang đọng). Tự động chuyển đổi giữa các chế độ: *Calm (Thư giãn)*, *Focus (Tập trung)*, và *Overload (Quá tải)*.
* **Cử chỉ Thông minh (Smart Gestures):** Vuốt để đổi trạng thái, vuốt để mở menu thao tác nhanh, nhấn giữ để kéo thả thay đổi vị trí công việc.
* **Làm việc Nhóm (Collaboration):** Phân quyền dự án, giao việc cho thành viên, bình luận (comments) theo thời gian thực và nhật ký hoạt động (activity logs).
* **Xác thực Nhanh (OAuth):** Hỗ trợ đăng nhập không mật khẩu bằng Google/GitHub qua Firebase Auth.

---

## 🛠️ 3. Công nghệ Sử dụng

* **Nền tảng:** Flutter (Dart)
* **State Management:** `flutter_riverpod`
* **Routing:** `go_router`
* **UI/UX:** `google_fonts`, `icons_plus`, `flutter_slidable`, `fl_chart`, `lottie`
* **Kiến trúc:** Feature-First (tách biệt module theo tính năng để chống xung đột code)
* **Cơ sở dữ liệu:** [Xem Thiết kế Database (MySQL)](./docs/DATABASE_DESIGN.md)

---

## 📁 4. Cấu trúc Dự án (Feature-First)

Kiến trúc đảm bảo 3 thành viên có thể làm việc song song mà không sợ `merge conflict`:

```text
lib/
├── core/                                  # Dùng chung (Model, Theme, Router, Component)
└── features/                              # Phân hệ độc lập
    ├── auth_and_dashboard/                # Code của Hà Vũ Long
    ├── task_board_and_filter/             # Code của Vũ Hoàng Phúc
    └── task_detail_and_collab/            # Code của Nguyễn Hải Đăng
```
*(Lưu ý: Mọi giao tiếp giữa các feature phải thông qua `core/models` và `GoRouter`)*

---

## 🤝 5. Quy trình Làm việc (Git Workflow)

Dự án áp dụng quy trình Git nghiêm ngặt để đảm bảo chất lượng mã nguồn:

1. **Nhánh `main`:** Chứa bản Release ổn định. **(⚠️ Bị khóa bảo vệ. Không được push trực tiếp).**
2. **Nhánh `dev`:** Nhánh hội tụ code của cả nhóm.
3. **Luồng làm việc hàng ngày:**
   * Từng người code trên nhánh `feat/...` của riêng mình.
   * Kéo code mới nhất từ nhánh hội tụ: `git merge dev`.
   * Đẩy code của mình lên: `git push origin <tên-nhánh>`.
   * Giao tiếp trên nhóm, sau đó báo cáo để merge nhánh cá nhân vào `dev`.
   * Nhánh `dev` sẽ được Review và tạo Pull Request (PR) để merge vào `main`.

---

## 🚀 6. Hướng dẫn Khởi chạy

```bash
# 1. Clone dự án
git clone <url-repository>
cd PRM393-SE1946-TodoApp

# 2. Chuyển sang nhánh làm việc (Ví dụ: dev)
git checkout dev

# 3. Tải thư viện
flutter pub get

# 4. Chạy ứng dụng
flutter run
```