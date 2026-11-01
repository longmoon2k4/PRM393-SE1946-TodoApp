# Hướng dẫn đọc code dự án

Tài liệu này bám theo code hiện tại của ứng dụng Flutter và backend Spring Boot. Nên đọc theo một luồng task cụ thể trước, rồi mở rộng sang các màn hình và phần còn lại của dự án.

## 1. Cấu trúc chính

```text
lib/
├── core/                         # Thành phần Flutter dùng chung
│   ├── models/                    # Model và chuyển đổi JSON
│   ├── providers/                 # State dùng chung; core_tasks_provider quản lý task
│   ├── services/                  # REST API, cache local, notification
│   ├── router/                    # Các đường dẫn màn hình
│   ├── theme/                     # Màu, kích thước, theme thích ứng
│   ├── widgets/                   # Widget dùng lại
│   └── data/                      # MockRepository cho dữ liệu giả
└── features/
    ├── auth_and_dashboard/        # Login, profile, dashboard, thống kê
    ├── task_board_and_filter/     # Kanban, vuốt task, tìm kiếm và bộ lọc
    └── task_detail_and_collab/    # Form, checklist, comment, reminder

backend/
├── src/main/java/com/todoapp/api/ # Controller, DTO, model, repository, config
├── src/main/resources/            # application.yml
└── sql/init.sql                   # Schema khởi tạo MySQL
```

Trong mỗi feature, `presentation/` chứa màn hình/widget và `providers/` giữ state hoặc logic của feature. Các file `REQUIREMENTS.md` mô tả phần việc dự kiến của từng feature; khi muốn biết hành vi đang chạy, hãy đối chiếu với Dart/Java source.

## 2. Luồng mở ứng dụng

1. `lib/main.dart`: khởi tạo Flutter, cache, notification và Firebase, sau đó dựng `ProviderScope`.
2. `lib/core/router/app_router.dart`: ánh xạ URL như `/login`, `/dashboard`, `/board` và `/task-detail` sang màn hình.
3. `lib/features/task_board_and_filter/presentation/task_board_screen.dart`: dựng Board, đọc state từ Riverpod và chuyển thao tác người dùng sang provider.

## 3. Theo một task từ dữ liệu tới database

```text
TaskBoardScreen / SlidableTaskCard
          │ thao tác của người dùng
          ▼
coreTasksProvider (CoreTasksNotifier)
     ├── LocalStorageService ── SharedPreferences trên thiết bị
     └── TaskApiService ── HTTP ── TaskController
                                      │
                               TaskRepository
                                      │
                                  MySQL
```

Đọc các file theo thứ tự sau:

1. `lib/core/models/task_model.dart` — `TaskItem` là model task. `toJson()` lưu cache local đầy đủ; `toBackendJson()` tạo payload REST; `fromJson()` chuyển response/cache về model Dart. Ví dụ, `TaskStatus.inProgress` được gửi là `in_progress`.
2. `lib/core/services/local_storage_service.dart` — serialize danh sách task thành JSON trong `SharedPreferences` và khôi phục danh sách khi app mở lại.
3. `lib/core/services/task_api_service.dart` — chọn địa chỉ backend, thiết lập Dio và gom các request task.
4. `lib/core/providers/core_tasks_provider.dart` — `CoreTasksNotifier.build()` đọc cache rồi khởi động đồng bộ; thao tác thêm/sửa/xóa cập nhật state và cache trước khi gọi API.
5. `lib/features/task_board_and_filter/providers/task_filter_sort_provider.dart` — áp dụng tìm kiếm, điều kiện lọc và sắp xếp trên danh sách task đã tải.
6. `lib/features/task_board_and_filter/presentation/search_filter_bar.dart` và `category_project_drawer.dart` — lấy tiêu chí từ giao diện và cập nhật filter provider.
7. `lib/features/task_board_and_filter/presentation/slidable_task_card.dart` — hiển thị một task, checkbox và các hành động vuốt.
8. `lib/features/task_board_and_filter/presentation/task_board_screen.dart` — chia danh sách thành cột theo `TaskStatus`, nối callback của thẻ với provider.
9. Phía backend: `TaskController.java` nhận HTTP → `TaskRequest`/`StatusUpdateRequest` mô tả dữ liệu vào → `Task` ánh xạ bảng `tasks` → `TaskRepository` đọc/ghi JPA → `backend/sql/init.sql` cho schema ban đầu.

`CoreTasksNotifier` hiện lưu local trước để UI phản hồi ngay. Nếu request thất bại, code ghi log và giữ cache, nhưng chưa có hàng đợi gửi lại tự động; khi server trả danh sách có task, danh sách đó thay state/cache local.

