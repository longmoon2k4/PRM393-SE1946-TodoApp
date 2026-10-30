import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statisticsProvider);
    final adaptive = ref.watch(adaptiveStateProvider);
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context, user, adaptive, auth.isOffline),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Theme.of(context).primaryColor,
        child: _isLoading
            ? _buildSkeletonLoading()
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Offline banner if disconnected
                    if (auth.isOffline) _buildOfflineBanner(),

                    // 1. Adaptive Mode & Workload Card
                    _buildWorkloadCard(context, adaptive),

                    const SizedBox(height: 20),

                    // 2. Metric Overview Grid (Done, In Progress, Todo, Overdue)
                    _buildMetricsGrid(context, stats),

                    const SizedBox(height: 24),

                    // 3. Task Distribution Donut Chart
                    _buildDistributionCard(context, stats),

                    const SizedBox(height: 20),

                    // 4. Weekly Productivity Velocity Bar Chart
                    _buildWeeklyVelocityCard(context, stats),

                    const SizedBox(height: 20),

                    // 5. Priority Distribution Breakdown
                    _buildPriorityBreakdownCard(context, stats),

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
  ) {
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).primaryColor.withAlpha(120),
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
                    : const Icon(LucideIcons.user, size: 24),
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
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  user?.name ?? 'Người dùng',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
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
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _getModeColor(adaptive.mode).withAlpha(30),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getModeColor(adaptive.mode).withAlpha(100),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getModeIcon(adaptive.mode),
                size: 14,
                color: _getModeColor(adaptive.mode),
              ),
              const SizedBox(width: 4),
              Text(
                adaptive.modeName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _getModeColor(adaptive.mode),
                ),
              ),
            ],
          ),
        ),
        // Settings Button
        IconButton(
          icon: const Icon(LucideIcons.settings, color: Color(0xFF334155)),
          onPressed: () => context.push('/profile'),
          tooltip: 'Cài đặt hồ sơ & Ngưỡng',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B82F6).withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.wifiOff, size: 16, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Chế độ ngoại tuyến: Dữ liệu đã lưu trong bộ nhớ máy.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E40AF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkloadCard(BuildContext context, AdaptiveState adaptive) {
    final modeColor = _getModeColor(adaptive.mode);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: modeColor.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: modeColor.withAlpha(60), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: modeColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getModeIcon(adaptive.mode),
                        color: modeColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tải công việc (Adaptive UI)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${adaptive.activeTaskCount} / ${adaptive.backlogThreshold} công việc đang chạy',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: modeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(adaptive.loadPercentage * 100).round()}%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: adaptive.loadPercentage.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(modeColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            adaptive.modeDescription,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              height: 1.4,
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildMetricsGrid(BuildContext context, TaskStatistics stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildMetricTile(
              width: cardWidth,
              icon: LucideIcons.circleCheck,
              title: 'Hoàn thành',
              value: '${stats.doneCount}',
              subtitle:
                  '${(stats.completionRate * 100).round()}% tổng tiến độ',
              color: AppColors.statusDone,
            ),
            _buildMetricTile(
              width: cardWidth,
              icon: LucideIcons.timer,
              title: 'Đang làm',
              value: '${stats.inProgressCount}',
              subtitle: 'Đang xử lý',
              color: AppColors.statusInProgress,
            ),
            _buildMetricTile(
              width: cardWidth,
              icon: LucideIcons.listTodo,
              title: 'Cần làm',
              value: '${stats.todoCount}',
              subtitle: 'Đang chờ',
              color: AppColors.statusTodo,
            ),
            _buildMetricTile(
              width: cardWidth,
              icon: LucideIcons.alarmClockOff,
              title: 'Quá hạn',
              value: '${stats.overdueCount}',
              subtitle: 'Cần ưu tiên',
              color: AppColors.priorityUrgent,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile({
    required double width,
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                  color: const Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionCard(BuildContext context, TaskStatistics stats) {
    if (stats.totalTasks == 0) {
      return _buildEmptyTaskCard();
    }

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Phân bổ Trạng thái Công việc',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Icon(LucideIcons.pieChart,
                  size: 20, color: Theme.of(context).primaryColor),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
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
                          sectionsSpace: 3,
                          centerSpaceRadius: 42,
                          sections: _getPieSections(stats),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(stats.completionRate * 100).round()}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Tiến độ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
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
                      _buildLegendItem('Xong', stats.doneCount,
                          AppColors.statusDone),
                      const SizedBox(height: 8),
                      _buildLegendItem('Đang làm', stats.inProgressCount,
                          AppColors.statusInProgress),
                      const SizedBox(height: 8),
                      _buildLegendItem('Cần làm', stats.todoCount,
                          AppColors.statusTodo),
                      const SizedBox(height: 8),
                      _buildLegendItem('Quá hạn', stats.overdueCount,
                          AppColors.priorityUrgent),
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
        radius: isDoneTouched ? 28 : 22,
      ),
      PieChartSectionData(
        color: AppColors.statusInProgress,
        value: inProgressVal == 0 ? 0.001 : inProgressVal,
        title: '',
        radius: isInProgressTouched ? 28 : 22,
      ),
      PieChartSectionData(
        color: AppColors.statusTodo,
        value: todoVal == 0 ? 0.001 : todoVal,
        title: '',
        radius: isTodoTouched ? 28 : 22,
      ),
      PieChartSectionData(
        color: AppColors.priorityUrgent,
        value: overdueVal == 0 ? 0.001 : overdueVal,
        title: '',
        radius: isOverdueTouched ? 28 : 22,
      ),
    ];
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF475569),
            ),
          ),
        ),
        Text(
          '$count',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyVelocityCard(
      BuildContext context, TaskStatistics stats) {
    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tốc độ Hoàn thành Tuần này',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Icon(LucideIcons.barChart2,
                  size: 20, color: Theme.of(context).primaryColor),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
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
                      reservedSize: 22,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}',
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF94A3B8)),
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
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B)),
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
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: Color(0xFFF1F5F9),
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
                        toY: val == 0 ? 0.3 : val,
                        color: val > 0
                            ? Theme.of(context).primaryColor
                            : const Color(0xFFE2E8F0),
                        width: 14,
                        borderRadius: BorderRadius.circular(6),
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
      BuildContext context, TaskStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân loại theo Mức độ Ưu tiên',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildPriorityRow('Khẩn cấp (Urgent)', stats.urgentCount,
              stats.totalTasks, AppColors.priorityUrgent),
          const SizedBox(height: 12),
          _buildPriorityRow('Cao (High)', stats.highCount, stats.totalTasks,
              AppColors.priorityHigh),
          const SizedBox(height: 12),
          _buildPriorityRow('Trung bình (Medium)', stats.mediumCount,
              stats.totalTasks, AppColors.priorityMedium),
          const SizedBox(height: 12),
          _buildPriorityRow('Thấp (Low)', stats.lowCount, stats.totalTasks,
              AppColors.priorityLow),
        ],
      ),
    );
  }

  Widget _buildPriorityRow(
      String label, int count, int total, Color color) {
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
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
            Text(
              '$count việc (${(percent * 100).round()}%)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearPercentIndicator(
          lineHeight: 8.0,
          percent: percent,
          progressColor: color,
          backgroundColor: const Color(0xFFF1F5F9),
          barRadius: const Radius.circular(4),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildEmptyTaskCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/empty_tasks.png',
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, stack) => const Icon(
              LucideIcons.inbox,
              size: 64,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có công việc nào!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bắt đầu tạo nhiệm vụ mới trên bảng Kanban hoặc nạp dữ liệu mẫu.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskBoardShortcut(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.push('/board'),
        icon: const Icon(LucideIcons.kanbanSquare, size: 18),
        label: const Text('Xem Bảng Công việc (Task Board)'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    ).animate().shimmer(duration: 1000.ms);
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

  IconData _getModeIcon(AdaptiveMode mode) {
    switch (mode) {
      case AdaptiveMode.calm:
        return LucideIcons.leaf;
      case AdaptiveMode.focus:
        return LucideIcons.flame;
      case AdaptiveMode.overload:
        return LucideIcons.triangleAlert;
    }
  }
}
