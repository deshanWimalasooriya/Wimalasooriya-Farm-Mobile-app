import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_assets.dart';
import '../core/theme/app_colors.dart';
import '../models/farm_models.dart';
import '../providers/farm_providers.dart';

class FlockScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenNotifications;

  const FlockScreen({super.key, required this.onOpenNotifications});

  @override
  ConsumerState<FlockScreen> createState() => _FlockScreenState();
}

class _FlockScreenState extends ConsumerState<FlockScreen> {
  int _selectedSubTab = 0; // 0: Hens Inventory, 1: Egg Yields

  // Hens Stepper & Reason State
  int _henDelta = 50;
  final TextEditingController _henDeltaController = TextEditingController(text: '50');
  String _selectedReason = 'New Batch';
  final List<String> _reasons = ['New Batch', 'Remove', 'Natural Death', 'Culled', 'Sold'];

  // Egg Yields State
  int _eggYieldCount = 500;
  final TextEditingController _eggYieldController = TextEditingController(text: '500');

  @override
  void dispose() {
    _henDeltaController.dispose();
    _eggYieldController.dispose();
    super.dispose();
  }

  Future<void> _recordFlockChange() async {
    final count = int.tryParse(_henDeltaController.text) ?? _henDelta;
    if (count <= 0) return;

    final action = (_selectedReason == 'New Batch') ? 'add' : 'remove';
    final actionLabel = action == 'add' ? 'Add' : 'Remove';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16264C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              action == 'add' ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
              color: action == 'add' ? AppColors.darkGreen : const Color(0xFFEF4444),
            ),
            const SizedBox(width: 10),
            Text('Confirm Flock $actionLabel', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to ${action == 'add' ? 'add' : 'deduct'} $count hens ($actionLabel reason: $_selectedReason) in Firestore?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'add' ? AppColors.darkGreen : const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('CONFIRM $actionLabel'.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final db = ref.read(databaseServiceProvider);
    try {
      await db.recordFlockChange(
        action: action,
        count: count,
        reason: _selectedReason,
        loggedBy: 'Deshan Wimalasooriya',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully recorded flock change: ${action == 'add' ? '+' : '-'}$count Hens ($_selectedReason)'),
            backgroundColor: action == 'add' ? AppColors.darkGreen : AppColors.darkRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notice: $e'), backgroundColor: AppColors.darkRed),
        );
      }
    }
  }

