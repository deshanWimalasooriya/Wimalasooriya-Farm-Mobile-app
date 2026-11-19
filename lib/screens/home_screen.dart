import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_assets.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/hen_icon.dart';
import '../models/farm_models.dart';
import '../providers/farm_providers.dart';
import '../utils/app_snackbar.dart';

class HomeScreen extends ConsumerWidget {
  final VoidCallback onOpenNotifications;

  const HomeScreen({super.key, required this.onOpenNotifications});

  String _getTimeBasedGreeting(String name) {
    final hour = DateTime.now().hour;
    if (hour >= 0 && hour < 12) {
      return 'Good Morning, $name';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon, $name';
    } else {
      return 'Good Evening, $name';
    }
  }

  void _showNotificationSheet(
    BuildContext context,
    List<Map<String, dynamic>> vehicleAlerts,
    bool isFeedLow,
    int feedStock,
    bool isHenLow,
    int henCount,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16264C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.notifications_active_rounded, color: AppColors.darkPrimaryGold, size: 26),
                  SizedBox(width: 10),
                  Text('Active Farm Notifications', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              if (vehicleAlerts.isEmpty && !isFeedLow && !isHenLow)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('All operations normal. No critical alerts.', style: TextStyle(color: Colors.white70)),
                  ),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isHenLow)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B1E1E).withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFDC2626)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_rounded, color: Color(0xFFEF4444)),
                                const SizedBox(width: 10),
                                Expanded(child: Text('Low Hen Count: Only $henCount live hens remaining!', style: const TextStyle(color: Colors.white))),
                              ],
                            ),
                          ),
                        if (isFeedLow)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B1E1E).withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFDC2626)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
                                const SizedBox(width: 10),
                                Expanded(child: Text('Feed Stock Alert: $feedStock packets remaining.', style: const TextStyle(color: Colors.white))),
                              ],
                            ),
                          ),
                        ...vehicleAlerts.map((a) {
                          final isExp = a['isExpired'] == true;
                          final days = a['daysLeft'];
                          final reg = a['regNumber'];
                          final doc = a['docName'];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isExp ? const Color(0xFF8B1E1E).withOpacity(0.5) : const Color(0xFF3B2F04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isExp ? const Color(0xFFEF4444) : AppColors.darkPrimaryGold),
                            ),
                            child: Row(
                              children: [
                                Icon(isExp ? Icons.error_outline_rounded : Icons.alarm_rounded, color: isExp ? const Color(0xFFEF4444) : AppColors.darkPrimaryGold),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('$reg — $doc', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 2),
                                      Text(
                                        isExp ? 'Document expired! Renew immediately.' : 'Expires in $days day(s).',
                                        style: TextStyle(color: isExp ? const Color(0xFFFCA5A5) : const Color(0xFFFDE68A), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16264C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.add_task_rounded, color: AppColors.darkPrimaryGold),
              SizedBox(width: 10),
              Text('Add Operational Task', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: TextField(
            controller: titleController,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              labelText: 'Task Description / Title',
              fillColor: Color(0xFF0B1B3D),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = titleController.text.trim();
                if (text.isNotEmpty) {
                  final db = ref.read(databaseServiceProvider);
                  await db.addNewTask(text);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    AppSnackBar.showSuccess(context, 'Added task: "$text"');
                  }
                }
              },
              child: const Text('SAVE TASK'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _confirmDeleteTask(BuildContext context, WidgetRef ref, DailyTask task) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16264C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
              SizedBox(width: 10),
              Text('Delete Task', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(
            'Are you sure you want to permanently delete "${task.title}"?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () async {
                final db = ref.read(databaseServiceProvider);
                await db.deleteTask(task.id);
                if (ctx.mounted) Navigator.pop(ctx, true);
                if (context.mounted) {
                  AppSnackBar.showInfo(context, 'Task deleted successfully');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _confirmToggleTask(BuildContext context, WidgetRef ref, DailyTask task) {
    final newStatus = !task.isCompleted;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16264C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                newStatus ? Icons.check_circle_outline_rounded : Icons.replay_rounded,
                color: AppColors.darkPrimaryGold,
              ),
              const SizedBox(width: 10),
              const Text('Confirm Task Status', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: Text(
            newStatus
                ? 'Are you sure you want to mark "${task.title}" as completed?'
                : 'Are you sure you want to mark "${task.title}" as pending?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () async {
                final db = ref.read(databaseServiceProvider);
                await db.toggleTaskCompletion(task.id, newStatus);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  if (newStatus) {
                    AppSnackBar.showSuccess(context, 'Completed: "${task.title}"');
                  } else {
                    AppSnackBar.showInfo(context, 'Marked pending: "${task.title}"');
                  }
                }
              },
              child: const Text('CONFIRM'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(farmMetricsStreamProvider);
    final tasksAsync = ref.watch(dailyTasksStreamProvider);
    final userAsync = ref.watch(currentUserStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentDateStr = DateFormat('MMMM d, y').format(DateTime.now());
    final userName = userAsync.value?.name ?? 'Deshan';
    final firstName = userName.split(' ').first;

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
            child: Consumer(
              builder: (context, ref, _) {
                final notifsAsync = ref.watch(adminNotificationsStreamProvider);
                final unreadNotifsCount = notifsAsync.value?.where((n) => !n.isRead).length ?? 0;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_rounded, size: 28),
                      onPressed: onOpenNotifications,
                    ),
                    if (unreadNotifsCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '$unreadNotifsCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(farmMetricsStreamProvider);
          ref.invalidate(dailyTasksStreamProvider);
          ref.invalidate(currentUserStreamProvider);
          ref.invalidate(vehiclesStreamProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dynamic Time-Based Greeting Synced with Profile
              Text(
                _getTimeBasedGreeting(firstName),
                style: const TextStyle(
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
              const SizedBox(height: 20),

              // Critical Alerts Banner (Strictly bound to real Firestore queries; hidden if none)
              Consumer(
                builder: (context, ref, _) {
                  final vehicleAlerts = ref.watch(expiringVehiclesProvider);
                  final metrics = metricsAsync.value;
                  final henCount = metrics?.currentHenCount ?? 0;
                  final feedStock = metrics?.feedPacketStock ?? 0;
                  final isHenLow = metrics != null && henCount > 0 && henCount < 100;
                  final isFeedLow = metrics != null && feedStock > 0 && feedStock <= 150;
                  final hasAlerts = vehicleAlerts.isNotEmpty || isHenLow || isFeedLow;

                  if (!hasAlerts) return const SizedBox.shrink();

                  return Column(
                    children: [
                      _buildCriticalAlertsCard(
                        metrics,
                        vehicleAlerts,
                        isDark,
                        isHenLow,
                        isFeedLow,
                      ),
                      const SizedBox(height: 18),
                    ],
                  );
                },
              ),

              // Overall Lifetime Profit KPI Card (Real-Time from transactionsStreamProvider)
              _buildLifetimeProfitCard(context, ref, isDark),
              const SizedBox(height: 18),

              // Daily Snapshot Card (100% Real-Time Firebase Stream)
              metricsAsync.when(
                data: (metrics) => _buildDailySnapshotCard(metrics, isDark),
                loading: () => _buildDailySnapshotCard(null, isDark, isLoading: true),
                error: (err, stack) => _buildDailySnapshotCard(null, isDark),
              ),
              const SizedBox(height: 22),

              // Daily Operational Tasks Header (Managed in Admin Panel)
              const Text(
                'DAILY OPERATIONAL TASKS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Real-Time Tasks Stream (No Mock Data)
              tasksAsync.when(
                data: (tasks) => _buildTasksList(context, ref, tasks, isDark),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(color: AppColors.darkPrimaryGold),
                  ),
                ),
                error: (err, _) => Center(
                  child: Text('Error loading tasks: $err', style: const TextStyle(color: Colors.white70)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCriticalAlertsCard(
    FarmMetrics? metrics,
    List<Map<String, dynamic>> vehicleAlerts,
    bool isDark,
    bool isHenLow,
    bool isFeedLow,
  ) {
    final feedStock = metrics?.feedPacketStock ?? 0;
    final henCount = metrics?.currentHenCount ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFDC2626).withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              children: [
                if (isHenLow)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildAlertItem(
                      icon: Icons.warning_rounded,
                      iconColor: const Color(0xFFEF4444),
                      text: 'FLOCK ALERT: Low live hen count ($henCount hens remaining on farm)!',
                    ),
                  ),
                if (isFeedLow)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildAlertItem(
                      icon: Icons.inventory_2_outlined,
                      iconColor: AppColors.warningYellow,
                      text: 'FEED ALERT: Low inventory stock ($feedStock packets remaining)!',
                    ),
                  ),
                if (vehicleAlerts.isNotEmpty)
                  ...vehicleAlerts.take(2).map((a) {
                    final isExp = a['isExpired'] == true;
                    final days = a['daysLeft'];
                    final reg = a['regNumber'];
                    final doc = a['docName'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildAlertItem(
                        icon: isExp ? Icons.cancel_rounded : Icons.alarm_rounded,
                        iconColor: isExp ? const Color(0xFFEF4444) : AppColors.warningYellow,
                        text: isExp
                            ? 'VEHICLE ALERT: $reg $doc has EXPIRED!'
                            : 'VEHICLE ALERT: $reg $doc expires in $days days',
                      ),
                    );
                  }),
              ],
            ),
          ),
          Positioned(
            left: 14,
            top: -12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF8B1E1E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDC2626), width: 1),
              ),
              child: const Text(
                'CRITICAL ALERTS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
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

  Widget _buildAlertItem({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailySnapshotCard(FarmMetrics? metrics, bool isDark, {bool isLoading = false}) {
    final henCount = metrics?.currentHenCount ?? 0;
    final eggCount = metrics?.todayEggCount ?? 0;
    final unitPrice = metrics?.unitEggPrice ?? 40.0;
    final revenue = eggCount * unitPrice;

    final formatter = NumberFormat('#,###');

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
            'DAILY SNAPSHOT',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0x22FFFFFF), height: 1),
          const SizedBox(height: 14),

          // Hens Row
          Row(
            children: [
              const HenIcon(size: 26, color: Colors.white),
              const SizedBox(width: 14),
              const Text(
                'Hens',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                formatter.format(henCount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkPrimaryGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Today's Eggs Row
          Row(
            children: [
              const Icon(Icons.egg_outlined, size: 26, color: Colors.white),
              const SizedBox(width: 14),
              const Text(
                "Today's Eggs",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                formatter.format(eggCount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkPrimaryGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Current Revenue Highlight Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkPrimaryGold.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0B1B3D),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'Rs',
                      style: TextStyle(
                        color: AppColors.darkPrimaryGold,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Current Revenue',
                    style: TextStyle(
                      color: Color(0xFF0B1B3D),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Rs. ${formatter.format(revenue.toInt())}',
                    style: const TextStyle(
                      color: Color(0xFF0B1B3D),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifetimeProfitCard(BuildContext context, WidgetRef ref, bool isDark) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    return transactionsAsync.when(
      data: (transactions) {
        final totalIncome = transactions
            .where((t) => t.type == 'income')
            .fold<double>(0.0, (sum, t) => sum + t.amount);
        final totalExpense = transactions
            .where((t) => t.type == 'expense')
            .fold<double>(0.0, (sum, t) => sum + t.amount);
        final lifetimeProfit = totalIncome - totalExpense;
        final isPositive = lifetimeProfit >= 0;
        final formatter = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPositive
                  ? (isDark
                      ? [const Color(0xFF0F3822), const Color(0xFF082014)]
                      : [const Color(0xFFDCFCE7), const Color(0xFFBBF7D0)])
                  : (isDark
                      ? [const Color(0xFF4A1515), const Color(0xFF2B0A0A)]
                      : [const Color(0xFFFEE2E2), const Color(0xFFFECACA)]),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444)).withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444)).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  color: isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OVERALL LIFETIME PROFIT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatter.format(lifetimeProfit),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isPositive
                              ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
                              : (isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'In: ${NumberFormat.compactSimpleCurrency(name: 'Rs. ').format(totalIncome)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Out: ${NumberFormat.compactSimpleCurrency(name: 'Rs. ').format(totalExpense)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 70,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkPrimaryGold),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildTasksList(BuildContext context, WidgetRef ref, List<DailyTask> tasks, bool isDark) {
    if (tasks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.assignment_outlined, size: 40, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              const SizedBox(height: 10),
              Text(
                'No operational tasks found',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Operational tasks are scheduled and managed via the Admin Panel.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: tasks.map<Widget>((task) {
          final isCompleted = task.isCompleted;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Dismissible(
              key: Key(task.id),
              direction: DismissDirection.horizontal,
              confirmDismiss: (direction) => _confirmDeleteTask(context, ref, task),
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text('Delete Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              secondaryBackground: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Delete Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    SizedBox(width: 8),
                    Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                  ],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F1E36) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: isCompleted
                      ? Border.all(color: const Color(0xFF22C55E), width: 2)
                      : Border.all(
                          color: isDark ? AppColors.darkCardBorder.withOpacity(0.5) : AppColors.lightCardBorder,
                          width: 1,
                        ),
                ),
                child: Row(
                  children: [
                    // Checkbox
                    GestureDetector(
                      onTap: () => _confirmToggleTask(context, ref, task),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: isCompleted ? const Color(0xFF22C55E) : Colors.transparent,
                          border: Border.all(
                            color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFF64748B),
                            width: 1.8,
                          ),
                        ),
                        child: isCompleted
                            ? const Icon(Icons.check, size: 18, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Task Title
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _confirmToggleTask(context, ref, task),
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted
                                ? const Color(0xFF22C55E)
                                : (isDark ? Colors.white : AppColors.lightTextPrimary),
                          ),
                        ),
                      ),
                    ),

                    // Trash / Delete Task Icon
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                      tooltip: 'Delete Task',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _confirmDeleteTask(context, ref, task),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
