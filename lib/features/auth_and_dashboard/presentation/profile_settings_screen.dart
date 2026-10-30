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
          content: Text('Đã cập nhật ngưỡng công việc: $intVal nhiệm vụ'),
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
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Xác nhận đăng xuất?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản Google hiện tại?',
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
    final adaptive = ref.watch(adaptiveStateProvider);
    final tasks = ref.watch(coreTasksProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Hồ sơ & Cài đặt',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. User Profile Header Card
            _buildProfileCard(user),

            const SizedBox(height: 24),

            // 2. Adaptive Backlog Threshold Configurator
            _buildThresholdConfigCard(adaptive),

            const SizedBox(height: 24),

            // 3. Notification Settings Card
            _buildNotificationCard(),

            const SizedBox(height: 24),

            // 4. Offline Storage & Mock Data Management
            _buildStorageCard(tasks.length),

            const SizedBox(height: 32),

            // 5. Sign Out Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _handleSignOut,
                icon: const Icon(LucideIcons.logOut,
                    size: 18, color: Color(0xFFEF4444)),
                label: Text(
                  'Đăng xuất tài khoản',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF4444),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(dynamic user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 2.5,
              ),
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
                  : const Icon(LucideIcons.user, size: 32),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Người dùng',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'Chưa kết nối email',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.shieldCheck,
                          size: 13, color: Color(0xFF2563EB)),
                      const SizedBox(width: 6),
                      Text(
                        'Google OAuth 2.0',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdConfigCard(AdaptiveState adaptive) {
    final currentThreshold = _sliderValue.round();
    final focusStart = (currentThreshold * 0.6).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.sliders,
                    size: 20, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ngưỡng Công việc Tồn đọng',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Kích hoạt cơ chế tự động chuyển đổi Theme',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '$currentThreshold việc',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Theme.of(context).primaryColor,
              thumbColor: Theme.of(context).primaryColor,
              overlayColor: Theme.of(context).primaryColor.withAlpha(40),
            ),
            child: Slider(
              value: _sliderValue,
              min: 3,
              max: 25,
              divisions: 22,
              label: '$currentThreshold',
              onChanged: _onSliderChanged,
              onChangeEnd: _saveThreshold,
            ),
          ),
          const SizedBox(height: 12),
          // Adaptive Mode Indicator description
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _buildModeThresholdRow('Calm Mode (Dịu mát)',
                    'Dưới $focusStart nhiệm vụ', AppColors.calmPrimary),
                const Divider(height: 16, color: Color(0xFFE2E8F0)),
                _buildModeThresholdRow(
                    'Focus Mode (Tập trung)',
                    'Từ $focusStart đến $currentThreshold nhiệm vụ',
                    AppColors.focusPrimary),
                const Divider(height: 16, color: Color(0xFFE2E8F0)),
                _buildModeThresholdRow(
                    'Overload Mode (Quá tải)',
                    'Trên $currentThreshold nhiệm vụ',
                    AppColors.overloadPrimary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeThresholdRow(String name, String range, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
          ],
        ),
        Text(
          range,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.bellRing,
                    size: 20, color: Color(0xFFD97706)),
              ),
              const SizedBox(width: 12),
              Text(
                'Thông báo Ngoại tuyến (Offline Alerts)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Cảnh báo khi bị Quá tải (Overload)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Tự động thông báo khi số lượng task vượt ngưỡng đã đặt',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF64748B),
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
          const Divider(height: 16, color: Color(0xFFE2E8F0)),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Nhắc nhở Hạn chót (Deadline)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Bắn thông báo trước 24 giờ kể cả khi không có kết nối mạng',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF64748B),
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
          const SizedBox(height: 16),
          // Test Notification Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await NotificationService.showTestNotification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã gửi thông báo thử nghiệm! Hãy kiểm tra thanh thông báo thiết bị.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(LucideIcons.bellPlus, size: 16),
              label: const Text('Bắn thử Thông báo Cục bộ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: const Color(0xFF1E293B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard(int taskCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.database,
                    size: 20, color: Color(0xFF059669)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bộ nhớ Ngoại tuyến (SharedPreferences)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'Đang lưu trữ an toàn $taskCount công việc trên máy',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(coreTasksProvider.notifier).resetToMock();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã khôi phục dữ liệu mẫu và cập nhật bộ nhớ đệm.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(LucideIcons.rotateCcw, size: 16),
              label: const Text('Khôi phục Dữ liệu mẫu (Reset Mock Data)'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
