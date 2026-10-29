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

## 📂 3. Kiến trúc Monorepo & Vùng làm việc (Codebase)

Dự án áp dụng kiến trúc **Feature-First** nghiêm ngặt. Mỗi thành viên được giao quyền sở hữu một thư mục riêng biệt trong `lib/features/` để đảm bảo có thể code song song mà không gây ra xung đột mã nguồn (Merge Conflict).

```text
PRM393-SE1946-TodoApp/
├── backend/                               # Code API Backend (Java/Spring Boot)
├── docs/                                  # Tài liệu thiết kế Database & API
└── lib/                                   # Code Frontend (Flutter/Dart)
    ├── core/                              # Code dùng chung (Models, Theme, Router)
    └── features/                          # KHÔNG GIAN LÀM VIỆC ĐỘC LẬP:
        ├── auth_and_dashboard/            # 👉 Vùng code của: Hà Vũ Long
        ├── task_board_and_filter/         # 👉 Vùng code của: Vũ Hoàng Phúc
        └── task_detail_and_collab/        # 👉 Vùng code của: Nguyễn Hải Đăng
```
*(Quy tắc cốt lõi: Tuyệt đối không chỉnh sửa code bên trong thư mục `features/` của thành viên khác).*

## 👥 4. Đội ngũ, Trách nhiệm & Phân nhánh Git

Bảng dưới đây quy định rõ ràng trách nhiệm của từng người ứng với Tính năng, Thư mục Code và Nhánh Git tương ứng:

| Thành viên | Trách nhiệm & Yêu cầu chi tiết | Thư mục Code (`features/`) | Nhánh Git làm việc (Branch) |
| :--- | :--- | :--- | :--- |
| **Hà Vũ Long** | Xác thực, Adaptive UI, Analytics. 👉 [Xem Yêu cầu chi tiết](./lib/features/auth_and_dashboard/REQUIREMENTS.md) | `auth_and_dashboard/` | `feat/long-auth-adaptive-ui`<br>`feat/long-dashboard` |
| **Vũ Hoàng Phúc** | Task Board, Lọc, Cử chỉ. 👉 [Xem Yêu cầu chi tiết](./lib/features/task_board_and_filter/REQUIREMENTS.md) | `task_board_and_filter/` | `feat/phuc-task-list-gesture`<br>`feat/phuc-search-filter` |
| **Nguyễn Hải Đăng**| CRUD Task, Checklist, Comment. 👉 [Xem Yêu cầu chi tiết](./lib/features/task_detail_and_collab/REQUIREMENTS.md) | `task_detail_and_collab/` | `feat/dang-task-detail-subtask`<br>`feat/dang-comment-reminder` |

> **⚠️ Quy trình Git:** 
> 1. Nhánh `main` đã bị khóa bảo vệ. Tuyệt đối không push trực tiếp.
> 2. Mọi code mới phải được thực hiện trên nhánh `feat/...` của cá nhân.
> 3. Sau khi xong, hợp nhất (merge) nhánh cá nhân vào nhánh `dev`.
> 4. Tạo Pull Request (PR) từ `dev` sang `main` để kiểm duyệt trước khi release.

## 💡 5. Cẩm nang Làm việc Độc lập (Chống "Block" nhau)

Trong quá trình làm việc nhóm, nếu tính năng của bạn cần dữ liệu từ tính năng của người khác (nhưng họ chưa làm xong), **bạn hoàn toàn không cần phải chờ đợi!** Áp dụng 3 quy tắc sau:

1. **Vượt rào bằng Router:** Mặc định app mở lên sẽ vào màn hình Login. Nếu bạn cần code màn hình khác, hãy vào `lib/core/router/app_router.dart`, đổi tạm `initialLocation` trỏ thẳng tới màn hình bạn đang làm (VD: `initialLocation: '/task-detail'`).
2. **Dùng Dữ liệu giả (Mock Data):** Hãy sử dụng kho dữ liệu `MockRepository.mockTasks` trong `lib/core/data/mock_repository.dart` để lấy danh sách/chi tiết công việc (đã có sẵn đủ trạng thái) và đắp vào UI của bạn thay vì chờ Backend/API.
3. **Ráp nối cuối cùng:** Mỗi người cứ thoải mái code và push lên nhánh `feat/` của mình. Đến sát hạn nộp, nhóm chỉ cần ngồi lại, ghép API và sửa đúng 1 file `app_router.dart` để nối các màn hình lại với nhau là xong!

## 🚀 6. Hướng dẫn Khởi chạy

### 6.1. Chạy Backend (Spring Boot)
*Yêu cầu: Đã cài đặt Docker (chạy MySQL) và JDK 17.*
```bash
# 1. Khởi động cơ sở dữ liệu MySQL qua Docker Compose
docker-compose -f backend/docker-compose.yml up -d

# 2. Chạy Spring Boot Server
cd backend
./mvnw spring-boot:run
```
👉 **Kiểm thử API (Swagger):** `http://localhost:8080/swagger-ui.html`

### 6.2. Chạy Frontend (Flutter)
*Yêu cầu: Đã cài đặt Flutter SDK.*
```bash
# 1. Tải các thư viện phụ thuộc
flutter pub get

# 2. Khởi chạy ứng dụng (trên máy ảo hoặc thiết bị thật)
flutter run
```