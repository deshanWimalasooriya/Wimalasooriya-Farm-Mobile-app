import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_assets.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/hen_icon.dart';
import '../models/farm_models.dart';
import '../providers/farm_providers.dart';

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

  void _showNotificationSheet(BuildContext context, List<Map<String, dynamic>> vehicleAlerts, bool isFeedLow, int feedStock) {
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
              if (vehicleAlerts.isEmpty && !isFeedLow)
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
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added task: "$text"'),
                      backgroundColor: AppColors.darkGreen,
                    ),
                  );
                }
              },
              child: const Text('SAVE TASK'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteTask(BuildContext context, WidgetRef ref, DailyTask task) {
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
              Text('Delete Task', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(
            'Are you sure you want to permanently delete "${task.title}"?',
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
                await db.deleteTask(task.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task deleted successfully'),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
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
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      newStatus
                          ? 'Completed: "${task.title}"'
                          : 'Marked pending: "${task.title}"',
                    ),
                    backgroundColor: newStatus ? AppColors.darkGreen : AppColors.darkHarvestGold,
                  ),
                );
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
                final vehicleAlerts = ref.watch(expiringVehiclesProvider);
                final feedStock = metricsAsync.value?.feedPacketStock ?? 0;
                final isFeedLow = feedStock <= 150;
                final totalAlerts = vehicleAlerts.length + (isFeedLow ? 1 : 0);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_rounded, size: 28),
                      onPressed: () => _showNotificationSheet(context, vehicleAlerts, isFeedLow, feedStock),
                    ),
                    if (totalAlerts > 0)
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
                            '$totalAlerts',
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

              // Critical Alerts Banner (Bound to real inventory + vehicle documents)
              Consumer(
                builder: (context, ref, _) {
                  final vehicleAlerts = ref.watch(expiringVehiclesProvider);
                  return metricsAsync.when(
                    data: (metrics) => _buildCriticalAlertsCard(metrics, vehicleAlerts, isDark),
                    loading: () => _buildCriticalAlertsCard(null, vehicleAlerts, isDark),
                    error: (_, __) => _buildCriticalAlertsCard(null, vehicleAlerts, isDark),
                  );
                },
              ),
              const SizedBox(height: 18),

              // Daily Snapshot Card (100% Real-Time Firebase Stream)
              metricsAsync.when(
                data: (metrics) => _buildDailySnapshotCard(metrics, isDark),
                loading: () => _buildDailySnapshotCard(null, isDark, isLoading: true),
                error: (err, stack) => _buildDailySnapshotCard(null, isDark),
              ),
              const SizedBox(height: 22),

              // Daily Operational Tasks Header with + Add Task Button
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'DAILY OPERATIONAL TASKS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _showAddTaskDialog(context, ref),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x26D4AF37),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.darkPrimaryGold, width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: AppColors.darkPrimaryGold, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Add Task',
                            style: TextStyle(
                              color: AppColors.darkPrimaryGold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

  Widget _buildCriticalAlertsCard(FarmMetrics? metrics, List<Map<String, dynamic>> vehicleAlerts, bool isDark) {
    final feedStock = metrics?.feedPacketStock ?? 0;
    final isFeedLow = feedStock <= 150;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          width: 1,
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
                if (vehicleAlerts.isNotEmpty) ...[
                  ...vehicleAlerts.take(2).map((a) {
                    final isExp = a['isExpired'] == true;
                    final days = a['daysLeft'];
                    final reg = a['regNumber'];
                    final doc = a['docName'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildAlertItem(
                        icon: isExp ? Icons.cancel_rounded : Icons.alarm_rounded,
                        iconColor: isExp ? const Color(0xFFEF4444) : AppColors.warningYellow,
                        text: isExp ? 'VEHICLE ALERT: $reg $doc has EXPIRED!' : 'VEHICLE ALERT: $reg $doc expires in $days days',
                      ),
                    );
                  }),
                ],
                _buildAlertItem(
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppColors.warningYellow,
                  text: isFeedLow
                      ? 'Low Stock: Layer Feed ($feedStock packets remaining)'
                      : 'Feed Reserve Stable ($feedStock packets in inventory)',
                ),
                const SizedBox(height: 10),
                _buildAlertItem(
                  icon: Icons.local_shipping_rounded,
                  iconColor: AppColors.darkPrimaryGold,
                  text: 'Fleet & Logistics: ${vehicleAlerts.isEmpty ? "All vehicle documents active" : "${vehicleAlerts.length} vehicle compliance notices"}',
                ),
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

  Widget _buildTasksList(BuildContext context, WidgetRef ref, List<DailyTask> tasks, bool isDark) {
    if (tasks.isEmpty) {
      return Container(
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
                'Tap "+ Add Task" to schedule daily farm duties.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

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
        children: tasks.map<Widget>((task) {
          final isCompleted = task.isCompleted;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: InkWell(
              onTap: () => _confirmToggleTask(context, ref, task),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  children: [
                    // Checkbox
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: isCompleted ? AppColors.darkHarvestGold : Colors.transparent,
                        border: Border.all(
                          color: isCompleted ? AppColors.darkHarvestGold : const Color(0xFF64748B),
                          width: 1.8,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check, size: 20, color: Color(0xFF0B1B3D))
                          : null,
                    ),
                    const SizedBox(width: 14),

                    // Task Title
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isCompleted
                              ? AppColors.darkPrimaryGold
                              : (isDark ? Colors.white : AppColors.lightTextPrimary),
                        ),
                      ),
                    ),

                    // Trash / Delete Task Icon
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                      tooltip: 'Delete Task',
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
