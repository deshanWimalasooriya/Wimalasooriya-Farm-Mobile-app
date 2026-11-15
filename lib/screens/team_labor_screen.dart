import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_assets.dart';
import '../core/theme/app_colors.dart';
import '../models/farm_models.dart';
import '../providers/farm_providers.dart';
import '../widgets/worker_id_card_preview.dart';

class TeamLaborScreen extends ConsumerStatefulWidget {
  const TeamLaborScreen({super.key});

  @override
  ConsumerState<TeamLaborScreen> createState() => _TeamLaborScreenState();
}

class _TeamLaborScreenState extends ConsumerState<TeamLaborScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formatter = NumberFormat('#,###');
  String _selectedCategory = 'All';
  String? selectedSupervisor;
  final Map<String, bool> _visiblePasswords = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _generateStrongPassword({int length = 12}) {
    const chars = 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#%&*';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  // ==================== DYNAMIC ROLE MODAL ====================
  void _showAddRoleDialog(BuildContext context) {
    final roleCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16264C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.add_moderator_rounded, color: AppColors.darkPrimaryGold),
              SizedBox(width: 10),
              Text('Create New Role', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: TextField(
            controller: roleCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Role Title (e.g. Broiler Specialist)',
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
                final text = roleCtrl.text.trim();
                if (text.isEmpty) return;

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    backgroundColor: const Color(0xFF16264C),
                    title: const Text('Confirm Role Creation', style: TextStyle(color: Colors.white)),
                    content: Text('Add "$text" to the farm roles registry?', style: const TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                      ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('CONFIRM')),
                    ],
                  ),
                );

                if (confirm != true) return;

                final db = ref.read(databaseServiceProvider);
                await db.addRole(text);

                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Role "$text" added successfully!'), backgroundColor: AppColors.darkGreen),
                  );
                }
              },
              child: const Text('SAVE ROLE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ==================== ADD WORKER MODAL ====================
  void _showAddWorkerDialog(BuildContext context, int currentWorkerCount, List<LaborGroup> existingGroups, List<String> availableRoles) {
    final nextId = 'WF-EMP-${(currentWorkerCount + 1).toString().padLeft(3, '0')}';
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController(text: '28');
    final nicCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final salaryCtrl = TextEditingController(text: '60000');
    final passwordCtrl = TextEditingController(text: _generateStrongPassword());
    final uniqueRoles = availableRoles.toSet().toList();
    if (uniqueRoles.isEmpty) uniqueRoles.add('Collector');
    String role = uniqueRoles.first;
    String? selectedGroupId;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final uniqueGroups = <String, LaborGroup>{};
            for (final g in existingGroups) {
              uniqueGroups[g.id] = g;
            }
            final groupList = uniqueGroups.values.toList();
            final validGroupId = groupList.any((g) => g.id == selectedGroupId) ? selectedGroupId : null;

            return AlertDialog(
              backgroundColor: const Color(0xFF16264C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.person_add_alt_1_rounded, color: AppColors.darkPrimaryGold),
                  const SizedBox(width: 10),
                  Text('Add Worker ($nextId)', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        labelStyle: TextStyle(color: Colors.white70),
                        fillColor: Color(0xFF0B1B3D),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ageCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Age',
                              labelStyle: TextStyle(color: Colors.white70),
                              fillColor: Color(0xFF0B1B3D),
                              filled: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: nicCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'NIC Number',
                              labelStyle: TextStyle(color: Colors.white70),
                              fillColor: Color(0xFF0B1B3D),
                              filled: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: TextStyle(color: Colors.white70),
                        fillColor: Color(0xFF0B1B3D),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Role Selector with + Add Role button
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: uniqueRoles.contains(role) ? role : uniqueRoles.first,
                            dropdownColor: const Color(0xFF0B1B3D),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Role / Designation',
                              labelStyle: TextStyle(color: Colors.white70),
                              fillColor: Color(0xFF0B1B3D),
                              filled: true,
                            ),
                            items: uniqueRoles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => role = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.darkPrimaryGold,
                            foregroundColor: const Color(0xFF0B1B3D),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.add, size: 20),
                          tooltip: 'Add New Role',
                          onPressed: () => _showAddRoleDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: salaryCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Monthly Salary (Rs.)',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixText: 'Rs. ',
                        prefixStyle: TextStyle(color: AppColors.darkPrimaryGold, fontWeight: FontWeight.bold),
                        fillColor: Color(0xFF0B1B3D),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Initial Provisioning Password Field
                    TextField(
                      controller: passwordCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Initial Password (Provisioned)',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.vpn_key_outlined, color: AppColors.darkPrimaryGold),
                        fillColor: Color(0xFF0B1B3D),
                        filled: true,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: AppColors.darkPrimaryGold, visualDensity: VisualDensity.compact),
                        icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                        label: const Text('Suggest Strong Password', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          passwordCtrl.text = _generateStrongPassword();
                          setDialogState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 6),

                    DropdownButtonFormField<String?>(
                      value: validGroupId,
                      dropdownColor: const Color(0xFF0B1B3D),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Assign Group (Optional)',
                        labelStyle: TextStyle(color: Colors.white70),
                        fillColor: Color(0xFF0B1B3D),
                        filled: true,
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Unassigned / Independent', style: TextStyle(color: Colors.white70)),
                        ),
                        ...groupList.map(
                          (g) => DropdownMenuItem<String?>(
                            value: g.id,
                            child: Text(g.name, style: const TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setDialogState(() => selectedGroupId = val);
                      },
                    ),
                  ],
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
                    if (nameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter worker name'), backgroundColor: AppColors.darkRed),
                      );
                      return;
                    }

                    final nicText = nicCtrl.text.trim();
                    if (nicText.isNotEmpty) {
                      final nicRegex = RegExp(r'^(?:[0-9]{9}[vVxX]|[0-9]{12})$');
                      if (!nicRegex.hasMatch(nicText)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid Sri Lankan NIC (9 digits+V/X or 12 digits)'),
                            backgroundColor: AppColors.darkRed,
                          ),
                        );
                        return;
                      }
                    }

                    final phoneText = phoneCtrl.text.trim().replaceAll(' ', '');
                    if (phoneText.isNotEmpty) {
                      final phoneRegex = RegExp(r'^(?:0\d{9}|\+94\d{9})$');
                      if (!phoneRegex.hasMatch(phoneText)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid Sri Lankan phone number (e.g. 0771234567 or +94771234567)'),
                            backgroundColor: AppColors.darkRed,
                          ),
                        );
                        return;
                      }
                    }

                    // Global Confirmation Alert
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: const Color(0xFF16264C),
                        title: const Text('Confirm Worker Registration', style: TextStyle(color: Colors.white)),
                        content: Text('Register ${nameCtrl.text.trim()} as $role ($nextId) in Firestore?', style: const TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('CONFIRM')),
                        ],
                      ),
                    );

                    if (confirm != true) return;

                    final salary = double.tryParse(salaryCtrl.text) ?? 50000.0;
                    final age = int.tryParse(ageCtrl.text) ?? 25;
                    final password = passwordCtrl.text.trim();

                    String? assignedGroupName;
                    if (selectedGroupId != null) {
                      final match = existingGroups.where((g) => g.id == selectedGroupId).firstOrNull;
                      assignedGroupName = match?.name;
                    }

                    // Structured full-detail payload
                    final fullPayload = jsonEncode({
                      'workerId': nextId,
                      'name': nameCtrl.text.trim(),
                      'nic': nicCtrl.text.trim(),
                      'role': role,
                      'phone': phoneCtrl.text.trim(),
                      'groupName': assignedGroupName ?? 'None',
                      'monthlySalary': salary,
                      'joinedDate': DateTime.now().toIso8601String().substring(0, 10),
                    });

                    final newWorker = Worker(
                      workerId: nextId,
                      name: nameCtrl.text.trim(),
                      age: age,
                      nic: nicCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      role: role,
                      monthlySalary: salary,
                      groupId: selectedGroupId,
                      groupName: assignedGroupName,
                      qrPayload: fullPayload,
                      visiblePassword: password.isNotEmpty ? password : null,
                      hasChangedPassword: false, // State 1: Newly created, visible to admin
                      joinedDate: DateTime.now(),
                    );

                    final db = ref.read(databaseServiceProvider);
                    await db.addWorker(newWorker);

                    if (selectedGroupId != null && assignedGroupName != null) {
                      await db.assignWorkerToGroup(
                        workerId: nextId,
                        groupId: selectedGroupId!,
                        groupName: assignedGroupName,
                      );
                    }

                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Registered $role: ${newWorker.name} ($nextId)'),
                          backgroundColor: AppColors.darkGreen,
                        ),
                      );
                    }
                  },
                  child: const Text('ADD WORKER', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== CREATE LABOR GROUP MODAL (WITH SUPERVISOR SELECTOR) ====================
  void _showCreateGroupDialog(BuildContext context, List<Worker> allWorkers) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    // Deduplicate workers by workerId
    final uniqueWorkers = <String, Worker>{};
    for (final w in allWorkers) {
      uniqueWorkers[w.workerId] = w;
    }
    final workerList = uniqueWorkers.values.toList();

    String? selectedSupervisorId;

    if (workerList.isNotEmpty) {
      selectedSupervisorId = workerList.first.workerId;
      selectedSupervisor = workerList.first.name;
    } else {
      selectedSupervisorId = 'admin';
      selectedSupervisor = 'Farm Admin';
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF16264C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.group_add_rounded, color: AppColors.darkPrimaryGold),
                  SizedBox(width: 10),
                  Text('Create Labor Group', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Group Name *',
                        hintText: 'e.g. Morning Egg Harvesting Unit',
                        labelStyle: TextStyle(color: Colors.white70),
                        fillColor: Color(0xFF0B1B3D),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Supervisor Selector from existing workers in Firestore
                    DropdownButtonFormField<String>(
                      value: selectedSupervisorId,
                      dropdownColor: const Color(0xFF0B1B3D),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Supervisor / Lead *',
                        labelStyle: TextStyle(color: Colors.white70),
                        fillColor: Color(0xFF0B1B3D),
                        filled: true,
                      ),
                      items: workerList.isEmpty
                          ? [const DropdownMenuItem(value: 'admin', child: Text('Farm Admin'))]
                          : workerList.map((w) {
                              return DropdownMenuItem(
                                value: w.workerId,
                                child: Text('${w.name} — ${w.role}', overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedSupervisorId = val;
                            final matched = workerList.where((w) => w.workerId == val).toList();
                            selectedSupervisor = matched.isNotEmpty ? matched.first.name : 'Farm Admin';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Description / Responsibilities',
                        labelStyle: TextStyle(color: Colors.white70),
                        fillColor: Color(0xFF0B1B3D),
                        filled: true,
                      ),
                    ),
                  ],
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
                    if (nameCtrl.text.trim().isEmpty || selectedSupervisor == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter Group Name and select a Supervisor')),
                      );
                      return;
                    }

                    // Global Confirmation Alert
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: const Color(0xFF16264C),
                        title: const Text('Confirm Group Creation', style: TextStyle(color: Colors.white)),
                        content: Text('Create labor group "${nameCtrl.text.trim()}" supervised by $selectedSupervisor?', style: const TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('CONFIRM')),
                        ],
                      ),
                    );

                    if (confirm != true) return;

                    final groupId = 'GRP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                    final newGroup = LaborGroup(
                      id: groupId,
                      name: nameCtrl.text.trim(),
                      supervisor: selectedSupervisor!,
                      description: descCtrl.text.trim(),
                      memberWorkerIds: [],
                    );

                    final db = ref.read(databaseServiceProvider);
                    await db.createLaborGroup(newGroup);

                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Created Labor Group "${newGroup.name}"'),
                          backgroundColor: AppColors.darkGreen,
                        ),
                      );
                    }
                  },
                  child: const Text('CREATE GROUP', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== ASSIGN WORKER TO GROUP DIALOG ====================
  void _showAssignWorkerDialog(BuildContext context, LaborGroup group, List<Worker> allWorkers) {
    final eligibleWorkers = allWorkers.where((w) => !group.memberWorkerIds.contains(w.workerId)).toList();
    final uniqueEligible = <String, Worker>{};
    for (final w in eligibleWorkers) {
      uniqueEligible[w.workerId] = w;
    }
    final eligibleList = uniqueEligible.values.toList();

    if (eligibleList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All registered workers are already assigned to this group!')),
      );
      return;
    }

    String selectedWorkerId = eligibleList.first.workerId;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final validSelectedId = eligibleList.any((w) => w.workerId == selectedWorkerId)
                ? selectedWorkerId
                : eligibleList.first.workerId;

            return AlertDialog(
              backgroundColor: const Color(0xFF16264C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.person_add_rounded, color: AppColors.darkPrimaryGold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Assign to ${group.name}',
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select worker to assign to this team:', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: validSelectedId,
                    dropdownColor: const Color(0xFF0B1B3D),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Worker',
                      labelStyle: TextStyle(color: Colors.white70),
                      fillColor: Color(0xFF0B1B3D),
                      filled: true,
                    ),
                    items: eligibleList.map((w) {
                      return DropdownMenuItem(
                        value: w.workerId,
                        child: Text('${w.name} (${w.role})', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedWorkerId = val);
                    },
                  ),
                ],
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
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: const Color(0xFF16264C),
                        title: const Text('Confirm Assignment', style: TextStyle(color: Colors.white)),
                        content: Text('Assign selected worker to "${group.name}"?', style: const TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('CONFIRM')),
                        ],
                      ),
                    );

                    if (confirm != true) return;

                    final db = ref.read(databaseServiceProvider);
                    await db.assignWorkerToGroup(
                      workerId: selectedWorkerId,
                      groupId: group.id,
                      groupName: group.name,
                    );

                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Worker assigned to "${group.name}"'),
                          backgroundColor: AppColors.darkGreen,
                        ),
                      );
                    }
                  },
                  child: const Text('ASSIGN', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== ADMIN RESET WORKER PASSWORD DIALOG ====================
  void _showResetWorkerPasswordDialog(BuildContext context, Worker worker) {
    final newPasswordCtrl = TextEditingController(text: _generateStrongPassword());
    final confirmPasswordCtrl = TextEditingController(text: newPasswordCtrl.text);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF16264C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.lock_reset_rounded, color: AppColors.darkPrimaryGold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Reset Password (${worker.name})', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Admin reset: Current password is NOT required.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: newPasswordCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'New Password *',
                      labelStyle: TextStyle(color: Colors.white70),
                      fillColor: Color(0xFF0B1B3D),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmPasswordCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password *',
                      labelStyle: TextStyle(color: Colors.white70),
                      fillColor: Color(0xFF0B1B3D),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: AppColors.darkPrimaryGold),
                      icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                      label: const Text('Suggest Strong Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        final p = _generateStrongPassword();
                        newPasswordCtrl.text = p;
                        confirmPasswordCtrl.text = p;
                        setDialogState(() {});
                      },
                    ),
                  ),
                ],
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
                    if (newPasswordCtrl.text.trim().isEmpty || newPasswordCtrl.text != confirmPasswordCtrl.text) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords must match!')));
                      return;
                    }

                    // Confirmation alert
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: const Color(0xFF16264C),
                        title: const Text('Confirm Password Reset', style: TextStyle(color: Colors.white)),
                        content: Text('Reset password for ${worker.name}? The new password will remain visible to the admin until the worker changes it.', style: const TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('CONFIRM')),
                        ],
                      ),
                    );

                    if (confirm != true) return;

                    final db = ref.read(databaseServiceProvider);
                    await db.updateWorkerPassword(
                      workerId: worker.workerId,
                      newPassword: newPasswordCtrl.text.trim(),
                      isAdminReset: true,
                    );

                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Password updated for ${worker.name} (Visible to admin)'), backgroundColor: AppColors.darkGreen),
                      );
                    }
                  },
                  child: const Text('SAVE PASSWORD', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== PRINTABLE LANYARD ID CARD GENERATOR MODAL ====================
  void _showLanyardIdCardDialog(BuildContext context, Worker worker) {
    WorkerIdCardDialog.show(context, worker);
  }

  // ==================== QR PASSPORT DIALOG (WITH SHARING) ====================
  void _showQrPassport(BuildContext context, Worker worker) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16264C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            '${worker.name} — Full-Detail QR Passport',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: worker.qrPayload,
                  version: QrVersions.auto,
                  size: 190.0,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'ID: ${worker.workerId}',
                style: const TextStyle(color: AppColors.darkPrimaryGold, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text('Role: ${worker.role}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
              if (worker.nic.isNotEmpty)
                Text('NIC: ${worker.nic}', style: const TextStyle(color: Colors.white60, fontSize: 13)),
              if (worker.groupName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Team: ${worker.groupName}', style: const TextStyle(color: AppColors.darkPrimaryGold, fontSize: 13)),
                ),
            ],
          ),
          actions: [
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkPrimaryGold,
                      foregroundColor: const Color(0xFF0B1B3D),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      WorkerIdCardDialog.show(context, worker);
                    },
                    icon: const Icon(Icons.badge_rounded, size: 18),
                    label: const Text('GENERATE FULL ID CARD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: worker.qrPayload));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('QR payload copied to clipboard!'), backgroundColor: AppColors.darkGreen),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('COPY PAYLOAD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close', style: TextStyle(color: Colors.white60)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ==================== CONFIRM DELETE WORKER ====================
  void _confirmDeleteWorker(BuildContext context, Worker worker) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16264C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.darkRed, size: 28),
              SizedBox(width: 10),
              Text('Delete Laborer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to permanently delete "${worker.name}" (${worker.workerId})?',
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'This will remove their profile, unassign them from any teams, and cannot be undone.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkRed,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final db = ref.read(databaseServiceProvider);
                await db.deleteWorker(worker.workerId);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Deleted worker: ${worker.name}'),
                      backgroundColor: AppColors.darkRed,
                    ),
                  );
                }
              },
              child: const Text('DELETE WORKER', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ==================== CONFIRM DELETE GROUP ====================
  void _confirmDeleteGroup(BuildContext context, LaborGroup group) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16264C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.darkRed, size: 28),
              SizedBox(width: 10),
              Text('Delete Labor Group', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "${group.name}"?',
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                'All ${group.memberWorkerIds.length} assigned worker(s) will become unassigned. This action cannot be undone.',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkRed,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final db = ref.read(databaseServiceProvider);
                await db.deleteLaborGroup(group.id);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Deleted group "${group.name}"'),
                      backgroundColor: AppColors.darkRed,
                    ),
                  );
                }
              },
              child: const Text('DELETE GROUP', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ==================== CONFIRM PAY SALARY ====================
  void _confirmPaySalary(BuildContext context, Worker worker) {
    final currentMonthYear = DateFormat('MMMM yyyy').format(DateTime.now());

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16264C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.payments_rounded, color: AppColors.darkPrimaryGold),
              SizedBox(width: 10),
              Text('Execute Payroll', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Confirm salary payment for: ${worker.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Worker ID: ${worker.workerId}', style: const TextStyle(color: Colors.white70)),
              Text('Role: ${worker.role}', style: const TextStyle(color: Colors.white70)),
              Text('Month: $currentMonthYear', style: const TextStyle(color: AppColors.darkPrimaryGold, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1B3D),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Net Salary:', style: TextStyle(color: Colors.white70)),
                    Text(
                      'Rs. ${_formatter.format(worker.monthlySalary.toInt())}',
                      style: const TextStyle(color: Color(0xFF22C55E), fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () async {
                final db = ref.read(databaseServiceProvider);
                await db.paySalary(worker: worker, monthYear: currentMonthYear);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Paid Rs. ${_formatter.format(worker.monthlySalary.toInt())} to ${worker.name} ($currentMonthYear)'),
                      backgroundColor: AppColors.darkGreen,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E), foregroundColor: Colors.white),
              child: const Text('CONFIRM PAYMENT', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(workersStreamProvider);
    final groupsAsync = ref.watch(laborGroupsStreamProvider);
    final rolesAsync = ref.watch(rolesStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final workers = workersAsync.value ?? [];
    final groups = groupsAsync.value ?? [];
    final roles = rolesAsync.value ?? ['Manager', 'Supervisor', 'Collector', 'Driver'];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackgroundWarm,
      appBar: AppBar(
        title: const Text('Team & Labor (HR & Payroll)', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.darkPrimaryGold,
          indicatorWeight: 3,
          labelColor: AppColors.darkPrimaryGold,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(
              icon: const Icon(Icons.people_alt_rounded),
              text: 'All Labors (${workers.length})',
            ),
            Tab(
              icon: const Icon(Icons.workspaces_rounded),
              text: 'Groups / Teams (${groups.length})',
            ),
          ],
        ),
        actions: const [],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddWorkerDialog(context, workers.length, groups, roles);
          } else {
            _showCreateGroupDialog(context, workers);
          }
        },
        backgroundColor: AppColors.darkPrimaryGold,
        foregroundColor: const Color(0xFF0B1B3D),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: Text(
          _tabController.index == 0 ? 'Add Laborer' : 'Create Group',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ==================== TAB 1: ALL LABORS ====================
          _buildAllLaborsView(context, workersAsync, groups, roles, isDark),

          // ==================== TAB 2: GROUPS / TEAMS ====================
          _buildGroupsView(context, groupsAsync, workers, isDark),
        ],
      ),
    );
  }

  // ==================== ALL LABORS VIEW ====================
  Widget _buildAllLaborsView(
    BuildContext context,
    AsyncValue<List<Worker>> workersAsync,
    List<LaborGroup> groups,
    List<String> roles,
    bool isDark,
  ) {
    return workersAsync.when(
      data: (workers) {
        if (workers.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.darkPrimaryGold.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.people_outline_rounded, size: 64, color: AppColors.darkPrimaryGold),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No Workers Registered',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start by adding farm laborers, collectors, supervisors, and drivers to manage payroll and teams.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkPrimaryGold,
                      foregroundColor: const Color(0xFF0B1B3D),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('ADD FIRST LABORER', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _showAddWorkerDialog(context, 0, groups, roles),
                  ),
                ],
              ),
            ),
          );
        }

        // Filter workers by dynamic category
        final filteredWorkers = _selectedCategory == 'All'
            ? workers
            : workers.where((w) => w.role.toLowerCase() == _selectedCategory.toLowerCase()).toList();

        final filterCategories = ['All', ...roles];

        return Column(
          children: [
            // Dynamic Horizontal Labor Category Chips
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filterCategories.map((cat) {
                    final isSel = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: isSel,
                        onSelected: (selected) {
                          setState(() => _selectedCategory = cat);
                        },
                        selectedColor: AppColors.darkPrimaryGold,
                        labelStyle: TextStyle(
                          color: isSel ? const Color(0xFF0B1B3D) : Colors.white,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                        backgroundColor: const Color(0xFF16264C),
                        checkmarkColor: const Color(0xFF0B1B3D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: isSel ? AppColors.darkPrimaryGold : Colors.white24),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Workers List
            Expanded(
              child: filteredWorkers.isEmpty
                  ? Center(
                      child: Text('No workers found under "$_selectedCategory"', style: const TextStyle(color: Colors.white70)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: filteredWorkers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, idx) {
                        final w = filteredWorkers[idx];
                        final currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());
                        final isPaidThisMonth = w.lastPaidMonth == currentMonth;
                        final isPasswordVisible = _visiblePasswords[w.workerId] ?? false;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCardSurface : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row 1: Avatar, Name, Salary, Actions
                              Row(
                                children: [
                                  // Worker Initials Avatar
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0B1B3D),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.darkPrimaryGold.withOpacity(0.5), width: 1.5),
                                    ),
                                    child: Center(
                                      child: Text(
                                        w.name.isNotEmpty ? w.name[0].toUpperCase() : 'W',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkPrimaryGold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Info Block
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(w.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                                        const SizedBox(height: 2),
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 6,
                                          children: [
                                            Text('${w.workerId} • ${w.role}', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                                            if (w.groupName != null && w.groupName!.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.darkPrimaryGold.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: AppColors.darkPrimaryGold.withOpacity(0.4), width: 0.8),
                                                ),
                                                child: Text(
                                                  w.groupName!,
                                                  style: const TextStyle(fontSize: 10, color: AppColors.darkPrimaryGold, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Salary: Rs. ${_formatter.format(w.monthlySalary.toInt())}/mo',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkPrimaryGold),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Pay Button
                                  ElevatedButton(
                                    onPressed: isPaidThisMonth ? null : () => _confirmPaySalary(context, w),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isPaidThisMonth ? const Color(0xFF334155) : const Color(0xFF22C55E),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: const Size(54, 32),
                                    ),
                                    child: Text(isPaidThisMonth ? 'PAID' : 'PAY', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),

                                  // Delete Worker Button
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.darkRed, size: 20),
                                    tooltip: 'Delete Worker',
                                    onPressed: () => _confirmDeleteWorker(context, w),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),
                              const Divider(color: Colors.white12, height: 12),

                              // Row 2: Password Visibility Lifecycle & Quick Actions
                              Row(
                                children: [
                                  // Password State
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                                        const SizedBox(width: 4),
                                        if (w.hasChangedPassword)
                                          const Text('Password: Hidden (Updated by user)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontStyle: FontStyle.italic))
                                        else if (w.visiblePassword != null && w.visiblePassword!.isNotEmpty) ...[
                                          Text(
                                            isPasswordVisible ? 'Pass: ${w.visiblePassword!}' : 'Pass: ••••••••',
                                            style: const TextStyle(color: AppColors.darkPrimaryGold, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                          IconButton(
                                            icon: Icon(isPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 16, color: AppColors.darkPrimaryGold),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              setState(() {
                                                _visiblePasswords[w.workerId] = !isPasswordVisible;
                                              });
                                            },
                                          ),
                                        ] else
                                          const Text('Pass: Set on provision', style: TextStyle(color: Colors.white60, fontSize: 11)),
                                      ],
                                    ),
                                  ),

                                  // Reset Password Button
                                  IconButton(
                                    icon: const Icon(Icons.key_rounded, size: 18, color: AppColors.darkPrimaryGold),
                                    tooltip: 'Reset Password',
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _showResetWorkerPasswordDialog(context, w),
                                  ),
                                  const SizedBox(width: 8),

                                  // Generate Printable ID Card Button
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0B1B3D),
                                      foregroundColor: AppColors.darkPrimaryGold,
                                      side: const BorderSide(color: AppColors.darkPrimaryGold, width: 1),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: const Size(110, 32),
                                    ),
                                    icon: const Icon(Icons.badge_rounded, size: 14),
                                    label: const Text('Generate ID Card', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                    onPressed: () => WorkerIdCardDialog.show(context, w),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.darkPrimaryGold)),
      error: (err, _) => Center(child: Text('Error loading workers: $err', style: const TextStyle(color: Colors.white))),
    );
  }

  // ==================== GROUPS / TEAMS VIEW ====================
  Widget _buildGroupsView(
    BuildContext context,
    AsyncValue<List<LaborGroup>> groupsAsync,
    List<Worker> allWorkers,
    bool isDark,
  ) {
    return groupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.darkPrimaryGold.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspaces_outline, size: 64, color: AppColors.darkPrimaryGold),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No Labor Groups Created',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Organize farm workers into shifts, shed cleaning teams, or egg collection units with supervisors.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkPrimaryGold,
                      foregroundColor: const Color(0xFF0B1B3D),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.group_add_rounded),
                    label: const Text('CREATE FIRST GROUP', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _showCreateGroupDialog(context, allWorkers),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (ctx, idx) {
            final group = groups[idx];
            final groupMembers = allWorkers.where((w) => group.memberWorkerIds.contains(w.workerId)).toList();

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Header Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1B3D),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.darkPrimaryGold.withOpacity(0.4)),
                        ),
                        child: const Icon(Icons.diversity_3_rounded, color: AppColors.darkPrimaryGold, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(group.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 2),
                            Text(
                              'Lead: ${group.supervisor}',
                              style: const TextStyle(fontSize: 12, color: AppColors.darkPrimaryGold, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      // Member Count Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1B3D),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          '${group.memberWorkerIds.length} Members',
                          style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Delete Group Button
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.darkRed, size: 22),
                        tooltip: 'Delete Group',
                        onPressed: () => _confirmDeleteGroup(context, group),
                      ),
                    ],
                  ),

                  // Description (if available)
                  if (group.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      group.description,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ],

                  const Divider(color: Color(0xFF1E293B), height: 24),

                  // Assigned Members Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Assigned Laborers',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.darkPrimaryGold,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.person_add_rounded, size: 16),
                        label: const Text('+ Assign Labor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => _showAssignWorkerDialog(context, group, allWorkers),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (groupMembers.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1B3D).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Center(
                        child: Text(
                          'No laborers assigned to this team yet.',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: groupMembers.map((member) {
                        return Container(
                          padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1B3D),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.darkPrimaryGold.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${member.name} (${member.role})',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      backgroundColor: const Color(0xFF16264C),
                                      title: const Text('Confirm Removal', style: TextStyle(color: Colors.white)),
                                      content: Text('Remove ${member.name} from "${group.name}"?', style: const TextStyle(color: Colors.white70)),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                        ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('CONFIRM')),
                                      ],
                                    ),
                                  );

                                  if (confirm != true) return;

                                  final db = ref.read(databaseServiceProvider);
                                  await db.removeWorkerFromGroup(
                                    workerId: member.workerId,
                                    groupId: group.id,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Removed ${member.name} from "${group.name}"'),
                                        backgroundColor: AppColors.darkRed,
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.white12,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.darkPrimaryGold)),
      error: (err, _) => Center(child: Text('Error loading groups: $err', style: const TextStyle(color: Colors.white))),
    );
  }
}
