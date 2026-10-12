# Todo App Mobile

Ứng dụng Flutter phía mobile cho Dev-Platform Todo API. Phiên bản hiện tại hỗ trợ đăng ký, đăng nhập và xem danh sách task từ API.

## Chức năng hiện có

- Đăng ký bằng họ tên, email và mật khẩu.
- Đăng nhập và lưu access token bằng `flutter_secure_storage`.
- Gửi access token trong header `Authorization: Bearer ...` cho các request tiếp theo.
- Tải danh sách task, kéo xuống để tải lại và thử tải lại khi request lỗi.
- Đăng xuất bằng cách xóa access token trên thiết bị.

Màn hình task hiện chỉ đọc dữ liệu. Nút thêm task chưa được nối chức năng; app chưa có luồng tạo, sửa, xóa hoặc đổi trạng thái task.

## Luồng màn hình

```text
Mở ứng dụng
    |
    v
Đăng nhập / Đăng ký
    | đăng ký (nếu cần), sau đó đăng nhập
    v
Lưu access token
    |
    v
My tasks ---- tải lại ----> Danh sách task từ API
    |
    +---- Log out ----> Xóa token ----> Đăng nhập / Đăng ký
```

## Công nghệ

- Flutter / Dart, giao diện Material 3.
- `http` cho HTTP API.
- `flutter_secure_storage` để lưu access token.
- `flutter_test` và `flutter_lints` cho kiểm thử widget và phân tích tĩnh.

## Cấu trúc thư mục

```text
.
├── android/                           # Cấu hình nền tảng Android
├── ios/                               # Cấu hình nền tảng iOS
├── lib/
│   ├── main.dart                      # Khởi tạo app và dependency
│   ├── core/
│   │   ├── config/app_config.dart     # API base URL
│   │   └── network/api_client.dart    # HTTP client, token và xử lý lỗi API
│   └── features/
│       ├── auth/
│       │   ├── data/auth_repository.dart
│       │   └── presentation/auth_page.dart
│       └── tasks/
│           ├── data/task_repository.dart
│           └── presentation/task_home_page.dart
├── test/
│   └── widget_test.dart               # Kiểm tra màn hình đăng nhập hiển thị
├── pubspec.yaml                       # Dependencies và cấu hình Flutter
└── README.md
```

## API đang được sử dụng

Base URL mặc định là `http://10.0.2.2:8080/api/v1`.

| Method | Endpoint | Mục đích |
|---|---|---|
| `POST` | `/auth/register` | Gửi `email`, `password`, `fullName` để đăng ký |
| `POST` | `/auth/login` | Đăng nhập; response cần có `accessToken` |
| `GET` | `/todo/tasks` | Lấy danh sách task |
| `GET` | `/users/me` | Repository có hỗ trợ lấy user hiện tại; màn hình hiện chưa gọi endpoint này |

Mỗi task được đọc với các trường `id`, `title`, `status`, `priority` và `deadline` tùy chọn. `deadline` cần có định dạng ngày giờ mà `DateTime.parse` của Dart đọc được.

## Yêu cầu

- Flutter SDK có Dart SDK đáp ứng constraint `^3.13.4` trong `pubspec.yaml`.
- Todo API đang chạy và thiết bị/emulator truy cập được API.

## Chạy ứng dụng

Từ thư mục `groupProject/PRM393-SE1946-TodoApp`:

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
```

`10.0.2.2` là địa chỉ để Android emulator truy cập máy host. Với iOS simulator, dùng:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

Có thể thay URL bằng môi trường API khác qua `--dart-define=API_BASE_URL=...`. Backend cần được khởi chạy riêng.

URL Android mẫu dùng HTTP. Nếu Android build target API 28 trở lên, cleartext traffic mặc định bị chặn; manifest hiện tại chưa khai báo ngoại lệ. Dùng HTTPS khi có thể hoặc cấu hình cho phép HTTP trong debug theo domain backend. Xem [Android Network Security Configuration](https://developer.android.com/privacy-and-security/security-config). Không bật HTTP cleartext rộng cho bản phát hành.

## Phạm vi chưa triển khai

- Khôi phục phiên đăng nhập khi mở lại app; hiện app luôn mở màn hình đăng nhập.
- Tạo, sửa, xóa task và cập nhật trạng thái.
- Kanban, thêm/sửa/xóa cột trạng thái, danh mục, thống kê và thông báo.
- Google/Firebase Auth; README hiện tại chưa cấu hình Firebase native.
- Android release hiện chưa có quyền `INTERNET` trong `src/main/AndroidManifest.xml`; các request API sẽ không hoạt động ở bản release cho đến khi thêm quyền này. Quyền hiện chỉ có trong manifest debug và profile.