  void _confirmResetToZero(BuildContext context, int currentHenCount) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16264C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
              SizedBox(width: 10),
              Text('Reset Flock Count?', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: const Text(
            'Are you sure you want to reset the live hen count to 0? This action will set the count to 0 and log an audit entry in the activity history.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () async {
                final db = ref.read(databaseServiceProvider);
                await db.resetHenCountToZero(loggedBy: 'Deshan Wimalasooriya');
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Live hen count has been reset to 0.'),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text('RESET TO 0'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(farmMetricsStreamProvider);
    final flockLedgerAsync = ref.watch(flockLedgerStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentDateStr = DateFormat('MMMM d, y').format(DateTime.now());

    final henCount = metricsAsync.value?.currentHenCount ?? 0;
    final formatter = NumberFormat('#,###');

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
                  onPressed: widget.onOpenNotifications,
                ),
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
            // Screen Header
            const Text(
              'Flock & Inventory',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currentDateStr,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Horizontal Pill Sub-Tabs
            Row(
              children: [
                Expanded(child: _buildSubTab(0, 'Hens Inventory')),
                const SizedBox(width: 12),
                Expanded(child: _buildSubTab(1, 'Egg Yields')),
              ],
            ),
            const SizedBox(height: 20),

            if (_selectedSubTab == 0) ...[
              // Live Hens Count Card with Stepper, Reason Dropdown & Reset to 0
              _buildLiveHensCard(henCount, formatter, isDark),
              const SizedBox(height: 20),

              // Flock Size Over Time Chart (Bound to Real Firestore Activity)
              _buildFlockSizeChartCard(flockLedgerAsync, isDark),
              const SizedBox(height: 20),

              // Recent Flock Activity Audit Log (Real Stream, Zero Mock Data)
              _buildRecentFlockActivityCard(flockLedgerAsync, isDark),
            ] else ...[
              _buildEggYieldsSubTab(isDark, formatter),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubTab(int index, String label) {
    final isSelected = _selectedSubTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedSubTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isSelected ? const Color(0x33D4AF37) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.darkPrimaryGold : Colors.white60,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.darkPrimaryGold : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLiveHensCard(int henCount, NumberFormat formatter, bool isDark) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LIVE HENS COUNT',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              // Reset to 0 Button with Confirmation
              InkWell(
                onTap: () => _confirmResetToZero(context, henCount),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x22EF4444),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEF4444), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restart_alt_rounded, color: Color(0xFFEF4444), size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Reset to 0',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatter.format(henCount),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkPrimaryGold,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'HENS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Log Hen Count Change',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Stepper + Reason Selector Row (FIXED: High-Contrast Visible Text)
          Row(
            children: [
              // Minus Button
              _buildCircleButton(
                icon: Icons.remove,
                onTap: () {
                  setState(() {
                    if (_henDelta > 5) {
                      _henDelta -= 5;
                      _henDeltaController.text = _henDelta.toString();
                    }
                  });
                },
              ),
              const SizedBox(width: 8),

              // Direct Numeric Input (FIXED: Dark Navy fill with high-contrast text)
              Container(
                width: 72,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.darkPrimaryGold,
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _henDeltaController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  cursorColor: AppColors.darkPrimaryGold,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0B1B3D),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    fillColor: Colors.transparent,
                  ),
                  onChanged: (val) {
                    final parsed = int.tryParse(val);
                    if (parsed != null) _henDelta = parsed;
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Plus Button
              _buildCircleButton(
                icon: Icons.add,
                onTap: () {
                  setState(() {
                    _henDelta += 5;
                    _henDeltaController.text = _henDelta.toString();
                  });
                },
              ),
              const SizedBox(width: 10),

              // Reason Dropdown Pill (UPDATED: New Batch, Remove, Natural Death, Culled, Sold)
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x33FFFFFF)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _reasons.contains(_selectedReason) ? _selectedReason : _reasons.first,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF16264C),
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.darkPrimaryGold),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0B1B3D),
                      ),
                      items: _reasons.map((r) {
                        return DropdownMenuItem<String>(
                          value: r,
                          child: Text(
                            'Reason: $r',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedReason = val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // + RECORD FLOCK CHANGE Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _recordFlockChange,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC59B27),
                foregroundColor: const Color(0xFF0B1B3D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '+ RECORD FLOCK CHANGE',
                style: TextStyle(
                  fontSize: 15,
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

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: Color(0xFFC59B27),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF0B1B3D), size: 22),
      ),
    );
  }

  Widget _buildFlockSizeChartCard(AsyncValue<List<FlockLedgerEntry>> asyncLogs, bool isDark) {
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
          const Text(
            'FLOCK SIZE OVER TIME',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 18),

          asyncLogs.when(
            data: (logs) {
              if (logs.isEmpty) {
                return const SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'No historical flock entries logged yet.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ),
                );
              }

              // Plot actual recent records in chronological order
              final reversed = logs.reversed.toList();
              final spots = <FlSpot>[];
              double cumulative = 4000;
              for (int i = 0; i < reversed.length; i++) {
                final entry = reversed[i];
                if (entry.action == 'add') {
                  cumulative += entry.count;
                } else {
                  cumulative = (cumulative - entry.count).clamp(0, 1000000);
                }
                spots.add(FlSpot(i.toDouble(), cumulative / 1000.0));
              }

              return SizedBox(
                height: 150,
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
                    titlesData: const FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (spots.length - 1).toDouble().clamp(1.0, 50.0),
                    minY: 0,
                    maxY: (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 1).clamp(2.0, 20.0),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: AppColors.darkPrimaryGold,
                        barWidth: 3.5,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.darkPrimaryGold.withOpacity(0.3),
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
              );
            },
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator(color: AppColors.darkPrimaryGold)),
            ),
            error: (err, _) => const SizedBox(
              height: 120,
              child: Center(child: Text('Error loading flock history', style: TextStyle(color: Colors.white70))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentFlockActivityCard(AsyncValue<List<FlockLedgerEntry>> asyncLogs, bool isDark) {
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
          const Text(
            'RECENT FLOCK ACTIVITY',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),

          asyncLogs.when(
            data: (logs) {
              if (logs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text(
                      'No flock activity recorded yet.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ),
                );
              }

              return Column(
                children: logs.map((entry) {
                  final isAdd = entry.action == 'add';
                  final timeStr = entry.timestamp != null
                      ? DateFormat('MMM d, hh:mm a').format(entry.timestamp!)
                      : 'Just now';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isAdd
                                ? const Color(0x3322C55E)
                                : const Color(0x33EF4444),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isAdd ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isAdd ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 14, color: Colors.white),
                              children: [
                                TextSpan(
                                  text: '${isAdd ? '+' : '-'} ${entry.count} Hens ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isAdd ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                                  ),
                                ),
                                TextSpan(
                                  text: '| ${entry.reason}',
                                  style: const TextStyle(color: Color(0xFFCBD5E1)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: AppColors.darkPrimaryGold),
              ),
            ),
            error: (err, _) => const Text('Error loading flock activity'),
          ),
        ],
      ),
    );
  }

  Widget _buildEggYieldsSubTab(bool isDark, NumberFormat formatter) {
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
          const Text(
            'DAILY EGG YIELD COLLECTION LOGGER',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 18),
          const Text('Enter Total Collected Eggs Today:'),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildCircleButton(
                icon: Icons.remove,
                onTap: () {
                  setState(() {
                    if (_eggYieldCount >= 50) {
                      _eggYieldCount -= 50;
                      _eggYieldController.text = _eggYieldCount.toString();
                    }
                  });
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkPrimaryGold),
                  ),
                  child: TextField(
                    controller: _eggYieldController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    cursorColor: AppColors.darkPrimaryGold,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkPrimaryGold : const Color(0xFF0B1B3D),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      fillColor: Colors.transparent,
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null) _eggYieldCount = parsed;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildCircleButton(
                icon: Icons.add,
                onTap: () {
                  setState(() {
                    _eggYieldCount += 50;
                    _eggYieldController.text = _eggYieldCount.toString();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final count = int.tryParse(_eggYieldController.text) ?? _eggYieldCount;
                if (count <= 0) return;

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF16264C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Row(
                      children: [
                        Icon(Icons.egg_outlined, color: AppColors.darkPrimaryGold),
                        SizedBox(width: 10),
                        Text('Confirm Egg Yield', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    content: Text(
                      'Record $count eggs collected today into Firestore egg logs?',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkPrimaryGold,
                          foregroundColor: const Color(0xFF0B1B3D),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('CONFIRM LOG', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;

                final db = ref.read(databaseServiceProvider);
                await db.recordEggProduction(producedCount: count, loggedBy: 'Deshan Wimalasooriya');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully recorded $count eggs collected today!'),
                      backgroundColor: AppColors.darkGreen,
                    ),
                  );
                }
              },
              child: const Text('RECORD TODAY\'S EGG YIELD'),
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
