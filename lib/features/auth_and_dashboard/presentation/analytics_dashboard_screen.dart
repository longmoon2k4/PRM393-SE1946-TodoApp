import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../../core/theme/adaptive_theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/statistics_provider.dart';

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState
    extends ConsumerState<AnalyticsDashboardScreen> {
  int _touchedPieIndex = -1;
  bool _isLoading = false;

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statisticsProvider);
    final adaptive = ref.watch(adaptiveStateProvider);
    final isDark = adaptive.isDark;
    final auth = ref.watch(authProvider);
    final user = auth.user;

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context, user, adaptive, auth.isOffline, isDark),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Theme.of(context).primaryColor,
        child: _isLoading
            ? _buildSkeletonLoading(isDark)
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 8,
                  bottom: 36,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Offline banner if disconnected
                    if (auth.isOffline) _buildOfflineBanner(isDark),

                    // 1. Workload Status Card
                    _buildWorkloadCard(
                      context,
                      adaptive,
                      cardBg,
                      borderColor,
                      textColor,
                      subtextColor,
                    ),

                    const SizedBox(height: 16),

                    // 2. Metric Overview Grid (Done, In Progress, Todo, Overdue)
                    _buildMetricsGrid(
                      context,
                      stats,
                      cardBg,
                      borderColor,
                      textColor,
                      subtextColor,
                    ),

                    const SizedBox(height: 16),

                    // 3. Task Distribution Donut Chart
                    _buildDistributionCard(
                      context,
                      stats,
                      cardBg,
                      borderColor,
                      textColor,
                      subtextColor,
                    ),

                    const SizedBox(height: 16),

                    // 4. Weekly Productivity Velocity Bar Chart
                    _buildWeeklyVelocityCard(
                      context,
                      stats,
                      cardBg,
                      borderColor,
                      textColor,
                      subtextColor,
                      isDark,
                    ),

                    const SizedBox(height: 16),

                    // 5. Priority Distribution Breakdown
                    _buildPriorityBreakdownCard(
                      context,
                      stats,
                      cardBg,
                      borderColor,
                      textColor,
                      subtextColor,
                      isDark,
                    ),

                    const SizedBox(height: 24),

                    // Navigation CTA to Task Board
                    _buildTaskBoardShortcut(context),
                  ],
                ),
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    dynamic user,
    AdaptiveState adaptive,
    bool isOffline,
    bool isDark,
  ) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 20,
      title: Row(
        children: [
          // User Avatar with fallback
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFCBD5E1),
                  width: 1.5,
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
                    : Icon(
                        LucideIcons.user,
                        size: 20,
                        color: isDark ? Colors.white : const Color(0xFF334155),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Xin chào,',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: subtextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  user?.name ?? 'Người dùng',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Mode indicator pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _getModeColor(adaptive.mode).withAlpha(isDark ? 35 : 20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getModeColor(adaptive.mode).withAlpha(isDark ? 80 : 60),
            ),
          ),
          child: Text(
            adaptive.modeName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _getModeColor(adaptive.mode),
            ),
          ),
        ),
        const SizedBox(width: 4),
        // Dark/Light Mode Switcher
        IconButton(
          icon: Icon(
            isDark ? LucideIcons.sun : LucideIcons.moon,
            size: 20,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF475569),
          ),
          onPressed: () {
            ref.read(themeModeProvider.notifier).toggleTheme();
          },
          tooltip: isDark ? 'Chuyển sang giao diện Sáng' : 'Chuyển sang giao diện Tối',
        ),
        // Settings Button
        IconButton(
          icon: Icon(
            LucideIcons.settings,
            size: 20,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF475569),
          ),
          onPressed: () => context.push('/profile'),
          tooltip: 'Cài đặt hồ sơ',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildOfflineBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E3A8A).withAlpha(40)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3B82F6).withAlpha(60)
              : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.wifiOff, size: 15, color: Color(0xFF3B82F6)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Chế độ ngoại tuyến: Dữ liệu đã lưu cục bộ.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFF1E40AF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkloadCard(
    BuildContext context,
    AdaptiveState adaptive,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
  ) {
    final modeColor = _getModeColor(adaptive.mode);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tải công việc hiện tại',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              Text(
                '${adaptive.activeTaskCount} / ${adaptive.backlogThreshold} việc',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: modeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: adaptive.loadPercentage.clamp(0.0, 1.0),
              backgroundColor: borderColor.withAlpha(50),
              valueColor: AlwaysStoppedAnimation<Color>(modeColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            adaptive.modeDescription,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(
    BuildContext context,
    TaskStatistics stats,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildMetricTile(
              width: cardWidth,
              title: 'Hoàn thành',
              value: '${stats.doneCount}',
              subtitle: '${(stats.completionRate * 100).round()}% tổng số',
              color: AppColors.statusDone,
              cardBg: cardBg,
              borderColor: borderColor,
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            _buildMetricTile(
              width: cardWidth,
              title: 'Đang thực hiện',
              value: '${stats.inProgressCount}',
              subtitle: 'Đang xử lý',
              color: AppColors.statusInProgress,
              cardBg: cardBg,
              borderColor: borderColor,
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            _buildMetricTile(
              width: cardWidth,
              title: 'Cần làm',
              value: '${stats.todoCount}',
              subtitle: 'Đang chờ xử lý',
              color: const Color(0xFF64748B),
              cardBg: cardBg,
              borderColor: borderColor,
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            _buildMetricTile(
              width: cardWidth,
              title: 'Quá hạn',
              value: '${stats.overdueCount}',
              subtitle: 'Cần xử lý gấp',
              color: AppColors.priorityUrgent,
              cardBg: cardBg,
              borderColor: borderColor,
              textColor: textColor,
              subtextColor: subtextColor,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: subtextColor,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionCard(
    BuildContext context,
    TaskStatistics stats,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
  ) {
    if (stats.totalTasks == 0) {
      return _buildEmptyTaskCard(cardBg, borderColor, textColor, subtextColor);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân bổ trạng thái',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedPieIndex = -1;
                                  return;
                                }
                                _touchedPieIndex = pieTouchResponse
                                    .touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: _getPieSections(stats),
                        ),
                      ),
                      Text(
                        '${(stats.completionRate * 100).round()}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(
                          'Xong', stats.doneCount, AppColors.statusDone, textColor, subtextColor),
                      const SizedBox(height: 6),
                      _buildLegendItem('Đang làm', stats.inProgressCount,
                          AppColors.statusInProgress, textColor, subtextColor),
                      const SizedBox(height: 6),
                      _buildLegendItem('Cần làm', stats.todoCount,
                          const Color(0xFF64748B), textColor, subtextColor),
                      const SizedBox(height: 6),
                      _buildLegendItem('Quá hạn', stats.overdueCount,
                          AppColors.priorityUrgent, textColor, subtextColor),
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

  List<PieChartSectionData> _getPieSections(TaskStatistics stats) {
    final isDoneTouched = _touchedPieIndex == 0;
    final isInProgressTouched = _touchedPieIndex == 1;
    final isTodoTouched = _touchedPieIndex == 2;
    final isOverdueTouched = _touchedPieIndex == 3;

    final doneVal = stats.doneCount.toDouble();
    final inProgressVal = stats.inProgressCount.toDouble();
    final todoVal = stats.todoCount.toDouble();
    final overdueVal = stats.overdueCount.toDouble();

    return [
      PieChartSectionData(
        color: AppColors.statusDone,
        value: doneVal == 0 ? 0.001 : doneVal,
        title: '',
        radius: isDoneTouched ? 26 : 20,
      ),
      PieChartSectionData(
        color: AppColors.statusInProgress,
        value: inProgressVal == 0 ? 0.001 : inProgressVal,
        title: '',
        radius: isInProgressTouched ? 26 : 20,
      ),
      PieChartSectionData(
        color: const Color(0xFF64748B),
        value: todoVal == 0 ? 0.001 : todoVal,
        title: '',
        radius: isTodoTouched ? 26 : 20,
      ),
      PieChartSectionData(
        color: AppColors.priorityUrgent,
        value: overdueVal == 0 ? 0.001 : overdueVal,
        title: '',
        radius: isOverdueTouched ? 26 : 20,
      ),
    ];
  }

  Widget _buildLegendItem(
    String label,
    int count,
    Color color,
    Color textColor,
    Color subtextColor,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: subtextColor,
            ),
          ),
        ),
        Text(
          '$count',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyVelocityCard(
    BuildContext context,
    TaskStatistics stats,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hiệu suất theo tuần',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 8,
                barTouchData: const BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}',
                        style: TextStyle(fontSize: 10, color: subtextColor),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final index = val.toInt();
                        if (index >= 0 && index < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              days[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: subtextColor,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? const Color(0xFF334155).withAlpha(60)
                        : const Color(0xFFF1F5F9),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  final val = stats.weeklyCompletedCounts[i].toDouble();
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: val == 0 ? 0.2 : val,
                        color: val > 0
                            ? Theme.of(context).primaryColor
                            : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0)),
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBreakdownCard(
    BuildContext context,
    TaskStatistics stats,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mức độ ưu tiên',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 14),
          _buildPriorityRow('Khẩn cấp', stats.urgentCount, stats.totalTasks,
              AppColors.priorityUrgent, textColor, subtextColor, isDark),
          const SizedBox(height: 10),
          _buildPriorityRow('Cao', stats.highCount, stats.totalTasks,
              AppColors.priorityHigh, textColor, subtextColor, isDark),
          const SizedBox(height: 10),
          _buildPriorityRow('Trung bình', stats.mediumCount, stats.totalTasks,
              AppColors.priorityMedium, textColor, subtextColor, isDark),
          const SizedBox(height: 10),
          _buildPriorityRow('Thấp', stats.lowCount, stats.totalTasks,
              AppColors.priorityLow, textColor, subtextColor, isDark),
        ],
      ),
    );
  }

  Widget _buildPriorityRow(
    String label,
    int count,
    int total,
    Color color,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    final percent = total == 0 ? 0.0 : (count / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            Text(
              '$count (${(percent * 100).round()}%)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearPercentIndicator(
          lineHeight: 6.0,
          percent: percent,
          progressColor: color,
          backgroundColor: isDark
              ? const Color(0xFF334155)
              : const Color(0xFFF1F5F9),
          barRadius: const Radius.circular(3),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildEmptyTaskCard(
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/empty_tasks.png',
            height: 100,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, stack) => Icon(
              LucideIcons.inbox,
              size: 48,
              color: subtextColor,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Không có công việc nào',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hiện tại không có dữ liệu công việc để thống kê.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskBoardShortcut(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => context.push('/board'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Xem bảng công việc'),
      ),
    );
  }

  Widget _buildSkeletonLoading(bool isDark) {
    final shimmerColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getModeColor(AdaptiveMode mode) {
    switch (mode) {
      case AdaptiveMode.calm:
        return AppColors.calmPrimary;
      case AdaptiveMode.focus:
        return AppColors.focusPrimary;
      case AdaptiveMode.overload:
        return AppColors.overloadPrimary;
    }
  }
}
