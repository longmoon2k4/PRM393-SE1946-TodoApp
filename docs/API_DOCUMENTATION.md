# 🌐 Tài liệu API Backend (RESTful)

Tài liệu này cung cấp danh sách các API để kết nối ứng dụng Flutter (Frontend) với Spring Boot (Backend). Để người mới đọc dễ hiểu, tôi đã liệt kê rõ phương thức, đường dẫn, dữ liệu gửi lên và kết quả trả về.

## 🔐 1. Xác thực (Authentication)
Tất cả các API bên dưới (ngoại trừ các API Public nếu có) đều yêu cầu gửi kèm Token của Firebase trong Header.

* **Header:**
  * `Authorization`: `Bearer <Firebase_ID_Token>`
* **Logic Backend:** Spring Boot sẽ kiểm tra Token này. Nếu hợp lệ, nó sẽ cho phép thực hiện thao tác và nhận diện được `user_id` đang gọi API.

---

## 🧑‍💻 2. API Quản lý Người dùng (Users)

### 2.1. Đồng bộ User từ Firebase
Khi người dùng đăng nhập Google thành công lần đầu trên Flutter, gọi API này để lưu thông tin user vào MySQL.

* **Method:** `POST`
* **Endpoint:** `/api/v1/users/sync`
* **Body (JSON):** (Không cần truyền ID vì Backend tự bóc tách từ Token)
  ```json
  {
    "email": "user@gmail.com",
    "name": "Nguyễn Văn A",
    "avatarUrl": "https://..."
  }
  ```
* **Response (200 OK):** Trả về object User đã được lưu.

---

## 📝 3. API Quản lý Công việc (Tasks)

### 3.1. Lấy danh sách Task (Có bộ lọc)
* **Method:** `GET`
* **Endpoint:** `/api/v1/tasks`
* **Query Parameters (Tùy chọn):**
  * `?status=todo` (Lọc theo trạng thái)
  * `?priority=high` (Lọc theo độ ưu tiên)
  * `?projectId=123` (Lấy task của 1 dự án cụ thể)
* **Response (200 OK):**
  ```json
  [
    {
      "id": "task-uuid-1",
      "title": "Học Flutter",
      "status": "todo",
      "priority": "high",
      "orderIndex": 1.0,
      "deadline": "2026-10-30T10:00:00Z"
    }
  ]
  ```

### 3.2. Lấy chi tiết một Task (Kèm Subtask & Comments)
* **Method:** `GET`
* **Endpoint:** `/api/v1/tasks/{taskId}`

### 3.3. Tạo Task mới
* **Method:** `POST`
* **Endpoint:** `/api/v1/tasks`
* **Body (JSON):**
  ```json
  {
    "title": "Viết báo cáo",
    "description": "Hoàn thành chương 1",
    "priority": "medium",
    "projectId": "project-uuid"
  }
  ```

### 3.4. Cập nhật trạng thái Task nhanh (Vuốt thẻ - Gesture)
API này tối ưu cho hành động vuốt thẻ để đổi trạng thái.
* **Method:** `PATCH`
* **Endpoint:** `/api/v1/tasks/{taskId}/status`
* **Body (JSON):**
  ```json
  {
    "status": "in_progress"
  }
  ```

### 3.5. Kéo thả Task (Cập nhật Order Index)
* **Method:** `PATCH`
* **Endpoint:** `/api/v1/tasks/{taskId}/order`
* **Body (JSON):**
  ```json
  {
    "newOrderIndex": 2.5
  }
  ```

### 3.6. Xóa Task (Xóa mềm / Thùng rác)
* **Method:** `DELETE`
* **Endpoint:** `/api/v1/tasks/{taskId}`
* **Response (200 OK):** Task không bị xóa hẳn khỏi Database mà cột `deleted_at` sẽ được cập nhật ngày giờ xóa.

---

## ✅ 4. API Subtasks (Checklist)

### 4.1. Đánh dấu hoàn thành một Subtask
* **Method:** `PATCH`
* **Endpoint:** `/api/v1/subtasks/{subtaskId}/toggle`
* **Response (200 OK):**
  ```json
  {
    "id": "subtask-uuid",
    "isCompleted": true
  }
  ```

---

## 💬 5. API Comments (Bình luận)

### 5.1. Thêm bình luận vào Task
* **Method:** `POST`
* **Endpoint:** `/api/v1/tasks/{taskId}/comments`
* **Body (JSON):**
  ```json
  {
    "content": "Tôi đã làm xong phần này rồi nhé!"
  }
  ```

---
*Ghi chú: Ngoài tài liệu Markdown này, Backend sẽ cung cấp một giao diện web Swagger UI (truy cập tại `http://localhost:8080/swagger-ui.html`) để nhóm có thể bấm test API trực tiếp trên trình duyệt mà không cần dùng Postman!*