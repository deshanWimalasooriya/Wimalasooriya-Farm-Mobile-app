import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_assets.dart';
import '../core/theme/app_colors.dart';
import '../models/farm_models.dart';
import '../providers/farm_providers.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyNameController;
  late TextEditingController _addressController;
  late TextEditingController _contactNumberController;
  late TextEditingController _unitPriceController;
  late TextEditingController _capacityController;

  bool _initialized = false;
  bool _isSaving = false;
  bool _isResetting = false;
  bool _isClearingTasks = false;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController();
    _addressController = TextEditingController();
    _contactNumberController = TextEditingController();
    _unitPriceController = TextEditingController();
    _capacityController = TextEditingController();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _addressController.dispose();
    _contactNumberController.dispose();
    _unitPriceController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _populateData(FarmSettings settings) {
    if (!_initialized) {
      _companyNameController.text = settings.companyName;
      _addressController.text = settings.address;
      _contactNumberController.text = settings.contactNumber;
      _unitPriceController.text = settings.unitEggPrice.toStringAsFixed(2);
      _capacityController.text = settings.maxHenCapacity.toString();
      _initialized = true;
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16264C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.save_rounded, color: AppColors.darkPrimaryGold),
            SizedBox(width: 10),
            Text('Save Settings?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Update company details and farm capacity parameters in Firestore?',
          style: TextStyle(color: Colors.white70),
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
            child: const Text('CONFIRM SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);
    try {
      final db = ref.read(databaseServiceProvider);
      final newSettings = FarmSettings(
        companyName: _companyNameController.text.trim(),
        address: _addressController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        unitEggPrice: double.tryParse(_unitPriceController.text.trim()) ?? 40.0,
        maxHenCapacity: int.tryParse(_capacityController.text.trim()) ?? 10000,
      );

      await db.saveFarmSettings(newSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Farm settings updated successfully!'),
            backgroundColor: AppColors.darkGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e'), backgroundColor: AppColors.darkRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showAddTaskDialog(BuildContext context) async {
    final titleController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16264C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.add_task_rounded, color: AppColors.darkPrimaryGold),
              SizedBox(width: 10),
              Text('Add Daily Task', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: TextField(
            controller: titleController,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              labelText: 'Task Description / Title',
              labelStyle: TextStyle(color: Colors.white70),
              fillColor: Color(0xFF0B1B3D),
              filled: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkPrimaryGold,
                foregroundColor: const Color(0xFF0B1B3D),
              ),
              onPressed: () async {
                final text = titleController.text.trim();
                if (text.isNotEmpty) {
                  final db = ref.read(databaseServiceProvider);
                  await db.addNewTask(text);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added task: "$text"'),
                        backgroundColor: AppColors.darkGreen,
                      ),
                    );
                  }
                }
              },
              child: const Text('ADD TASK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteSpecificTask(DailyTask task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16264C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 10),
            Text('Delete Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = ref.read(databaseServiceProvider);
      await db.deleteTask(task.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted task: "${task.title}"'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _clearDailyTasks() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16264C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cleaning_services_rounded, color: AppColors.warningYellow),
            SizedBox(width: 10),
            Text('Clear Daily Tasks?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete all daily tasks from the Home screen? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warningYellow,
              foregroundColor: const Color(0xFF0B1B3D),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CLEAR ALL TASKS', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isClearingTasks = true);
    try {
      final db = ref.read(databaseServiceProvider);
      await db.clearAllDailyTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All daily operational tasks cleared successfully.'),
            backgroundColor: AppColors.darkGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing tasks: $e'), backgroundColor: AppColors.darkRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isClearingTasks = false);
    }
  }

  Future<void> _factoryResetDatabase() async {
    final resetConfirmCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF16264C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Factory Reset Database',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DANGER: This action will permanently erase all farm operational data from Cloud Firestore:\n'
                      '• Flock ledger & egg production logs\n'
                      '• Financial ledger & salary payments\n'
                      '• Workers & labor groups\n'
                      '• Vehicles & maintenance history\n'
                      '• Bulk orders & daily tasks\n'
                      '• Farm metrics counters\n\n'
                      'NOTE: Admin accounts and users collection will be strictly PRESERVED.',
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Type "RESET" to confirm this irreversible action:',
                      style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: resetConfirmCtrl,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: 'Type RESET here',
                        hintStyle: TextStyle(color: Colors.white38),
                        fillColor: Color(0xFF0B1B3D),
                        filled: true,
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: resetConfirmCtrl.text.trim() == 'RESET'
                      ? () => Navigator.pop(ctx, true)
                      : null,
                  child: const Text('PERMANENTLY RESET', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isResetting = true);
    try {
      final db = ref.read(databaseServiceProvider);
      await db.factoryResetDatabase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database factory reset completed. Operational records cleared.'),
            backgroundColor: AppColors.darkGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resetting database: $e'), backgroundColor: AppColors.darkRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(farmSettingsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackgroundWarm,
      appBar: AppBar(
        title: const Text('Admin Panel', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: settingsAsync.when(
        data: (settings) {
          _populateData(settings);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admin Panel Header Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.darkPrimaryGold.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.darkPrimaryGold, width: 2),
                          ),
                          child: ClipOval(
                            child: Image.asset(AppAssets.logo, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FARM ADMINISTRATION',
                                style: TextStyle(
                                  color: AppColors.darkPrimaryGold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Global Enterprise Configuration',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 1: Company & Farm Settings
                  _buildSectionHeader('COMPANY & OPERATIONAL DETAILS', Icons.business_rounded),
                  const SizedBox(height: 12),

                  _buildTextField(
                    controller: _companyNameController,
                    label: 'Company Name',
                    icon: Icons.storefront_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),

                  _buildTextField(
                    controller: _addressController,
                    label: 'Farm Address / Location',
                    icon: Icons.location_on_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),

                  _buildTextField(
                    controller: _contactNumberController,
                    label: 'Contact Number',
                    icon: Icons.phone_rounded,
                    isDark: isDark,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _unitPriceController,
                          label: 'Unit Egg Price (Rs.)',
                          icon: Icons.monetization_on_rounded,
                          isDark: isDark,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _capacityController,
                          label: 'Max Farm Capacity',
                          icon: Icons.domain_rounded,
                          isDark: isDark,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Save Settings Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkPrimaryGold,
                        foregroundColor: const Color(0xFF0B1B3D),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0B1B3D)),
                            )
                          : const Icon(Icons.check_circle_rounded),
                      label: Text(
                        _isSaving ? 'SAVING...' : 'SAVE COMPANY SETTINGS',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Section 2: Operational Data Management (Tasks)
                  _buildSectionHeader('OPERATIONAL TASKS MANAGEMENT', Icons.assignment_turned_in_rounded),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF16264C) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0x33FFFFFF) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Daily Operational Tasks',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Create, manage, or clear tasks shown on the Home dashboard.',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showAddTaskDialog(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.darkPrimaryGold,
                                foregroundColor: const Color(0xFF0B1B3D),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // List of Current Tasks
                        Consumer(
                          builder: (context, ref, _) {
                            final tasksAsync = ref.watch(dailyTasksStreamProvider);
                            return tasksAsync.when(
                              data: (tasks) {
                                if (tasks.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                      child: Text(
                                        'No operational tasks found.',
                                        style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                      ),
                                    ),
                                  );
                                }
                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: tasks.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final task = tasks[index];
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF0F1E36) : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: task.isCompleted
                                              ? const Color(0xFF22C55E)
                                              : (isDark ? AppColors.darkCardBorder.withOpacity(0.5) : AppColors.lightCardBorder),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            task.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                            size: 18,
                                            color: task.isCompleted ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              task.title,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: task.isCompleted ? const Color(0xFF22C55E) : null,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                                            tooltip: 'Delete Task',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _confirmDeleteSpecificTask(task),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkPrimaryGold),
                                ),
                              ),
                              error: (e, _) => Text('Error loading tasks: $e', style: const TextStyle(fontSize: 12, color: Colors.red)),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Clear All Tasks Button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _isClearingTasks ? null : _clearDailyTasks,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.warningYellow,
                              side: const BorderSide(color: AppColors.warningYellow),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: _isClearingTasks
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.warningYellow),
                                  )
                                : const Icon(Icons.delete_sweep_rounded),
                            label: Text(_isClearingTasks ? 'CLEARING...' : 'Clear All Home Tasks'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Section 3: Danger Zone (Factory Reset)
                  _buildSectionHeader('DANGER ZONE (SYSTEM RESET)', Icons.dangerous_rounded, isDanger: true),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF450A0A).withOpacity(0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDC2626), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
                            SizedBox(width: 8),
                            Text(
                              'Factory Reset Database',
                              style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Deletes all live records across flock, finance, inventory, workers, and fleet. Admin account is preserved.',
                          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _isResetting ? null : _factoryResetDatabase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: _isResetting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.delete_forever_rounded),
                            label: Text(
                              _isResetting ? 'RESETTING DATABASE...' : 'FACTORY RESET DATABASE',
                              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.darkPrimaryGold)),
        error: (err, _) => Center(child: Text('Error loading settings: $err')),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {bool isDanger = false}) {
    final color = isDanger ? const Color(0xFFEF4444) : AppColors.darkPrimaryGold;
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF0B1B3D),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
        prefixIcon: Icon(icon, color: AppColors.darkPrimaryGold),
        fillColor: isDark ? const Color(0xFF16264C) : Colors.white,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return '$label cannot be empty';
        return null;
      },
    );
  }
}
