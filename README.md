# Todo App Mobile

Flutter client cho Dev-Platform Todo API.

## Chay local

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
```

Android emulator dùng `10.0.2.2` để trỏ về máy host. iOS simulator có thể dùng
`http://localhost:8080/api/v1`.

## Cau truc

- `lib/core`: cấu hình và HTTP client dùng chung.
- `lib/features/auth`: register, login, token storage.
- `lib/features/tasks`: model, repository và task list.

Google/Firebase Auth sẽ được thêm sau khi project Firebase cung cấp file cấu hình native.
