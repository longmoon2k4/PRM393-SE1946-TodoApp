import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
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
    final isOverload = adaptive.mode == AdaptiveMode.overload;
    final isFocus = adaptive.mode == AdaptiveMode.focus;

    final cardBg = Theme.of(context).cardColor;
    final borderColor = isDark
        ? (isOverload
            ? const Color(0xFF9F1239)
            : (isFocus ? const Color(0xFF78350F) : const Color(0xFF334155)))
        : (isOverload
            ? const Color(0xFFFECDD3)
            : (isFocus ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)));
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
            IconsaxPlusLinear.arrow_left,
            color: textColor,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Hồ sơ & Cài đặt',
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
            _buildProfileHeroCard(
              user,
              stats,
              cardBg,
              borderColor,
              textColor,
              subtextColor,
              isDark,
              adaptive,
            ),

            const SizedBox(height: 22),

            _buildSectionHeader('GIAO DIỆN THÍCH ỨNG & NGƯỠNG TẢI', subtextColor),
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

            _buildSectionHeader('GIAO DIỆN & MÀU SẮC', subtextColor),
            const SizedBox(height: 8),
            _buildAppearanceCard(
              cardBg,
              borderColor,
              textColor,
              subtextColor,
              isDark,
              adaptive,
            ),

            const SizedBox(height: 22),

            _buildSectionHeader('CÀI ĐẶT THÔNG BÁO', subtextColor),
            const SizedBox(height: 8),
            _buildNotificationCard(
              cardBg,
              borderColor,
              textColor,
              subtextColor,
              isDark,
              adaptive,
            ),

            const SizedBox(height: 22),

            _buildSectionHeader('ĐỒNG BỘ & DỮ LIỆU', subtextColor),
            const SizedBox(height: 8),
            _buildDataAndSyncCard(
              auth.isOffline,
              stats.totalTasks,
              cardBg,
              borderColor,
              textColor,
              subtextColor,
              isDark,
              adaptive,
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _handleSignOut,
                icon: const Icon(IconsaxPlusLinear.logout_1, size: 16, color: Color(0xFFEF4444)),
                label: Text(
                  'Đăng xuất tài khoản',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEF4444),
                    letterSpacing: 0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444).withAlpha(isDark ? 30 : 16),
                  foregroundColor: const Color(0xFFEF4444),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: const Color(0xFFEF4444).withAlpha(isDark ? 90 : 60),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Center(
              child: Text(
                'Smart Workflow & Todo App • Phiên bản 2.4.0',
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

  BoxDecoration _enterpriseCardDecoration({
    required Color cardBg,
    required bool isDark,
    double radius = 20,
    Color? customBorderColor,
    AdaptiveMode? mode,
  }) {
    final effectiveBorder = customBorderColor ??
        (mode == AdaptiveMode.overload
            ? (isDark ? const Color(0xFF9F1239) : const Color(0xFFFECDD3))
            : (mode == AdaptiveMode.focus
                ? (isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A))
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))));

    final shadowTint = mode == AdaptiveMode.overload
        ? const Color(0xFFE11D48)
        : (mode == AdaptiveMode.focus
            ? const Color(0xFFD97706)
            : const Color(0xFF0F172A));

    return BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: effectiveBorder,
        width: mode == AdaptiveMode.overload ? 1.5 : 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: shadowTint.withAlpha(isDark
              ? (mode == AdaptiveMode.overload ? 60 : 35)
              : (mode == AdaptiveMode.overload ? 25 : 12)),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: shadowTint.withAlpha(isDark ? 30 : 6),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
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

  Widget _buildProfileHeroCard(
    dynamic user,
    TaskStatistics stats,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
    AdaptiveState adaptive,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _enterpriseCardDecoration(
        cardBg: cardBg,
        isDark: isDark,
        radius: 20,
        mode: adaptive.mode,
      ),
      child: Column(
        children: [
          Row(
            children: [
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
                        width: 2.2,
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
                          : Icon(IconsaxPlusLinear.user, size: 30, color: subtextColor),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3.5),
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
                    Text(
                      user?.name ?? 'Hà Vũ Long',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user?.email ?? 'long@fpt.edu.vn',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: subtextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Tài khoản Google • Đã liên kết',
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

          Row(
            children: [
              Expanded(
                child: _buildProfileStatColumn(
                  'Tổng việc',
                  '${stats.totalTasks}',
                  textColor,
                  subtextColor,
                ),
              ),
              Container(width: 1, height: 28, color: borderColor),
              Expanded(
                child: _buildProfileStatColumn(
                  'Đã xong',
                  '${stats.doneCount}',
                  textColor,
                  subtextColor,
                ),
              ),
              Container(width: 1, height: 28, color: borderColor),
              Expanded(
                child: _buildProfileStatColumn(
                  'Điểm năng suất',
                  '${stats.productivityScore}đ',
                  const Color(0xFF10B981),
                  subtextColor,
                ),
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
      decoration: _enterpriseCardDecoration(
        cardBg: cardBg,
        isDark: isDark,
        radius: 20,
        mode: adaptive.mode,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ngưỡng công việc tối đa',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tự động kích hoạt chế độ tập trung & cảnh báo khi vượt ngưỡng',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

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

          Text(
            'Trạng thái giao diện theo khối lượng việc:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              _buildSimPreviewCard(
                title: 'Calm',
                range: '1 - $calmLimit',
                desc: 'Bình thường',
                color: AppColors.calmPrimary,
                isCurrent: adaptive.activeTaskCount <= calmLimit,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildSimPreviewCard(
                title: 'Focus',
                range: '${calmLimit + 1} - $currentThreshold',
                desc: 'Tập trung',
                color: AppColors.focusPrimary,
                isCurrent: adaptive.activeTaskCount > calmLimit && adaptive.activeTaskCount <= currentThreshold,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildSimPreviewCard(
                title: 'Overload',
                range: '> $currentThreshold',
                desc: 'Quá tải',
                color: AppColors.overloadPrimary,
                isCurrent: adaptive.activeTaskCount > currentThreshold,
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
    required bool isCurrent,
    required bool isDark,
  }) {
    final bgColor = isCurrent
        ? color.withAlpha(isDark ? 40 : 20)
        : (isDark ? const Color(0xFF0F172A).withAlpha(50) : const Color(0xFFF8FAFC));
    final cardBorder = isCurrent
        ? color
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cardBorder,
            width: isCurrent ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$range việc',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (isCurrent) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'HIỆN TẠI',
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
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

  Widget _buildAppearanceCard(
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
    AdaptiveState adaptive,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _enterpriseCardDecoration(
        cardBg: cardBg,
        isDark: isDark,
        radius: 20,
        mode: adaptive.mode,
      ),
      child: Row(
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
              isDark ? IconsaxPlusLinear.moon : IconsaxPlusLinear.sun_1,
              size: 18,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giao diện tối (Dark Mode)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                Text(
                  isDark ? 'Đang bật nền Slate 900' : 'Đang bật nền Sáng dịu',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: subtextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: isDark,
            onChanged: (val) {
              ref.read(themeModeProvider.notifier).setTheme(val);
            },
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
    AdaptiveState adaptive,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _enterpriseCardDecoration(
        cardBg: cardBg,
        isDark: isDark,
        radius: 20,
        mode: adaptive.mode,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  IconsaxPlusLinear.notification_bing,
                  size: 18,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cảnh báo quá tải',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Thông báo khi công việc vượt ngưỡng',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: _notifyOverload,
                onChanged: (val) {
                  setState(() => _notifyOverload = val);
                  ref
                      .read(authProvider.notifier)
                      .updateNotificationPreferences(notifyOnOverload: val);
                  if (!val) {
                    NotificationService.cancelOverloadAlert();
                  }
                },
              ),
            ],
          ),
          Divider(height: 24, color: borderColor),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  IconsaxPlusLinear.calendar_tick,
                  size: 18,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nhắc nhở hạn chót',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Thông báo trước 24 giờ đến hạn',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: _notifyDeadline,
                onChanged: (val) {
                  setState(() => _notifyDeadline = val);
                  ref
                      .read(authProvider.notifier)
                      .updateNotificationPreferences(notifyOnDeadline: val);
                  if (!val) {
                    NotificationService.cancelDeadlineAlert();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataAndSyncCard(
    bool isOffline,
    int totalTasks,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
    AdaptiveState adaptive,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _enterpriseCardDecoration(
        cardBg: cardBg,
        isDark: isDark,
        radius: 20,
        mode: adaptive.mode,
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
                  IconsaxPlusLinear.cloud_connection,
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
                      'Đồng bộ đám mây',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalTasks công việc đã được lưu trữ',
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
                  isOffline ? 'Ngoại tuyến' : 'Đã kết nối',
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
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                final success = await ref.read(coreTasksProvider.notifier).syncFromBackend();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Đã đồng bộ dữ liệu mới nhất thành công!'
                          : 'Không thể kết nối máy chủ. Đang lưu trên thiết bị.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(IconsaxPlusLinear.refresh, size: 15, color: Color(0xFF2563EB)),
              label: Text(
                'Đồng bộ dữ liệu ngay',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2563EB),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6).withAlpha(isDark ? 35 : 16),
                foregroundColor: const Color(0xFF2563EB),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: const Color(0xFF3B82F6).withAlpha(isDark ? 80 : 50),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
