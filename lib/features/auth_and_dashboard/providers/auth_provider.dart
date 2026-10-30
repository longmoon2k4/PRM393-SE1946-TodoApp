import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/notification_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final bool isOffline;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isOffline = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    bool? isOffline,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthNotifier extends Notifier<AuthState> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  bool _googleSignInInitialized = false;

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:8080',
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
    ),
  );

  @override
  AuthState build() {
    // Tự động kiểm tra phiên đăng nhập đã lưu trong Local Cache hoặc Firebase
    final cachedUser = LocalStorageService.getCachedUser();
    final firebaseUser = _firebaseAuth.currentUser;

    if (firebaseUser != null) {
      final user = cachedUser ??
          UserModel(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'Người dùng',
            email: firebaseUser.email ?? '',
            avatarUrl: firebaseUser.photoURL,
          );
      return AuthState(status: AuthStatus.authenticated, user: user);
    } else if (cachedUser != null) {
      return AuthState(
        status: AuthStatus.authenticated,
        user: cachedUser,
        isOffline: true,
      );
    }

    return const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> _ensureGoogleInitialized() async {
    if (!_googleSignInInitialized) {
      try {
        await GoogleSignIn.instance.initialize(
          serverClientId: '387812790123-v375adnsh554sb3bhepqlvta35sq01k9.apps.googleusercontent.com',
        );
        _googleSignInInitialized = true;
      } catch (e) {
        debugPrint('GoogleSignIn initialize: $e');
      }
    }
  }

  /// Đăng nhập duy nhất bằng Google OAuth 2.0
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      await _ensureGoogleInitialized();
      
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      
      if (googleUser == null) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Người dùng đã hủy đăng nhập.',
        );
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final User? fbUser = userCredential.user;

      if (fbUser == null) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Không thể lấy thông tin tài khoản Firebase.',
        );
        return false;
      }

      // Lấy ngưỡng công việc cũ nếu có trong cache, mặc định 10
      final cachedUser = LocalStorageService.getCachedUser();
      final user = UserModel(
        id: fbUser.uid,
        name: fbUser.displayName ?? googleUser.displayName ?? 'Người dùng',
        email: fbUser.email ?? googleUser.email,
        avatarUrl: fbUser.photoURL ?? googleUser.photoUrl,
        backlogThreshold: cachedUser?.backlogThreshold ?? 10,
        notifyOnOverload: cachedUser?.notifyOnOverload ?? true,
        notifyOnDeadline: cachedUser?.notifyOnDeadline ?? true,
      );

      // Lưu ngay vào LocalStorage để sẵn sàng cho chế độ offline
      await LocalStorageService.saveUser(user);

      // Đồng bộ thông tin với Backend Spring Boot (nếu có kết nối)
      try {
        final idToken = await fbUser.getIdToken();
        await _dio.post(
          '/api/v1/users/sync',
          options: Options(
            headers: {'Authorization': 'Bearer $idToken'},
          ),
          data: {
            'email': user.email,
            'name': user.name,
            'avatarUrl': user.avatarUrl,
          },
        );
        await LocalStorageService.updateLastSyncTime();
      } catch (dioError) {
        debugPrint(
            'Lưu ý: Không thể đồng bộ user với Spring Boot backend (server có thể chưa bật): $dioError');
      }

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isOffline: false,
      );
      return true;
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Lỗi đăng nhập Google: ${e.toString()}',
      );
      return false;
    }
  }

  /// Cập nhật ngưỡng công việc tồn đọng (Backlog Threshold)
  Future<void> updateBacklogThreshold(int newThreshold) async {
    if (state.user == null) return;
    final updated = state.user!.copyWith(backlogThreshold: newThreshold);
    await LocalStorageService.saveUser(updated);
    state = state.copyWith(user: updated);
  }

  /// Cập nhật tùy chọn nhận thông báo
  Future<void> updateNotificationPreferences({
    bool? notifyOnOverload,
    bool? notifyOnDeadline,
  }) async {
    if (state.user == null) return;
    final updated = state.user!.copyWith(
      notifyOnOverload: notifyOnOverload,
      notifyOnDeadline: notifyOnDeadline,
    );
    await LocalStorageService.saveUser(updated);
    state = state.copyWith(user: updated);
  }

  /// Đăng xuất khỏi Firebase và xóa phiên cục bộ
  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _ensureGoogleInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('Google SignOut Error: $e');
    }
    try {
      await _firebaseAuth.signOut();
      await LocalStorageService.clearUser();
      await NotificationService.cancelAllNotifications();
    } catch (e) {
      debugPrint('Firebase SignOut Error: $e');
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
