import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginRegisterScreen extends ConsumerWidget {
  const LoginRegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 100,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 24),
              Text(
                'Smart Workflow Todo',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Quản lý công việc thông minh & hiệu quả',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 48),

              // Nút Đăng nhập Google
              ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(authControllerProvider).signInWithGoogle();
                },
                icon: Brand(Brands.google, size: 24),
                label: const Text(
                  'Đăng nhập bằng Google',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Nút Đăng nhập GitHub
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement GitHub Sign-in sau
                },
                icon: Brand(Brands.github, size: 24),
                label: const Text(
                  'Đăng nhập bằng GitHub',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF24292E),
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
