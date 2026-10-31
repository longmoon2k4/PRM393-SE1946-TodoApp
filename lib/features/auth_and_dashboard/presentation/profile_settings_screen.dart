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
import '../providers/statistics_provider.dart';

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
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Đăng xuất tài khoản',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn đăng xuất? Dữ liệu ngoại tuyến trên máy vẫn sẽ được bảo toàn.',
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
    final stats = ref.watch(statisticsProvider);
    final adaptive = ref.watch(adaptiveStateProvider);
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
          'Hồ sơ & Cài đặt hệ thống',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
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
            // 1. Hero Profile & User Stats Card
            _buildProfileHeroCard(
              user,
              stats,
              cardBg,
              borderColor,
              textColor,
              subtextColor,
              isDark,
            ),

            const SizedBox(height: 22),

            // 2. Interactive Adaptive UI Simulation Studio
            _buildSectionHeader('BỘ NÃO ADAPTIVE UI (ENGINE GIAO DIỆN THÍCH ỨNG)', subtextColor),
            const SizedBox(height: 8),
            _buildAdaptiveStudioCard(
              cardBg,
              borderColor,
              textColor,
              subtextColor,
              isDark,
              adaptive,
            ),

            const SizedBox(height: 22),

            // 3. Appearance Card (Dark mode toggle)
            _buildSectionHeader('GIAO DIỆN & MÀU SẮC', subtextColor),
            const SizedBox(height: 8),
            _buildAppearanceCard(
              cardBg,
              borderColor,
              textColor,
              subtextColor,
              isDark,
            ),

            const SizedBox(height: 22),

            // 4. Notification Settings Card
            _buildSectionHeader('THÔNG BÁO THÔNG MINH (NOTIFICATIONS)', subtextColor),
            const SizedBox(height: 8),
            _buildNotificationCard(
              cardBg,
              borderColor,
              textColor,
              subtextColor,
              isDark,
            ),

            const SizedBox(height: 22),

            // 5. System, Cloud Sync & Data Management
            _buildSectionHeader('KẾT NỐI HỆ THỐNG & DỮ LIỆU', subtextColor),
            const SizedBox(height: 8),
            _buildDataAndSyncCard(
              auth.isOffline,
              stats.totalTasks,
              cardBg,
              borderColor,
              textColor,
              subtextColor,
              isDark,
            ),

            const SizedBox(height: 32),

            // 6. Sign Out Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _handleSignOut,
                icon: const Icon(LucideIcons.logOut, size: 16),
                label: const Text('Đăng xuất tài khoản'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  foregroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // App Version & Credits
            Center(
              child: Text(
                'Smart Workflow & Adaptive Todo App • v2.4.0 (PRM393 FPT)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: subtextColor,
                ),
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
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: subtextColor,
        ),
      ),
    );
  }

  // 1. Hero Profile & User Stats Card
  Widget _buildProfileHeroCard(
    dynamic user,
    TaskStatistics stats,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 6),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with badge
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 2,
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
                          : Icon(LucideIcons.user, size: 30, color: subtextColor),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user?.name ?? 'Hà Vũ Long',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user?.email ?? 'long@fpt.edu.vn',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: subtextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Google OAuth 2.0 • Đã xác thực',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 16),

          // 3-Metric Summary Strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProfileStatColumn(
                'Tổng việc',
                '${stats.totalTasks}',
                textColor,
                subtextColor,
              ),
              Container(width: 1, height: 28, color: borderColor),
              _buildProfileStatColumn(
                'Đã xong',
                '${stats.doneCount}',
                textColor,
                subtextColor,
              ),
              Container(width: 1, height: 28, color: borderColor),
              _buildProfileStatColumn(
                'Điểm năng suất',
                '${stats.productivityScore}đ',
                const Color(0xFF10B981),
                subtextColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStatColumn(
    String label,
    String value,
    Color valueColor,
    Color subtextColor,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: subtextColor,
          ),
        ),
      ],
    );
  }

  // 2. Interactive Adaptive UI Simulation Studio
  Widget _buildAdaptiveStudioCard(
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
    AdaptiveState adaptive,
  ) {
    final currentThreshold = _sliderValue.round();
    final calmLimit = (currentThreshold * 0.6).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ngưỡng kích hoạt quá tải',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'Kéo slider để thay đổi mốc đổi màu tự động',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(isDark ? 40 : 20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  '$currentThreshold việc',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Theme.of(context).primaryColor,
              inactiveTrackColor: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
              thumbColor: Theme.of(context).primaryColor,
              overlayColor: Theme.of(context).primaryColor.withAlpha(30),
              trackHeight: 6,
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

          const SizedBox(height: 10),

          // Live Simulation Preview Cards
          Text(
            'Quy tắc chuyển màu theo ngưỡng $currentThreshold việc:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),

          // 3 Color Preview Cards
          Row(
            children: [
              _buildSimPreviewCard(
                title: 'Calm',
                range: '1 - $calmLimit',
                desc: 'Dịu mát',
                color: AppColors.calmPrimary,
                bgColor: AppColors.calmPrimary.withAlpha(isDark ? 35 : 15),
                isCurrent: adaptive.mode == AdaptiveMode.calm,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildSimPreviewCard(
                title: 'Focus',
                range: '${calmLimit + 1} - $currentThreshold',
                desc: 'Tập trung',
                color: AppColors.focusPrimary,
                bgColor: AppColors.focusPrimary.withAlpha(isDark ? 35 : 15),
                isCurrent: adaptive.mode == AdaptiveMode.focus,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildSimPreviewCard(
                title: 'Overload',
                range: '> $currentThreshold',
                desc: 'Khẩn cấp',
                color: AppColors.overloadPrimary,
                bgColor: AppColors.overloadPrimary.withAlpha(isDark ? 35 : 15),
                isCurrent: adaptive.mode == AdaptiveMode.overload,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimPreviewCard({
    required String title,
    required String range,
    required String desc,
    required Color color,
    required Color bgColor,
    required bool isCurrent,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent ? color : color.withAlpha(80),
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$range việc',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: color,
              ),
            ),
            if (isCurrent) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'HIỆN TẠI',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 3. Appearance Card (Dark mode toggle)
  Widget _buildAppearanceCard(
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFFF1F5F9).withAlpha(30)
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDark ? LucideIcons.moon : LucideIcons.sun,
                      size: 18,
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chế độ Giao diện Tối (Dark Mode)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      Text(
                        isDark ? 'Đang bật nền Slate 900' : 'Đang bật nền Sáng dịu',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch.adaptive(
                value: isDark,
                onChanged: (val) {
                  ref.read(themeModeProvider.notifier).setTheme(val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Notification Settings Card
  Widget _buildNotificationCard(
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.bellRing,
                size: 18,
                color: Color(0xFFEF4444),
              ),
            ),
            title: Text(
              'Cảnh báo quá tải công việc',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            subtitle: Text(
              'Nhận push notification khi số task chưa xong vượt ngưỡng',
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
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.calendarClock,
                size: 18,
                color: Color(0xFFF59E0B),
              ),
            ),
            title: Text(
              'Nhắc nhở hạn chót công việc',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            subtitle: Text(
              'Thông báo trước 24 giờ kể cả khi thiết bị không có mạng',
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await NotificationService.showTestNotification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã gửi thông báo kiểm tra hệ thống thành công!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(LucideIcons.send, size: 14),
              label: const Text('Bắn thông báo thử nghiệm (Test Notification)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
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

  // 5. Data & Sync Card
  Widget _buildDataAndSyncCard(
    bool isOffline,
    int totalTasks,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.database,
                  size: 18,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lưu trữ cục bộ & Đồng bộ Cloud',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Đang lưu trữ $totalTasks công việc an toàn trong bộ nhớ máy',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOffline
                      ? const Color(0xFFF59E0B).withAlpha(25)
                      : const Color(0xFF10B981).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOffline ? 'Offline' : 'Online',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isOffline
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF10B981),
                  ),
                ),
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
                    content: Text('Đã khôi phục dữ liệu ban đầu thành công.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(LucideIcons.rotateCcw, size: 14),
              label: const Text('Khôi phục dữ liệu mẫu ban đầu (Mock Data)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
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
