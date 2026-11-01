# Checklist kiểm thử thủ công trên Android Emulator

## Chuẩn bị

### Cập nhật cấu hình đăng nhập Google

`android/app/google-services.json` đang dùng project `prm-todo-app-b094c`, nhưng `lib/firebase_options.dart` vẫn dùng project cũ `todo-app-prm393`. Cần đồng bộ cấu hình trước khi đánh giá đăng nhập:

```powershell
firebase login
C:\src\flutter\bin\dart.bat pub global activate flutterfire_cli
flutterfire configure --project=prm-todo-app-b094c
```

Chọn Android với package `com.example.todo_app`. Sau đó dừng app và chạy lại để nạp cấu hình mới.

Lưu ý: `android/app/google-services.json` và `lib/features/auth_and_dashboard/providers/auth_provider.dart` đang có thay đổi local; lệnh FlutterFire cũng có thể sửa `firebase.json` và `lib/firebase_options.dart`. Cả bốn file đều đã được Git theo dõi nên `.gitignore` không ngăn chúng bị stage. Giữ các thay đổi local ở những file này unstaged, và kiểm tra `git status` cùng `git diff --cached` trước khi commit. Không commit hoặc push cấu hình/client ID Firebase trên máy anh.

### Khởi chạy backend để thử đồng bộ

Trong terminal thứ nhất, tại thư mục repo:

```powershell
docker compose -f backend/docker-compose.yml up -d
mvn -f backend/pom.xml spring-boot:run
```

Trong terminal thứ hai, chạy Flutter trên emulator:

```powershell
C:\src\flutter\bin\flutter.bat devices
C:\src\flutter\bin\flutter.bat run -d <deviceId>
```

Thay `<deviceId>` bằng ID emulator được in ra; nếu chỉ có một thiết bị thì có thể bỏ `-d <deviceId>`. Emulator Android kết nối backend trên máy host qua `10.0.2.2:8080`. Nếu chỉ kiểm tra giao diện, backend có thể chưa cần chạy; muốn kiểm tra đồng bộ thì phải bật MySQL và backend.

## Checklist thao tác

1. **Đăng nhập:** mở app, chọn Google account; đăng xuất rồi đăng nhập lại để thử cả hai chiều. Thành công thì app vào Dashboard.
2. **Mở Board:** trên Dashboard bấm shortcut Task Board; route nằm ở `lib/core/router/app_router.dart:73-77`.
3. **Bốn cột:** kiểm tra Chưa làm, Đang làm, Hoàn thành, Đã hủy và số task trên đầu mỗi cột. Cuộn ngang để đổi cột, cuộn dọc từng cột. Vuốt trên thẻ task dành cho thao tác task; để cuộn ngang bảng, thử bắt đầu vuốt ở vùng tiêu đề hoặc khoảng trống.
4. **Đổi trạng thái:** vuốt thẻ sang phải, rồi chạm nút trạng thái hiện ra. Thử Chưa làm → Đang làm → Hoàn thành; task Hoàn thành/Đã hủy sẽ chuyển về Chưa làm. Thử cả checkbox: đánh dấu sẽ chuyển task sang Hoàn thành, bỏ đánh dấu chuyển về Chưa làm. Mã xử lý nằm ở `lib/features/task_board_and_filter/presentation/slidable_task_card.dart:77-93`.
5. **Thao tác khác:** vuốt thẻ sang trái, thử Ưu tiên, Dời hạn và Giao việc; kiểm tra thông tin hiển thị lại trên thẻ sau khi lưu.
6. **Kéo sắp xếp:** khi không có filter và đang ở “Thứ tự thủ công”, kéo tay cầm của task lên/xuống trong cùng cột. Chờ cập nhật xong rồi mới kéo tiếp; thử đồng bộ hoặc mở lại Board để xem thứ tự có được giữ không. Tính năng hiện chưa hỗ trợ kéo task sang cột khác.
7. **Tìm kiếm/lọc:** tìm theo tiêu đề hoặc mô tả; thử filter trạng thái, ưu tiên, hạn và nhãn nếu dữ liệu có nhãn. Thử các kiểu sắp xếp rồi bấm Xóa toàn bộ bộ lọc. Khi đang lọc hoặc đổi sort khỏi thủ công, kéo sắp xếp sẽ tắt.
8. **Chọn nhiều:** nhấn giữ một task để vào chế độ chọn; chọn vài task, thử Hoàn thành và Bỏ chọn. Kiểm tra giới hạn chọn tối đa 5 task.
9. **Đồng bộ:** bấm nút đồng bộ hoặc kéo xuống trong một cột; khi backend chạy sẽ hiện thông báo đồng bộ, nếu backend tắt sẽ hiện lỗi kết nối. Có thể thử offline với một task mẫu, bật lại backend rồi đồng bộ để xem cập nhật chờ được gửi lại.

> Khi server có ít hơn 3 task, provider có thể thêm dữ liệu mẫu vào database. Hãy dùng database thử nghiệm khi kiểm tra seed; tránh reset database đang có dữ liệu cần giữ.
