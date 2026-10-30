import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/providers/core_tasks_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/adaptive_theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  double _sliderValue = 10.0;
  bool _notifyOverload = true;
  bool _notifyDeadline = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _sliderValue = user.backlogThreshold.toDouble();
      _notifyOverload = user.notifyOnOverload;
      _notifyDeadline = user.notifyOnDeadline;
    }
  }

  void _onSliderChanged(double val) {
    setState(() => _sliderValue = val);
  }

  Future<void> _saveThreshold(double val) async {
    final intVal = val.round();
    await ref.read(authProvider.notifier).updateBacklogThreshold(intVal);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cập nhật ngưỡng: $intVal công việc'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Đăng xuất',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?',
            style: GoogleFonts.plusJakartaSans(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.priorityUrgent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).signOut();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final isDark = ref.watch(themeModeProvider);

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: textColor,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Cài đặt',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Account Card
            _buildProfileCard(user, cardBg, borderColor, textColor, subtextColor, isDark),

            const SizedBox(height: 20),

            // 2. Appearance Section (Dark mode toggle & Backlog threshold)
            _buildSectionHeader('GIAO DIỆN & HIỂN THỊ', subtextColor),
            const SizedBox(height: 8),
            _buildAppearanceCard(cardBg, borderColor, textColor, subtextColor, isDark),

            const SizedBox(height: 20),

            // 3. Notification Settings Card
            _buildSectionHeader('THÔNG BÁO', subtextColor),
            const SizedBox(height: 8),
            _buildNotificationCard(cardBg, borderColor, textColor, subtextColor, isDark),

            const SizedBox(height: 20),

            // 4. Data Management
            _buildSectionHeader('DỮ LIỆU', subtextColor),
            const SizedBox(height: 8),
            _buildDataCard(cardBg, borderColor, textColor, subtextColor, isDark),

            const SizedBox(height: 32),

            // 5. Sign Out Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _handleSignOut,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  foregroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Đăng xuất tài khoản'),
              ),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color subtextColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: subtextColor,
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    dynamic user,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
            ),
            child: ClipOval(
              child: user?.avatarUrl != null
                  ? Image.network(
                      user!.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(LucideIcons.user, size: 24, color: subtextColor),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Người dùng',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? 'Chưa liên kết email',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: subtextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceCard(
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    final currentThreshold = _sliderValue.round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dark Mode Toggle Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Giao diện tối (Dark Mode)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Switch.adaptive(
                value: isDark,
                onChanged: (val) {
                  ref.read(themeModeProvider.notifier).setTheme(val);
                },
              ),
            ],
          ),

          Divider(height: 24, color: borderColor),

          // Backlog Threshold Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ngưỡng công việc',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'Đổi màu thích ứng khi việc dồn ứ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
              Text(
                '$currentThreshold việc',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Theme.of(context).primaryColor,
              thumbColor: Theme.of(context).primaryColor,
              overlayColor: Theme.of(context).primaryColor.withAlpha(30),
            ),
            child: Slider(
              value: _sliderValue,
              min: 3,
              max: 25,
              divisions: 22,
              onChanged: _onSliderChanged,
              onChangeEnd: _saveThreshold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Cảnh báo quá tải công việc',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            subtitle: Text(
              'Nhận thông báo khi số lượng việc vượt ngưỡng',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: subtextColor,
              ),
            ),
            value: _notifyOverload,
            onChanged: (val) {
              setState(() => _notifyOverload = val);
              ref
                  .read(authProvider.notifier)
                  .updateNotificationPreferences(notifyOnOverload: val);
            },
          ),
          Divider(height: 16, color: borderColor),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Nhắc nhở hạn chót',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            subtitle: Text(
              'Thông báo trước 24 giờ kể cả khi không có mạng',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: subtextColor,
              ),
            ),
            value: _notifyDeadline,
            onChanged: (val) {
              setState(() => _notifyDeadline = val);
              ref
                  .read(authProvider.notifier)
                  .updateNotificationPreferences(notifyOnDeadline: val);
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                await NotificationService.showTestNotification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã gửi thông báo kiểm tra hệ thống.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(LucideIcons.bell, size: 14),
              label: const Text('Kiểm tra quyền thông báo'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lưu trữ cục bộ (Offline)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Dữ liệu công việc được đồng bộ tự động vào bộ nhớ máy.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: subtextColor,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              ref.read(coreTasksProvider.notifier).resetToMock();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã khôi phục dữ liệu ban đầu.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Đặt lại dữ liệu ban đầu'),
          ),
        ],
      ),
    );
  }
}
