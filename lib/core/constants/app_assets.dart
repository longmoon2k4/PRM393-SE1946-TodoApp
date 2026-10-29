/// Lớp quản lý toàn bộ đường dẫn tĩnh (Assets) trong ứng dụng.
/// Tuyệt đối KHÔNG gõ đường dẫn chuỗi (String) trực tiếp trong code UI.
class AppAssets {
  AppAssets._(); // Private constructor để không cho phép khởi tạo object

  // --- Thư mục Hình ảnh (images) ---
  static const String logo = 'assets/images/logo.png';
  static const String emptyTasks = 'assets/images/empty_tasks.png';
  static const String error404 = 'assets/images/error_404.png';
  
  // --- Thư mục Biểu tượng (icons) ---
  // Ghi chú: Ưu tiên dùng thư viện `lucide_icons_flutter` thay vì import SVG riêng lẻ.
  // Chỉ dùng cho các icon đặc thù không có trong thư viện.
  // VD: static const String customIcon = 'assets/icons/custom.svg';

  // --- Thư mục Lottie (Ảnh động) ---
  // VD: static const String loadingAnimation = 'assets/lottie/loading.json';
}