## 4. Các API task hiện có

Các đường dẫn dưới đây lấy từ `backend/src/main/java/com/todoapp/api/controller/TaskController.java`:

| Method | Đường dẫn | Ý nghĩa |
|---|---|---|
| `GET` | `/api/v1/tasks` | Lấy danh sách; nhận query như `status`, `priority`, `projectId`, `categoryId`, `assigneeId`, `search` |
| `GET` | `/api/v1/tasks/{id}` | Lấy một task |
| `POST` | `/api/v1/tasks` | Tạo task |
| `PUT` | `/api/v1/tasks/{id}` | Cập nhật task |
| `PATCH` | `/api/v1/tasks/{id}/status` | Đổi trạng thái |
| `PATCH` | `/api/v1/tasks/{id}/order` | Đổi `orderIndex` |
| `DELETE` | `/api/v1/tasks/{id}` | Xóa mềm bằng cách đặt `deletedAt` |
| `POST` | `/api/v1/tasks/{id}/comments` | Thêm comment |
| `POST` | `/api/v1/tasks/{id}/subtasks` | Thêm subtask |
| `GET` | `/api/v1/tasks/{id}/activity` | Lấy lịch sử hoạt động |

`SubtaskController` còn có `PATCH /api/v1/subtasks/{id}/toggle` và `DELETE /api/v1/subtasks/{id}`. `ProjectController`, `CategoryController`, `UserController` lần lượt xử lý các endpoint dưới `/api/v1/projects`, `/api/v1/categories`, `/api/v1/users`.

Flutter `TaskApiService` hiện gọi list/detail/create/update/status/delete. Kéo sắp xếp trên Board đang lưu bằng `updateTask()` (PUT task), dù backend cũng có endpoint PATCH order. Màn chi tiết hiện còn khung `Scaffold`; `task_crud_provider.dart` đang rỗng nên các endpoint comment/subtask chưa được nối từ màn đó.

**Xác thực:** client đính kèm Firebase token nếu có phiên đăng nhập. Tuy vậy `SecurityConfig.java` hiện đặt `anyRequest().permitAll()`, nên backend chưa bắt buộc token; phần mô tả xác thực trong `docs/API_DOCUMENTATION.md` chưa khớp cấu hình thực tế.

## 5. Đọc phần Task Board theo chức năng

- Board và bốn cột trạng thái: `task_board_screen.dart`.
- Vuốt, checkbox, nhãn trên task: `slidable_task_card.dart`.
- Tìm kiếm có debounce 300 ms và sheet lọc: `search_filter_bar.dart`.
- Điều kiện lọc/sắp xếp: `task_filter_sort_provider.dart`.
- Chọn tối đa 5 task và hành động hàng loạt: `multi_select_provider.dart`, sau đó xem `_completeSelectedTasks()` trong Board.
- Drawer project/category: `category_project_drawer.dart`; các mục hiện được rút ra từ ID trên task, không tải danh sách bằng API riêng.

## 6. Đọc tiếp phần còn lại

- Đăng nhập và dashboard: bắt đầu ở `lib/features/auth_and_dashboard/presentation/`, sau đó theo provider tương ứng.
- Checklist/comment/reminder: xem `lib/features/task_detail_and_collab/`; một số file hiện mới là placeholder, nên kiểm tra code trước khi dựa vào mô tả tính năng.
- Thiết kế quan hệ DB: `docs/DATABASE_DESIGN.md`; endpoint đã ghi trong `docs/API_DOCUMENTATION.md`, nhưng khi có khác biệt hãy ưu tiên mapping trong controller.
- Test hiện có: `test/widget_test.dart`.

## 7. Chạy local

Chạy MySQL và backend trong một cửa sổ PowerShell:

```powershell
Set-Location 'C:\full\PRM393\groupProject\PRM393-SE1946-TodoApp'
docker compose -f backend/docker-compose.yml up -d
mvn -f backend/pom.xml spring-boot:run
```

Trong cửa sổ khác, chạy Flutter:

```powershell
Set-Location 'C:\full\PRM393\groupProject\PRM393-SE1946-TodoApp'
flutter pub get
flutter devices
flutter run -d <deviceId>
```

Thay `<deviceId>` bằng ID từ `flutter devices`. Trên Android emulator, API mặc định dùng `http://10.0.2.2:8080`; trình duyệt và các nền tảng khác mặc định dùng `http://localhost:8080` (xem `TaskApiService.defaultBaseUrl`).
