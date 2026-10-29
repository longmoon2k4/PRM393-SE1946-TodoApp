# 🚀 Smart Workflow & Adaptive Todo App

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)
![Spring Boot](https://img.shields.io/badge/Spring_Boot-6DB33F?style=flat-square&logo=spring-boot&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=flat-square&logo=mysql&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat-square&logo=firebase&logoColor=black)

Nền tảng quản lý công việc và cộng tác nhóm thông minh. Dự án được thiết kế theo kiến trúc **Monorepo**, kết hợp giữa Frontend (Flutter) tập trung vào trải nghiệm Adaptive UI và Backend (Spring Boot RESTful API) mạnh mẽ.

---

## ✨ 1. Tính năng Nổi bật
* **Giao diện Thích ứng (Adaptive UI):** Tự động chuyển đổi màu sắc/bố cục dựa trên độ tải công việc (*Calm, Focus, Overload*).
* **Cử chỉ Thông minh (Smart Gestures):** Vuốt để đổi trạng thái, thao tác nhanh, kéo thả (Drag & Drop) để sắp xếp ưu tiên.
* **Làm việc Nhóm (Collaboration):** Phân quyền dự án, giao việc, bình luận realtime và lưu vết lịch sử (Activity Logs).
* **Bảo mật & Xác thực:** Đăng nhập không mật khẩu qua Google/GitHub (Firebase OAuth 2.0) kết hợp Spring Security.

## 🛠️ 2. Tech Stack
* **Frontend:** Flutter, Riverpod (State Management), GoRouter.
* **Backend:** Java 17, Spring Boot 3, Spring Data JPA, Hibernate.
* **Database:** MySQL 8.0 (Chi tiết: [DATABASE_DESIGN.md](./docs/DATABASE_DESIGN.md)).
* **API Docs:** Swagger UI (Chi tiết: [API_DOCUMENTATION.md](./docs/API_DOCUMENTATION.md)).

## 📂 3. Cấu trúc Monorepo

Dự án được phân chia rõ ràng để làm việc nhóm song song, chống xung đột (Conflict):

```text
PRM393-SE1946-TodoApp/
├── backend/                               # Code API Backend (Java/Spring Boot)
├── docs/                                  # Tài liệu thiết kế Database & API
└── lib/                                   # Code Frontend (Flutter/Dart)
    ├── core/                              # Dùng chung (Models, Theme, Router)
    └── features/                          # Các phân hệ độc lập (Feature-First)
        ├── auth_and_dashboard/            # Phân hệ: Auth & Thống kê
        ├── task_board_and_filter/         # Phân hệ: Quản lý Board & Lọc
        └── task_detail_and_collab/        # Phân hệ: Chi tiết Task & Cộng tác
```

## 👥 4. Đội ngũ & Phân công

| Thành viên | Vai trò & Phân hệ | Nhánh làm việc (Branch) |
| :--- | :--- | :--- |
| **Hà Vũ Long** | Auth (OAuth), Adaptive UI, Analytics | `feat/long-auth-adaptive-ui`, `feat/long-dashboard` |
| **Vũ Hoàng Phúc** | Task Board, Search/Filter, Gestures | `feat/phuc-task-list-gesture`, `feat/phuc-search-filter` |
| **Nguyễn Hải Đăng**| Task CRUD, Subtasks, Collaboration | `feat/dang-task-detail-subtask`, `feat/dang-comment-reminder` |

> **⚠️ Quy trình Git:** Nhánh `main` đã bị khóa bảo vệ. Tuyệt đối không push trực tiếp. Mọi code mới phải thực hiện trên nhánh `feat/...`, sau đó kéo gộp vào `dev`, và tạo Pull Request (PR) để lên `main`.

## 🚀 5. Hướng dẫn Khởi chạy

### 5.1. Chạy Backend (Spring Boot)
*Yêu cầu: Đã cài đặt Docker (chạy MySQL) và JDK 17.*
```bash
# 1. Khởi động cơ sở dữ liệu MySQL qua Docker Compose
docker-compose -f backend/docker-compose.yml up -d

# 2. Chạy Spring Boot Server
cd backend
./mvnw spring-boot:run
```
👉 **Kiểm thử API (Swagger):** `http://localhost:8080/swagger-ui.html`

### 5.2. Chạy Frontend (Flutter)
*Yêu cầu: Đã cài đặt Flutter SDK.*
```bash
# 1. Tải các thư viện phụ thuộc
flutter pub get

# 2. Khởi chạy ứng dụng (trên máy ảo hoặc thiết bị thật)
flutter run
```