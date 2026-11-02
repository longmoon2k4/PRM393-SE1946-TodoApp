# Checklist kiểm thử thủ công trên Android Emulator

## Chuẩn bị

### Cập nhật cấu hình đăng nhập Google

`android/app/google-services.json` và `lib/firebase_options.dart` cần trỏ tới cùng Firebase project. Dùng project ID của anh:

```powershell
firebase login
C:\src\flutter\bin\dart.bat pub global activate flutterfire_cli
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
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
2. **Mở Board và về Home:** trên Dashboard bấm shortcut Task Board. Trong Board, nút hình ngôi nhà đưa về Dashboard; nút hamburger mở menu bên cạnh.
3. **Bốn cột:** kiểm tra Chưa làm, Đang làm, Hoàn thành, Đã hủy và số task trên đầu mỗi cột. Cuộn ngang để đổi cột, cuộn dọc từng cột. Vuốt trên thẻ task dành cho thao tác task; để cuộn ngang bảng, thử bắt đầu vuốt ở vùng tiêu đề hoặc khoảng trống.
4. **Đổi trạng thái:** vuốt thẻ sang phải, rồi chạm nút trạng thái hiện ra. Thử Chưa làm → Đang làm → Hoàn thành → Đã hủy → Chưa làm.
5. **Checkbox:** ngoài chế độ chọn nhiều, checkbox đánh dấu Hoàn thành; bỏ dấu đưa task về Chưa làm. Chỉ nhấn giữ task mới vào chế độ chọn nhiều.
6. **Menu project/category:** mở bằng nút hamburger. Nếu không có task nào được gán project/category, menu báo chưa có mục để lọc; “Mọi project/category” đóng menu và xóa bộ lọc phạm vi.
7. **Thao tác khác:** vuốt thẻ sang trái, thử Ưu tiên, Dời hạn và Giao việc; kiểm tra thông tin hiển thị lại trên thẻ sau khi lưu.
8. **Kéo sắp xếp:** khi không có filter và đang ở “Thứ tự thủ công”, kéo tay cầm của task lên/xuống trong cùng cột. Chờ cập nhật xong rồi mới kéo tiếp; thử đồng bộ hoặc mở lại Board để xem thứ tự có được giữ không. Tính năng hiện chưa hỗ trợ kéo task sang cột khác.
9. **Tìm kiếm/lọc:** tìm theo tiêu đề hoặc mô tả; thử filter trạng thái, ưu tiên, hạn và nhãn nếu dữ liệu có nhãn. Thử các kiểu sắp xếp rồi bấm Xóa toàn bộ bộ lọc. Khi đang lọc hoặc đổi sort khỏi thủ công, kéo sắp xếp sẽ tắt.
10. **Chọn nhiều:** nhấn giữ một task để vào chế độ chọn; chọn vài task, thử Hoàn thành và Bỏ chọn. Kiểm tra giới hạn chọn tối đa 5 task.
11. **Đồng bộ:** khi backend chạy, bấm nút đồng bộ hoặc kéo xuống trong một cột và kiểm tra task thay đổi có lưu lên server. Khi backend tắt, thao tác cập nhật vẫn lưu cache nhưng không có hàng đợi retry; lần sync sau có thể thay cache bằng dữ liệu server. Vì vậy hãy dùng backend đang chạy để kiểm tra việc lưu trạng thái.

> Khi server có ít hơn 3 task, provider có thể thêm dữ liệu mẫu vào database. Hãy dùng database thử nghiệm khi kiểm tra seed; tránh reset database đang có dữ liệu cần giữ.
