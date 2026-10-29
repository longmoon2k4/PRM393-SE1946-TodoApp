# Backend - Spring Boot

Backend RESTful API cho Smart Workflow & Adaptive Todo App.

## 🛠️ Tech Stack
- Java 17+ (khuyến nghị JDK 21 Temurin)
- Spring Boot 3.2.5
- Spring Data JPA, Spring Security, Spring Validation
- MySQL 8 (Docker)
- Springdoc OpenAPI (Swagger UI)

## 🚀 Chạy nhanh

### 1) Khởi động MySQL
```bash
cd backend
docker compose up -d
```
MySQL sẽ tự tạo DB `todo_db` và toàn bộ bảng từ `sql/init.sql` (chỉ ở lần đầu).

### 2) Chạy backend
```bash
export JAVA_HOME=/home/smile/.sdkman/candidates/java/21.0.2-tem
export PATH=$JAVA_HOME/bin:$PATH
mvn spring-boot:run
```

- API base: `http://localhost:8080/api/v1`
- Swagger UI: `http://localhost:8080/swagger-ui.html`

### Reset DB sạch
```bash
docker compose down -v
docker compose up -d
```

## 🗄️ Database
- Chi tiết thiết kế: [`../docs/DATABASE_DESIGN.md`](../docs/DATABASE_DESIGN.md)
- Init script: [`sql/init.sql`](./sql/init.sql)
- Hibernate `ddl-auto=update` được bật để đồng bộ schema.

## 🌐 API
- Tài liệu: [`../docs/API_DOCUMENTATION.md`](../docs/API_DOCUMENTATION.md)
- Các nhóm: Users, Tasks, Subtasks, Comments, Projects, Categories.

## 📝 Ghi chú
- Backend hiện chạy dev mode (`permitAll`).
- CORS đã bật cho frontend.
- Nếu thay đổi model, Hibernate sẽ tự cập nhật schema khi restart.
