# 🚀 Smart Workflow & Adaptive Todo App

Ứng dụng quản lý công việc và cộng tác nhóm linh hoạt, phát triển bằng **Flutter** (frontend) và **Spring Boot** (backend), cơ sở dữ liệu **MySQL** chạy qua **Docker**.

---

## 📌 1. Tổng quan

- **Frontend**: Flutter (Dart), Riverpod, GoRouter, Firebase Auth
- **Backend**: Spring Boot 3.2, Spring Data JPA, Spring Security, Springdoc OpenAPI
- **Database**: MySQL 8 (Docker)
- **Kiến trúc**: Feature-First (Flutter) + Layered (Spring Boot)

### Tính năng chính
- Adaptive UI theo “độ tải” công việc (Calm / Focus / Overload)
- Smart gestures: vuốt đổi trạng thái, kéo thả sắp xếp
- Quản lý task, subtask, comment, tag, activity log
- Làm việc nhóm: project, phân quyền thành viên
- Đồng bộ user từ Firebase (OAuth)

---

## 👥 2. Phân công nhóm

| Thành viên | Vai trò & Phân hệ | Nhánh |
| :--- | :--- | :--- |
| **Hà Vũ Long** | Authentication (OAuth), Adaptive UI Engine, Analytics Dashboard | `feat/long-auth-adaptive-ui`, `feat/long-dashboard` |
| **Vũ Hoàng Phúc** | Task Board, Search/Filter Engine, Smart Gestures | `feat/phuc-task-list-gesture`, `feat/phuc-search-filter` |
| **Nguyễn Hải Đăng** | Task CRUD, Subtasks, Collaboration, Notifications | `feat/dang-task-detail-subtask`, `feat/dang-comment-reminder` |

---

## 📁 3. Cấu trúc dự án

```text
PRM393-SE1946-TodoApp/
├── lib/                      # Flutter app (Feature-First)
├── backend/                  # Spring Boot backend
│   ├── src/main/java/...     # Controllers, models, repositories
│   ├── src/main/resources/   # application.yml
│   ├── sql/init.sql          # MySQL init script (auto-run by Docker)
│   ├── docker-compose.yml    # MySQL container
│   └── README.md
├── docs/                     # DATABASE_DESIGN.md, API_DOCUMENTATION.md
└── README.md
```

---

## 🛠️ 4. Yêu cầu môi trường

- **Flutter SDK** (>= 3.6)
- **JDK 17+** (khuyến nghị JDK 21 Temurin)
- **Maven 3.9+**
- **Docker** (cho MySQL)

---

## 🚀 5. Khởi chạy nhanh

### 5.1. Clone và checkout
```bash
git clone https://github.com/longmoon2k4/PRM393-SE1946-TodoApp.git
cd PRM393-SE1946-TodoApp
git checkout dev
```

### 5.2. Chạy Backend + MySQL
```bash
cd backend

# 1) Khởi động MySQL (Docker) - tự tạo DB và bảng từ sql/init.sql
docker compose up -d

# 2) Chạy Spring Boot
export JAVA_HOME=/home/smile/.sdkman/candidates/java/21.0.2-tem  # hoặc JDK 17+
export PATH=$JAVA_HOME/bin:$PATH
mvn spring-boot:run
```

- API base: `http://localhost:8080/api/v1`
- Swagger UI: `http://localhost:8080/swagger-ui.html`
- MySQL: `localhost:3306`, DB `todo_db`, user `root`, password `password`

> Lần đầu chạy MySQL, container sẽ tự thực thi `sql/init.sql` để tạo đầy đủ các bảng.
> Nếu muốn reset DB sạch: `docker compose down -v && docker compose up -d`.

### 5.3. Chạy Flutter
```bash
cd ..   # về thư mục gốc
cd PRM393-SE1946-TodoApp
flutter pub get
flutter run
```

---

## 🗄️ 6. Database

Thiết kế chi tiết: [`docs/DATABASE_DESIGN.md`](./docs/DATABASE_DESIGN.md)

Các bảng chính:
- `users`, `projects`, `project_members`
- `categories`, `tasks`, `subtasks`
- `task_comments`, `activity_logs`
- `tags`, `task_tags`

Hibernate `ddl-auto=update` được bật để đồng bộ schema; `init.sql` đảm bảo DB có sẵn bảng ngay từ lần chạy đầu.

---

## 🌐 7. API Documentation

Tài liệu API: [`docs/API_DOCUMENTATION.md`](./docs/API_DOCUMENTATION.md)

Nhóm API:
- **Users**: sync user từ Firebase
- **Tasks**: CRUD, filter, status, order, soft delete
- **Subtasks**: toggle hoàn thành
- **Comments**: thêm bình luận
- **Projects / Categories**: CRUD

Swagger UI cho phép test trực tiếp: `http://localhost:8080/swagger-ui.html`

---

## 🔐 8. Xác thực

- Frontend dùng Firebase Auth (Google/GitHub).
- Backend hiện tại cho phép `permitAll` (dev mode) và đồng bộ user qua `/api/v1/users/sync`.
- Khi triển khai production, nên bật verify Firebase ID Token ở backend.

---

## 🤝 9. Git Workflow

1. Nhánh `main`: bản release ổn định (protected).
2. Nhánh `dev`: hội tụ code.
3. Mỗi thành viên code trên nhánh `feat/...` riêng.
4. Daily flow:
   - `git pull origin dev`
   - code + commit
   - push nhánh cá nhân
   - tạo PR vào `dev`

---

## 🧪 10. Kiểm thử nhanh Backend

```bash
cd backend
# Tạo user
curl -X POST http://localhost:8080/api/v1/users/sync \
  -H 'Content-Type: application/json' \
  -d '{"email":"test@gmail.com","name":"Test User"}'

# Tạo task
curl -X POST http://localhost:8080/api/v1/tasks \
  -H 'Content-Type: application/json' \
  -d '{"title":"Task demo","priority":"high"}'

# Lấy danh sách
curl http://localhost:8080/api/v1/tasks
```

---

## 📄 License

Dự án phục vụ học tập (PRM393).
