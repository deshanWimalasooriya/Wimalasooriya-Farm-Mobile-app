import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_assets.dart';
import '../core/theme/app_colors.dart';
import '../models/farm_models.dart';
import '../providers/farm_providers.dart';
import '../utils/app_snackbar.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenNotifications;

  const FinanceScreen({super.key, required this.onOpenNotifications});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  int _selectedSubTab = 0; // 0: Eggs, 1: Salary Payments, 2: Maintenance, 3: Food & Med
  final List<String> _subTabs = ['Eggs', 'Salary Payments', 'Maintenance', 'Food & Meds'];

  // 1. Eggs Sub-Tab State (1-by-1 stepper)
  int _soldEggs = 100;
  final TextEditingController _soldEggsController = TextEditingController(text: '100');

  // 2. Salary Payments Sub-Tab State
  Worker? _selectedWorker;
  final TextEditingController _salaryAmountController = TextEditingController();
  final TextEditingController _salaryNoteController = TextEditingController();

  // 3. Maintenance Sub-Tab State
  String _maintenanceMode = 'Vehicle Maintenance'; // 'Vehicle Maintenance' or 'Factory Maintenance'
  Vehicle? _selectedMaintVehicle;
  String? _selectedMaintDriverName;
  String? _selectedMaintDriverId;
  String _maintType = 'General Service';
  final TextEditingController _maintTitleController = TextEditingController();
  final TextEditingController _maintCostController = TextEditingController();
  final TextEditingController _maintNoteController = TextEditingController();
  final TextEditingController _maintOdometerController = TextEditingController();

  // 4. Food & Meds Sub-Tab State
  String _foodMedType = 'Feed'; // 'Feed' or 'Medicine'
  String? _selectedCatalogItem;
  final TextEditingController _foodMedNameController = TextEditingController();
  final TextEditingController _foodMedQtyController = TextEditingController(text: '1');
  final TextEditingController _foodMedCostController = TextEditingController();

  @override
  void dispose() {
    _soldEggsController.dispose();
    _salaryAmountController.dispose();
    _salaryNoteController.dispose();
    _maintTitleController.dispose();
    _maintCostController.dispose();
    _maintNoteController.dispose();
    _maintOdometerController.dispose();
    _foodMedNameController.dispose();
    _foodMedQtyController.dispose();
    _foodMedCostController.dispose();
    super.dispose();
  }

  void _updateEggs(int count) {
    setState(() {
      _soldEggs = count.clamp(0, 10000000);
      _soldEggsController.text = _soldEggs.toString();
    });
  }

  void _showEditUnitEggPriceDialog(BuildContext context, double currentPrice) {
    final priceController = TextEditingController(text: currentPrice.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16264C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: AppColors.darkPrimaryGold),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Edit Unit Egg Price',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          content: TextField(
            controller: priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            decoration: const InputDecoration(
              labelText: 'Price per 1 Egg (Rs.)',
              prefixText: 'Rs. ',
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
                final newPrice = double.tryParse(priceController.text) ?? currentPrice;
                if (newPrice > 0) {
                  final db = ref.read(databaseServiceProvider);
                  await db.updateUnitEggPrice(newPrice);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    AppSnackBar.showSuccess(
                      context,
                      'Updated Unit Egg Price to Rs. ${newPrice.toStringAsFixed(2)}',
                    );
                  }
                }
              },
              child: const Text('UPDATE PRICE'),
            ),
          ],
        );
      },
    );
  }

  // ==================== CONFIRMATION ALERT HELPER ====================
  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    Color confirmColor = AppColors.darkPrimaryGold,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1E36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E293B)),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          content,
          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: confirmColor == AppColors.darkPrimaryGold ? const Color(0xFF0B1B3D) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  double _getCurrentSystemBalance() {
    final transactions = ref.read(transactionsStreamProvider).value ?? [];
    final totalIncome = transactions
        .where((t) => t.type == 'income')
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    final totalExpense = transactions
        .where((t) => t.type == 'expense')
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    return totalIncome - totalExpense;
  }

  Future<void> _showInsufficientFundsDialog(double requestedAmount, double currentBalance) async {
    final formatter = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16264C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: Color(0xFFEF4444)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Insufficient Funds',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        content: Text(
          'Insufficient Funds in System.\n'
          'Current balance: ${formatter.format(currentBalance)}\n'
          'Requested: ${formatter.format(requestedAmount)}\n\n'
          'Expenses cannot exceed available balance.',
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkPrimaryGold,
              foregroundColor: const Color(0xFF0B1B3D),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _recordEggTransaction(double unitPrice) async {
    final db = ref.read(databaseServiceProvider);
    if (_soldEggs <= 0) return;

    final metrics = ref.read(farmMetricsStreamProvider).value;
    final availableEggs = metrics?.todayEggCount ?? 0;
    if (_soldEggs > availableEggs) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Cannot sell $_soldEggs eggs. Available stock is only $availableEggs eggs.',
        );
      }
      return;
    }

    final total = _soldEggs * unitPrice;
    final confirmed = await _showConfirmationDialog(
      title: 'Confirm Egg Sale',
      content: 'Record sale of $_soldEggs eggs at Rs. ${unitPrice.toStringAsFixed(2)} each?\nTotal Income: +Rs. ${NumberFormat('#,###.00').format(total)}',
      confirmText: 'RECORD SALE',
      confirmColor: const Color(0xFF22C55E),
    );

    if (!confirmed) return;

    try {
      await db.recordEggSale(
        count: _soldEggs,
        unitPrice: unitPrice,
        loggedBy: 'Deshan Wimalasooriya',
      );
      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          'Recorded Egg Sale: $_soldEggs eggs (+Rs. ${NumberFormat('#,###.00').format(total)})',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Notice: $e');
      }
    }
  }

  Future<bool> _promptAdminPasswordConfirmation(BuildContext context) async {
    final passwordCtrl = TextEditingController();
    bool isAuthenticating = false;
    String? errorMsg;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF16264C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: AppColors.darkPrimaryGold),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Admin Authentication',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Re-enter your admin password to authorize this salary disbursement.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Admin Password',
                      labelStyle: const TextStyle(color: Colors.white70),
                      fillColor: const Color(0xFF0B1B3D),
                      filled: true,
                      prefixIcon: const Icon(Icons.key_rounded, color: AppColors.darkPrimaryGold),
                      errorText: errorMsg,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isAuthenticating ? null : () => Navigator.pop(ctx, false),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkPrimaryGold,
                    foregroundColor: const Color(0xFF0B1B3D),
                  ),
                  onPressed: isAuthenticating
                      ? null
                      : () async {
                          final pass = passwordCtrl.text.trim();
                          if (pass.isEmpty) {
                            setDialogState(() => errorMsg = 'Password cannot be empty');
                            return;
                          }
                          setDialogState(() {
                            isAuthenticating = true;
                            errorMsg = null;
                          });

                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null && user.email != null) {
                              final cred = EmailAuthProvider.credential(
                                email: user.email!,
                                password: pass,
                              );
                              await user.reauthenticateWithCredential(cred);
                              if (ctx.mounted) Navigator.pop(ctx, true);
                            } else {
                              if (pass.length >= 6) {
                                if (ctx.mounted) Navigator.pop(ctx, true);
                              } else {
                                setDialogState(() {
                                  isAuthenticating = false;
                                  errorMsg = 'Invalid credentials';
                                });
                              }
                            }
                          } catch (e) {
                            setDialogState(() {
                              isAuthenticating = false;
                              errorMsg = 'Incorrect password. Authorization failed.';
                            });
                          }
                        },
                  child: isAuthenticating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0B1B3D)),
                        )
                      : const Text('AUTHORIZE', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
    return result == true;
  }

  Future<void> _recordSalaryPayment() async {
    if (_selectedWorker == null) {
      AppSnackBar.showError(context, 'Please select a worker first');
      return;
    }
    final amount = double.tryParse(_salaryAmountController.text) ?? _selectedWorker!.monthlySalary;
    if (amount <= 0) return;

    final currentBalance = _getCurrentSystemBalance();
    if (amount > currentBalance) {
      await _showInsufficientFundsDialog(amount, currentBalance);
      return;
    }

    final currentMonthYear = DateFormat('MMMM yyyy').format(DateTime.now());
    final confirmed = await _showConfirmationDialog(
      title: 'Confirm Salary Payment',
      content: 'Pay monthly salary of Rs. ${NumberFormat('#,###.00').format(amount)} to ${_selectedWorker!.name} for $currentMonthYear?',
      confirmText: 'PROCEED TO AUTH',
      confirmColor: const Color(0xFFEF4444),
    );

    if (!confirmed) return;

    if (!mounted) return;
    final authorized = await _promptAdminPasswordConfirmation(context);
    if (!authorized) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Salary payment cancelled: Admin authentication required.',
        );
      }
      return;
    }

    final db = ref.read(databaseServiceProvider);
    await db.recordSalaryPayment(
      workerId: _selectedWorker!.workerId,
      workerName: _selectedWorker!.name,
      amount: amount,
      monthYear: currentMonthYear,
      note: _salaryNoteController.text.trim(),
    );

    _salaryNoteController.clear();
    setState(() => _selectedWorker = null);

    if (mounted) {
      AppSnackBar.showSuccess(
        context,
        'Salary payment authorized and recorded for ${_selectedWorker?.name ?? "worker"}',
      );
    }
  }

  Future<void> _recordMaintenance() async {
    final cost = double.tryParse(_maintCostController.text) ?? 0.0;
    if (cost <= 0) {
      AppSnackBar.showError(context, 'Please enter a valid expense cost');
      return;
    }

    final currentBalance = _getCurrentSystemBalance();
    if (cost > currentBalance) {
      await _showInsufficientFundsDialog(cost, currentBalance);
      return;
    }

    final isVehicle = _maintenanceMode == 'Vehicle Maintenance';
    if (isVehicle && _selectedMaintVehicle == null) {
      AppSnackBar.showError(context, 'Please select a vehicle for vehicle maintenance');
      return;
    }

    final customDesc = _maintTitleController.text.trim();
    if (!isVehicle && customDesc.isEmpty) {
      AppSnackBar.showError(context, 'Please enter maintenance title or equipment name');
      return;
    }

    final vehicleReg = isVehicle ? _selectedMaintVehicle!.regNumber : '';
    final vehicleId = isVehicle ? _selectedMaintVehicle!.vehicleId : '';
    final type = isVehicle ? _maintType : 'Factory Maintenance';
    final description = isVehicle
        ? (customDesc.isNotEmpty ? customDesc : type)
        : customDesc;
    final odometer = isVehicle ? int.tryParse(_maintOdometerController.text.trim()) : null;
    final driverName = isVehicle ? (_selectedMaintDriverName ?? '') : '';
    final driverId = isVehicle ? (_selectedMaintDriverId ?? '') : '';
    final note = _maintNoteController.text.trim();

    final confirmContent = isVehicle
        ? 'Record vehicle maintenance expense for $vehicleReg ($type)?\n'
            '• Description: $description\n'
            '• Driver: ${driverName.isNotEmpty ? driverName : "N/A"}\n'
            '${odometer != null ? "• Odometer: $odometer km\n" : ""}'
            '• Total Cost: Rs. ${NumberFormat('#,###.00').format(cost)}'
        : 'Record factory infrastructure maintenance expense?\n'
            '• Maintenance Title: $description\n'
            '${note.isNotEmpty ? "• Notes: $note\n" : ""}'
            '• Total Cost: Rs. ${NumberFormat('#,###.00').format(cost)}';

    final confirmed = await _showConfirmationDialog(
      title: 'Confirm Maintenance Expense',
      content: confirmContent,
      confirmText: 'RECORD EXPENSE',
      confirmColor: const Color(0xFFEF4444),
    );

    if (!confirmed) return;

    final db = ref.read(databaseServiceProvider);
    final log = VehicleMaintenanceLog(
      id: 'maint_${DateTime.now().millisecondsSinceEpoch}',
      vehicleId: vehicleId,
      regNumber: vehicleReg,
      driverId: driverId,
      driverName: driverName,
      maintenanceType: type,
      description: note.isNotEmpty ? '$description ($note)' : description,
      cost: cost,
      odometer: odometer,
    );

    await db.recordVehicleMaintenance(log: log);

    _maintTitleController.clear();
    _maintCostController.clear();
    _maintNoteController.clear();
    _maintOdometerController.clear();
    setState(() {
      _selectedMaintVehicle = null;
      _selectedMaintDriverName = null;
      _selectedMaintDriverId = null;
    });

    if (mounted) {
      AppSnackBar.showSuccess(
        context,
        isVehicle ? 'Vehicle maintenance expense recorded and synced!' : 'Factory maintenance expense recorded and synced!',
      );
    }
  }

  Future<void> _showAddCatalogItemDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCardSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add New $_foodMedType to Catalog', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Item Name',
                hintText: 'e.g. High Calcium Layer Mash',
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'e.g. Daily maintenance feed',
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ref.read(databaseServiceProvider).addCatalogItem(
                  type: _foodMedType.toLowerCase(),
                  name: name,
                  description: descCtrl.text.trim(),
                );
                setState(() {
                  _selectedCatalogItem = name;
                  _foodMedNameController.text = name;
                });
                if (mounted) {
                  AppSnackBar.showSuccess(context, 'Added "$name" to $_foodMedType catalog!');
                }
              } catch (e) {
                if (mounted) {
                  AppSnackBar.showError(context, 'Failed to add item: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkPrimaryGold,
              foregroundColor: const Color(0xFF0B1B3D),
            ),
            child: const Text('Save to Catalog', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _recordFoodMed() async {
    final name = _foodMedNameController.text.trim();
    final qty = int.tryParse(_foodMedQtyController.text) ?? 1;
    final cost = double.tryParse(_foodMedCostController.text) ?? 0.0;
    if (name.isEmpty || cost <= 0) return;

    final currentBalance = _getCurrentSystemBalance();
    if (cost > currentBalance) {
      await _showInsufficientFundsDialog(cost, currentBalance);
      return;
    }

    final confirmed = await _showConfirmationDialog(
      title: 'Confirm $_foodMedType Purchase',
      content: 'Record purchase of "$name" ($qty units)?\nTotal Cost: Rs. ${NumberFormat('#,###.00').format(cost)}',
      confirmText: 'RECORD PURCHASE',
      confirmColor: const Color(0xFFEF4444),
    );

    if (!confirmed) return;

    final db = ref.read(databaseServiceProvider);
    await db.recordFeedOrMedicine(
      type: _foodMedType.toLowerCase(),
      packetCount: _foodMedType == 'Feed' ? qty : 0,
      totalCost: cost,
      description: '$name ($qty units)',
    );

    setState(() {
      _selectedCatalogItem = null;
    });
    _foodMedNameController.clear();
    _foodMedCostController.clear();
    _foodMedQtyController.text = '1';

    if (mounted) {
      AppSnackBar.showSuccess(context, '$_foodMedType purchase recorded!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(farmMetricsStreamProvider);
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final workersAsync = ref.watch(workersStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentDateStr = DateFormat('MMMM d, y').format(DateTime.now());
    final formatter = NumberFormat('#,###');

    final unitPrice = metricsAsync.value?.unitEggPrice ?? 40.0;
    final availableEggs = metricsAsync.value?.todayEggCount ?? 0;
    final calculatedIncome = _soldEggs * unitPrice;
    final notifsAsync = ref.watch(adminNotificationsStreamProvider);
    final unreadNotifsCount = notifsAsync.value?.where((n) => !n.isRead).length ?? 0;

    // Filter transactions by selected sub-tab category
    final activeCategory = _subTabs[_selectedSubTab];
    final allTransactions = transactionsAsync.value ?? [];
    final filteredTransactions = allTransactions.where((t) {
      if (activeCategory == 'Eggs') return t.category == 'Eggs';
      if (activeCategory == 'Salary Payments') return t.category == 'Salary Payments';
      if (activeCategory == 'Maintenance') return t.category == 'Maintenance';
      return t.category == 'Food & Meds' || t.category == 'Food & Med';
    }).toList();

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
            // Screen Header
            const Text(
              'Financial Ledger',
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_subTabs.length, (idx) {
                  final isSelected = _selectedSubTab == idx;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedSubTab = idx),
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
                          _subTabs[idx],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.darkPrimaryGold : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),

            // DEDICATED FORM BASED ON SELECTED SUB-TAB
            if (_selectedSubTab == 0) ...[
              // 1. EGGS FORM (1-by-1 stepper, editable unit price, live calculation)
              _buildEggSalesCard(calculatedIncome, unitPrice, availableEggs, formatter, isDark),
            ] else if (_selectedSubTab == 1) ...[
              // 2. SALARY PAYMENTS FORM
              _buildSalaryPaymentCard(workersAsync, formatter, isDark),
            ] else if (_selectedSubTab == 2) ...[
              // 3. MAINTENANCE FORM
              _buildMaintenanceCard(isDark),
            ] else ...[
              // 4. FOOD & MEDS FORM
              _buildFoodMedsCard(isDark),
            ],
            const SizedBox(height: 20),

            // NET PROFIT OVERVIEW CARD (100% Real-Time Firestore Aggregation)
            _buildNetProfitCard(allTransactions, formatter, isDark),
            const SizedBox(height: 20),

            // RECENT TRANSACTIONS (Filtered by Active Category, Zero Dummy Data)
            _buildRecentTransactionsCard(filteredTransactions, activeCategory, formatter, isDark),
          ],
        ),
      ),
    );
  }

  // ==================== SUB-TAB FORMS ====================

  Widget _buildEggSalesCard(double calculatedIncome, double unitPrice, int availableEggs, NumberFormat formatter, bool isDark) {
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
          // Live Available Egg Stock Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: availableEggs > 0 ? AppColors.darkPrimaryGold.withOpacity(0.5) : const Color(0xFFEF4444),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (availableEggs > 0 ? AppColors.darkPrimaryGold : const Color(0xFFEF4444)).withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.egg_outlined,
                    color: availableEggs > 0 ? AppColors.darkPrimaryGold : const Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Available Egg Stock',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${formatter.format(availableEggs)} Eggs',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: availableEggs > 0
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (availableEggs > 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444)).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: availableEggs > 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    availableEggs > 0 ? 'In Stock' : 'Out of Stock',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: availableEggs > 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'EGG SALES',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Editable Unit Egg Price Badge
              InkWell(
                onTap: () => _showEditUnitEggPriceDialog(context, unitPrice),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x26D4AF37),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.darkPrimaryGold, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Unit Price: Rs. ${unitPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.darkPrimaryGold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit, size: 14, color: AppColors.darkPrimaryGold),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Enter Sold Eggs (1-by-1 Step or Direct Input)', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
          const SizedBox(height: 12),

          // Stepper (1-by-1) + Direct Input + Live Income Row
          Row(
            children: [
              _buildCircleButton(
                icon: Icons.remove,
                onTap: () {
                  if (_soldEggs > 0) _updateEggs(_soldEggs - 1);
                },
              ),
              const SizedBox(width: 8),
              Container(
                width: 90,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.darkPrimaryGold),
                ),
                child: TextField(
                  controller: _soldEggsController,
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
                    if (parsed != null) setState(() => _soldEggs = parsed);
                  },
                ),
              ),
              const SizedBox(width: 8),
              _buildCircleButton(
                icon: Icons.add,
                onTap: () {
                  _updateEggs(_soldEggs + 1);
                },
              ),
              const SizedBox(width: 14),

              // Live Auto-Calculated Income
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Calculated Income:',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Rs. ${formatter.format(calculatedIncome.toInt())}',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkPrimaryGold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // + RECORD TRANSACTION Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _recordEggTransaction(unitPrice),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC59B27),
                foregroundColor: const Color(0xFF0B1B3D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                '+ RECORD TRANSACTION',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryPaymentCard(AsyncValue<List<Worker>> workersAsync, NumberFormat formatter, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RECORD WORKER SALARY PAYMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),

          workersAsync.when(
            data: (workers) {
              if (workers.isEmpty) {
                return const Text('No workers registered yet. Add workers in Team & Labor.', style: TextStyle(color: Colors.white70));
              }
              final uniqueWorkers = <String, Worker>{};
              for (final w in workers) {
                uniqueWorkers[w.workerId] = w;
              }
              final workerList = uniqueWorkers.values.toList();
              final validWorkerId = workerList.any((w) => w.workerId == _selectedWorker?.workerId)
                  ? _selectedWorker?.workerId
                  : null;

              return DropdownButtonFormField<String>(
                value: validWorkerId,
                dropdownColor: const Color(0xFF0B1B3D),
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
                decoration: InputDecoration(
                  labelText: 'Select Registered Worker',
                  fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                ),
                items: workerList.map((w) {
                  return DropdownMenuItem(
                    value: w.workerId,
                    child: Text(
                      '${w.name} (${w.role}) — Rs. ${formatter.format(w.monthlySalary.toInt())}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (id) {
                  setState(() {
                    if (id != null) {
                      _selectedWorker = workerList.firstWhere((w) => w.workerId == id);
                      _salaryAmountController.text = _selectedWorker!.monthlySalary.toStringAsFixed(0);
                    } else {
                      _selectedWorker = null;
                    }
                  });
                },
              );
            },
            loading: () => const LinearProgressIndicator(color: AppColors.darkPrimaryGold),
            error: (err, _) => Text('Error: $err'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _salaryAmountController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
            decoration: InputDecoration(
              labelText: 'Payment Amount (Rs.)',
              prefixText: 'Rs. ',
              fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _salaryNoteController,
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
            decoration: InputDecoration(
              labelText: 'Payment Note / Overtime (Optional)',
              fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _recordSalaryPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('+ RECORD SALARY PAYMENT', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCard(bool isDark) {
    final vehiclesAsync = ref.watch(vehiclesStreamProvider);
    final workersAsync = ref.watch(workersStreamProvider);
    final vehicles = vehiclesAsync.value ?? [];
    final workers = workersAsync.value ?? [];

    // Get unique drivers list for dropdown
    final Set<String> driverSet = {};
    if (_selectedMaintVehicle != null && _selectedMaintVehicle!.assignedDriverNames.isNotEmpty) {
      driverSet.addAll(_selectedMaintVehicle!.assignedDriverNames);
    } else {
      final drivers = workers.where((w) => w.role.toLowerCase().contains('driver')).map((w) => w.name);
      driverSet.addAll(drivers);
      if (driverSet.isEmpty) {
        driverSet.addAll(workers.map((w) => w.name));
      }
    }
    final availableDrivers = driverSet.toList();
    final isVehicleMode = _maintenanceMode == 'Vehicle Maintenance';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LOG MAINTENANCE / REPAIR EXPENSE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 14),

          // Dual Maintenance Modes Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _maintenanceMode = 'Vehicle Maintenance';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isVehicleMode ? AppColors.darkPrimaryGold : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car_rounded,
                            size: 16,
                            color: isVehicleMode ? const Color(0xFF0B1B3D) : (isDark ? Colors.white70 : Colors.black87),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Vehicle Maintenance',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isVehicleMode ? const Color(0xFF0B1B3D) : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _maintenanceMode = 'Factory Maintenance';
                        _selectedMaintVehicle = null;
                        _selectedMaintDriverName = null;
                        _selectedMaintDriverId = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !isVehicleMode ? AppColors.darkPrimaryGold : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.factory_rounded,
                            size: 16,
                            color: !isVehicleMode ? const Color(0xFF0B1B3D) : (isDark ? Colors.white70 : Colors.black87),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Factory Maintenance',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: !isVehicleMode ? const Color(0xFF0B1B3D) : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (isVehicleMode) ...[
            // Vehicle Selector Dropdown
            DropdownButtonFormField<String?>(
              value: vehicles.any((v) => v.vehicleId == _selectedMaintVehicle?.vehicleId) ? _selectedMaintVehicle?.vehicleId : null,
              dropdownColor: isDark ? const Color(0xFF0B1B3D) : Colors.white,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
              decoration: InputDecoration(
                labelText: 'Select Vehicle *',
                prefixIcon: const Icon(Icons.directions_car_rounded, color: AppColors.darkPrimaryGold, size: 20),
                fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
              ),
              items: vehicles.isEmpty
                  ? [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No vehicles registered in fleet', style: TextStyle(color: Colors.white70)),
                      ),
                    ]
                  : vehicles.map((v) => DropdownMenuItem<String?>(
                        value: v.vehicleId,
                        child: Text('${v.regNumber} (${v.vehicleType})'),
                      )).toList(),
              onChanged: (val) {
                setState(() {
                  if (val == null) {
                    _selectedMaintVehicle = null;
                    _selectedMaintDriverName = null;
                    _selectedMaintDriverId = null;
                  } else {
                    final matched = vehicles.where((v) => v.vehicleId == val).toList();
                    if (matched.isNotEmpty) {
                      _selectedMaintVehicle = matched.first;
                      if (_selectedMaintVehicle!.assignedDriverNames.isNotEmpty) {
                        _selectedMaintDriverName = _selectedMaintVehicle!.assignedDriverNames.first;
                        if (_selectedMaintVehicle!.assignedDriverIds.isNotEmpty) {
                          _selectedMaintDriverId = _selectedMaintVehicle!.assignedDriverIds.first;
                        }
                      }
                    }
                  }
                });
              },
            ),
            const SizedBox(height: 12),

            // Vehicle Maintenance Type
            DropdownButtonFormField<String>(
              value: _maintType,
              dropdownColor: isDark ? const Color(0xFF0B1B3D) : Colors.white,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
              decoration: InputDecoration(
                labelText: 'Maintenance Type',
                prefixIcon: const Icon(Icons.handyman_rounded, color: AppColors.darkPrimaryGold, size: 20),
                fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
              ),
              items: [
                'General Service',
                'Engine Service',
                'Oil & Filters',
                'Tire Replacement',
                'Brake Repair',
                'Battery / Electrical',
                'Body Work',
                'Inspection / Emission',
              ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _maintType = val);
              },
            ),
            const SizedBox(height: 12),

            // Driver Selector & Odometer Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: availableDrivers.contains(_selectedMaintDriverName) ? _selectedMaintDriverName : null,
                    dropdownColor: isDark ? const Color(0xFF0B1B3D) : Colors.white,
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
                    decoration: InputDecoration(
                      labelText: 'Driver',
                      prefixIcon: const Icon(Icons.person_rounded, color: AppColors.darkPrimaryGold, size: 20),
                      fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('None / Unknown')),
                      ...availableDrivers.map((d) => DropdownMenuItem<String?>(
                            value: d,
                            child: Text(d, overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedMaintDriverName = val;
                        final matched = workers.where((w) => w.name == val).toList();
                        if (matched.isNotEmpty) {
                          _selectedMaintDriverId = matched.first.workerId;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _maintOdometerController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
                    decoration: InputDecoration(
                      labelText: 'Odometer (km)',
                      prefixIcon: const Icon(Icons.speed_rounded, color: AppColors.darkPrimaryGold, size: 20),
                      fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          TextField(
            controller: _maintTitleController,
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
            decoration: InputDecoration(
              labelText: isVehicleMode
                  ? 'Work Description / Replaced Parts'
                  : 'Equipment / Maintenance Title (e.g. Water Pump, Brooder Unit) *',
              prefixIcon: Icon(isVehicleMode ? Icons.description_rounded : Icons.precision_manufacturing_rounded, color: AppColors.darkPrimaryGold, size: 20),
              fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _maintCostController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
            decoration: InputDecoration(
              labelText: 'Total Cost (Rs.) *',
              prefixText: 'Rs. ',
              prefixIcon: const Icon(Icons.payments_rounded, color: AppColors.darkPrimaryGold, size: 20),
              fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _maintNoteController,
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
            decoration: InputDecoration(
              labelText: 'Workshop / Contractor / Invoice Notes',
              prefixIcon: const Icon(Icons.note_alt_rounded, color: AppColors.darkPrimaryGold, size: 20),
              fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _recordMaintenance,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isVehicleMode ? '+ RECORD VEHICLE MAINTENANCE' : '+ RECORD FACTORY MAINTENANCE',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodMedsCard(bool isDark) {
    final catalogsAsync = ref.watch(catalogsStreamProvider);
    final catalogMap = catalogsAsync.value ?? {};
    final catalogItems = catalogMap[_foodMedType.toLowerCase()] ?? [];
    final catalogNames = catalogItems.map((c) => c.name).toSet();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LOG FEED & MEDICINE PURCHASE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),

          // Toggle Feed or Medicine
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _foodMedType = 'Feed';
                      _selectedCatalogItem = null;
                      _foodMedNameController.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _foodMedType == 'Feed' ? AppColors.darkPrimaryGold : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.darkPrimaryGold),
                    ),
                    child: Center(
                      child: Text(
                        'Feed (Bags/Packets)',
                        style: TextStyle(
                          color: _foodMedType == 'Feed' ? const Color(0xFF0B1B3D) : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _foodMedType = 'Medicine';
                      _selectedCatalogItem = null;
                      _foodMedNameController.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _foodMedType == 'Medicine' ? AppColors.darkPrimaryGold : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.darkPrimaryGold),
                    ),
                    child: Center(
                      child: Text(
                        'Medicine / Vet',
                        style: TextStyle(
                          color: _foodMedType == 'Medicine' ? const Color(0xFF0B1B3D) : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Catalog Selector Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SELECT FROM CATALOG',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              InkWell(
                onTap: _showAddCatalogItemDialog,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline_rounded, size: 14, color: AppColors.darkPrimaryGold),
                      SizedBox(width: 4),
                      Text(
                        '+ Add New Item',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkPrimaryGold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Dropdown for Catalog Items
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: catalogNames.contains(_selectedCatalogItem) ? _selectedCatalogItem : null,
                hint: Text(
                  'Choose $_foodMedType from catalog...',
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 13),
                ),
                dropdownColor: isDark ? const Color(0xFF0B1B3D) : Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.darkPrimaryGold),
                items: [
                  ...catalogItems.map((item) {
                    return DropdownMenuItem<String>(
                      value: item.name,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (item.description.isNotEmpty)
                            Text(
                              item.description,
                              style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCatalogItem = val;
                      _foodMedNameController.text = val;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Custom / Editable Name Field
          TextField(
            controller: _foodMedNameController,
            onChanged: (val) {
              if (val != _selectedCatalogItem) {
                setState(() => _selectedCatalogItem = null);
              }
            },
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
            decoration: InputDecoration(
              labelText: '$_foodMedType Name / Description',
              fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _foodMedQtyController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _foodMedCostController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
                  decoration: InputDecoration(
                    labelText: 'Total Cost (Rs.)',
                    prefixText: 'Rs. ',
                    fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _recordFoodMed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('+ RECORD $_foodMedType.toUpperCase() PURCHASE', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  // ==================== NET PROFIT CARD ====================

  Widget _buildNetProfitCard(List<FinancialTransaction> transactions, NumberFormat formatter, bool isDark) {
    double totalIncome = 0.0;
    double totalExpenses = 0.0;

    for (final tx in transactions) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else {
        totalExpenses += tx.amount;
      }
    }

    final netProfit = totalIncome - totalExpenses;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'NET PROFIT THIS MONTH',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.darkPrimaryGold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Rs. ${formatter.format(netProfit.toInt())}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.darkPrimaryGold,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0x22FFFFFF), height: 1),
          const SizedBox(height: 16),

          // Total Income & Total Expenses Split
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Income:', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        FittedBox(
                          child: Text(
                            'Rs. ${formatter.format(totalIncome.toInt())}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF22C55E),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_outward, color: Color(0xFF22C55E), size: 18),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 42, color: const Color(0x22FFFFFF)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Expenses:', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        FittedBox(
                          child: Text(
                            'Rs. ${formatter.format(totalExpenses.toInt())}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_downward, color: Color(0xFFEF4444), size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== RECENT TRANSACTIONS ====================

  Widget _buildRecentTransactionsCard(
    List<FinancialTransaction> transactions,
    String category,
    NumberFormat formatter,
    bool isDark,
  ) {
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
              Expanded(
                child: Text(
                  'RECENT TRANSACTIONS ($category)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${transactions.length} entries',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFF64748B)),
                    const SizedBox(height: 8),
                    Text(
                      'No transactions found for "$category".',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: transactions.map((tx) {
                final isIncome = tx.type == 'income';
                final timeStr = tx.timestamp != null
                    ? DateFormat('MMM d, hh:mm a').format(tx.timestamp!)
                    : 'Just now';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isIncome ? const Color(0x3322C55E) : const Color(0x33EF4444),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isIncome ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.description,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            if (tx.category == 'Maintenance' && tx.regNumber != null && tx.regNumber!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tx.regNumber!,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.darkPrimaryGold),
                                    ),
                                  ),
                                  if (tx.driverName != null && tx.driverName!.isNotEmpty)
                                    Text(
                                      '• ${tx.driverName}',
                                      style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                    ),
                                  if (tx.odometer != null)
                                    Text(
                                      '• ${tx.odometer} km',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                    ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 2),
                            Text(
                              timeStr,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isIncome ? '+' : '-'} Rs. ${formatter.format(tx.amount.toInt())}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isIncome ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
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
  }
}
