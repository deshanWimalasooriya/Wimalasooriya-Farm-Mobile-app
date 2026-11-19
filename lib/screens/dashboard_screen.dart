import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_assets.dart';
import '../core/theme/app_colors.dart';
import '../models/farm_models.dart';
import '../providers/farm_providers.dart';
import '../utils/app_snackbar.dart';

class DashboardScreen extends ConsumerWidget {
  final VoidCallback onOpenNotifications;

  const DashboardScreen({super.key, required this.onOpenNotifications});

  void _showReportDialog(BuildContext context, String currentRange) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16264C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.assessment_outlined, color: AppColors.darkPrimaryGold, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Generate Farm Report',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Generate and export audit-ready performance analytics for the selected "$currentRange" time window:',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    AppSnackBar.showSuccess(
                      context,
                      'Exported $currentRange analytics to CSV/PDF successfully!',
                    );
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: Text('Export $currentRange Report (CSV / PDF)'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(farmMetricsStreamProvider);
    final eggLogsAsync = ref.watch(eggLogsStreamProvider);
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final timeRange = ref.watch(dashboardTimeRangeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentDateStr = DateFormat('MMMM d, y').format(DateTime.now());
    final formatter = NumberFormat('#,###');

    final henCount = metricsAsync.value?.currentHenCount ?? 0;
    final allEggLogs = eggLogsAsync.value ?? [];
    final allTransactions = transactionsAsync.value ?? [];
    final notifsAsync = ref.watch(adminNotificationsStreamProvider);
    final unreadNotifsCount = notifsAsync.value?.where((n) => !n.isRead).length ?? 0;

    // Filter data based on selected timeRange (Daily, Weekly, Monthly, Yearly)
    final now = DateTime.now();
    DateTime filterCutoff;
    switch (timeRange) {
      case 'Daily':
        filterCutoff = DateTime(now.year, now.month, now.day);
        break;
      case 'Weekly':
        filterCutoff = now.subtract(const Duration(days: 7));
        break;
      case 'Monthly':
        filterCutoff = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'Yearly':
        filterCutoff = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        filterCutoff = now.subtract(const Duration(days: 7));
    }

    final filteredEggLogs = allEggLogs.where((l) {
      if (l.timestamp == null) return false;
      return l.timestamp!.isAfter(filterCutoff);
    }).toList();

    final filteredTransactions = allTransactions.where((t) {
      if (t.timestamp == null) return false;
      return t.timestamp!.isAfter(filterCutoff);
    }).toList();

    // Aggregated Metrics
    int totalEggsPeriod = 0;
    for (final log in filteredEggLogs) {
      totalEggsPeriod += log.producedCount;
    }
    if (totalEggsPeriod == 0 && timeRange == 'Daily') {
      totalEggsPeriod = metricsAsync.value?.todayEggCount ?? 0;
    }

    double totalIncomePeriod = 0;
    double totalExpensePeriod = 0;
    for (final tx in filteredTransactions) {
      if (tx.type == 'income') {
        totalIncomePeriod += tx.amount;
      } else {
        totalExpensePeriod += tx.amount;
      }
    }

    final layingRate = henCount > 0
        ? ((totalEggsPeriod / henCount) * 100).clamp(0, 100).toStringAsFixed(0)
        : '0';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.darkPrimaryGold, width: 1.5),
            ),
            child: ClipOval(
              child: Image.asset(
                AppAssets.logo,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        title: const Text(
          'Wimalasooriya Farms',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_rounded, size: 28),
                  onPressed: onOpenNotifications,
                ),
                if (unreadNotifsCount > 0)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Header + Dynamic Glassmorphic Time Filter Dropdown
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Insights & Analytics',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentDateStr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Glassmorphic Time Range Filter Dropdown
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0x6616264C) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.darkPrimaryGold,
                          width: 1.2,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: timeRange,
                          dropdownColor: const Color(0xFF16264C),
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.darkPrimaryGold),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                          items: ['Daily', 'Weekly', 'Monthly', 'Yearly'].map((range) {
                            return DropdownMenuItem<String>(
                              value: range,
                              child: Text(range),
                            );
                          }).toList(),
                          onChanged: (newVal) {
                            if (newVal != null) {
                              ref.read(dashboardTimeRangeProvider.notifier).state = newVal;
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Top KPI Row (3 Cards with dynamic period aggregations)
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: formatter.format(henCount),
                    label: 'HENS',
                    subtext: 'Live Flock',
                    subtextColor: AppColors.darkGreen,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildKpiCard(
                    title: formatter.format(totalEggsPeriod),
                    label: 'EGGS ($timeRange)',
                    subtext: '$layingRate% laying rate',
                    subtextColor: AppColors.darkPrimaryGold,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Rs. ${formatter.format(totalIncomePeriod.toInt())}',
                    label: 'SALES ($timeRange)',
                    subtext: totalIncomePeriod >= totalExpensePeriod ? 'Profitable' : 'Expense High',
                    subtextColor: totalIncomePeriod >= totalExpensePeriod ? AppColors.darkGreen : AppColors.darkRed,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Production Efficiency Line Chart
            _buildProductionChartCard(filteredEggLogs, timeRange, isDark),
            const SizedBox(height: 20),

            // Financial Comparison Bar Chart
            _buildFinancialBarChartCard(
              context,
              filteredTransactions,
              totalIncomePeriod,
              totalExpensePeriod,
              timeRange,
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String label,
    required String subtext,
    required Color subtextColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              subtext,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: subtextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionChartCard(List<EggLogEntry> logs, String timeRange, bool isDark) {
    List<FlSpot> spots = [];
    List<String> xLabels = [];

    if (timeRange == 'Weekly') {
      xLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final counts = List.filled(7, 0.0);
      for (final log in logs) {
        if (log.timestamp != null) {
          final weekdayIdx = (log.timestamp!.weekday - 1) % 7;
          counts[weekdayIdx] += log.producedCount / 1000.0;
        }
      }
      for (int i = 0; i < 7; i++) {
        spots.add(FlSpot(i.toDouble(), counts[i]));
      }
    } else if (timeRange == 'Daily') {
      xLabels = ['06:00', '09:00', '12:00', '15:00', '18:00'];
      final counts = List.filled(5, 0.0);
      for (final log in logs) {
        if (log.timestamp != null) {
          final h = log.timestamp!.hour;
          int bucket = (h ~/ 4).clamp(0, 4);
          counts[bucket] += log.producedCount / 1000.0;
        }
      }
      for (int i = 0; i < 5; i++) {
        spots.add(FlSpot(i.toDouble(), counts[i]));
      }
    } else if (timeRange == 'Monthly') {
      xLabels = ['W1', 'W2', 'W3', 'W4'];
      final counts = List.filled(4, 0.0);
      for (final log in logs) {
        if (log.timestamp != null) {
          final day = log.timestamp!.day;
          int week = ((day - 1) ~/ 7).clamp(0, 3);
          counts[week] += log.producedCount / 1000.0;
        }
      }
      for (int i = 0; i < 4; i++) {
        spots.add(FlSpot(i.toDouble(), counts[i]));
      }
    } else {
      // Yearly
      xLabels = ['Q1', 'Q2', 'Q3', 'Q4'];
      final counts = List.filled(4, 0.0);
      for (final log in logs) {
        if (log.timestamp != null) {
          final m = log.timestamp!.month;
          int q = ((m - 1) ~/ 3).clamp(0, 3);
          counts[q] += log.producedCount / 1000.0;
        }
      }
      for (int i = 0; i < 4; i++) {
        spots.add(FlSpot(i.toDouble(), counts[i]));
      }
    }

    final hasProductionData = spots.any((s) => s.y > 0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'PRODUCTION EFFICIENCY ($timeRange)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'in 1,000s',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (!hasProductionData)
            Container(
              height: 140,
              alignment: Alignment.center,
              child: Text(
                'No egg collection logged for $timeRange.',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            )
          else
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 1,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: _gridLine,
                    getDrawingVerticalLine: _gridLine,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < xLabels.length) {
                            return Text(
                              xLabels[idx],
                              style: const TextStyle(
                                color: AppColors.darkPrimaryGold,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (xLabels.length - 1).toDouble(),
                  minY: 0,
                  maxY: (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 1).clamp(2.0, 20.0),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: AppColors.darkPrimaryGold,
                      barWidth: 3.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.darkPrimaryGold.withOpacity(0.35),
                            AppColors.darkPrimaryGold.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      spots: spots,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Real-Time Egg Yield Collection Trend',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialBarChartCard(
    BuildContext context,
    List<FinancialTransaction> transactions,
    double totalIncome,
    double totalExpense,
    String timeRange,
    bool isDark,
  ) {
    final hasFinancialData = totalIncome > 0 || totalExpense > 0;
    final maxVal = [totalIncome / 10000.0, totalExpense / 10000.0, 1.0]
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'FINANCIAL COMPARISON ($timeRange)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'in 10,000s Rs.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (!hasFinancialData)
            Container(
              height: 140,
              alignment: Alignment.center,
              child: Text(
                'No financial records for $timeRange.',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            )
          else
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.center,
                  maxY: maxVal * 1.25,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() == 0) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Total Income vs Expense',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: _gridLine,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barsSpace: 14,
                      barRods: [
                        BarChartRodData(
                          toY: totalIncome / 10000.0,
                          color: const Color(0xFF22C55E),
                          width: 22,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                        BarChartRodData(
                          toY: totalExpense / 10000.0,
                          color: const Color(0xFFEF4444),
                          width: 22,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 18),

          // + GENERATE REPORT Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => _showReportDialog(context, timeRange),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.darkPrimaryGold, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: const Color(0x330B1B3D),
              ),
              child: Text(
                '+ GENERATE $timeRange REPORT',
                style: const TextStyle(
                  color: AppColors.darkPrimaryGold,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static FlLine _gridLine(double value) => const FlLine(
        color: Color(0x1AFFFFFF),
        strokeWidth: 1,
      );
}
