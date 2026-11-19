import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../models/farm_models.dart';
import '../providers/farm_providers.dart';
import '../services/database_service.dart';
import '../utils/app_snackbar.dart';

class FleetScreen extends ConsumerStatefulWidget {
  const FleetScreen({super.key});

  @override
  ConsumerState<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends ConsumerState<FleetScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _filterNoDriver = false;
  String? _selectedFilterGroupId;
  String _selectedVehicleType = 'All';
  final List<String> _vehicleTypes = ['All', 'Lorry', 'Tractor', 'Van', 'Bike', 'Three-Wheeler', 'Cab'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackgroundWarm,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackgroundTop : Colors.white,
        elevation: 0,
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
                'assets/logo/Corporate_logo_design_for_farm_9c195630.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.agriculture_rounded, color: AppColors.darkPrimaryGold),
              ),
            ),
          ),
        ),
        title: Text(
          'Fleet & Logistics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0B1B3D),
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.darkPrimaryGold,
          indicatorWeight: 3,
          labelColor: AppColors.darkPrimaryGold,
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.local_shipping_rounded), text: 'All Vehicles'),
            Tab(icon: Icon(Icons.grid_view_rounded), text: 'Vehicle Groups'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllVehiclesTab(isDark),
          _buildVehicleGroupsTab(isDark),
        ],
      ),
    );
  }

  // ==================== TAB 1: ALL VEHICLES ====================
  Widget _buildSearchAndFilterHeader(bool isDark, List<VehicleGroup> groups) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1E36) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Bar + Vehicle Group Filter Dropdown
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
                    decoration: InputDecoration(
                      hintText: 'Search Reg No or Make/Model...',
                      hintStyle: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.darkPrimaryGold),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Group Filter Dropdown button
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedFilterGroupId != null ? AppColors.darkPrimaryGold : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedFilterGroupId,
                    hint: Text(
                      'Group',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.darkPrimaryGold),
                    dropdownColor: isDark ? const Color(0xFF0B1B3D) : Colors.white,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0B1B3D),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Groups'),
                      ),
                      ...groups.map((g) => DropdownMenuItem<String?>(
                            value: g.id,
                            child: Text(g.name),
                          )),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedFilterGroupId = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 2. Horizontal Scrollable Chips: "No Driver" toggle + Vehicle Type chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // "No Driver" Toggle Chip
                FilterChip(
                  selected: _filterNoDriver,
                  showCheckmark: false,
                  avatar: Icon(
                    _filterNoDriver ? Icons.person_off_rounded : Icons.person_outline_rounded,
                    size: 14,
                    color: _filterNoDriver ? const Color(0xFF0B1B3D) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                  label: const Text('No Driver'),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _filterNoDriver ? const Color(0xFF0B1B3D) : (isDark ? Colors.white : const Color(0xFF0B1B3D)),
                  ),
                  backgroundColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                  selectedColor: AppColors.darkPrimaryGold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: _filterNoDriver ? AppColors.darkPrimaryGold : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  onSelected: (selected) {
                    setState(() => _filterNoDriver = selected);
                  },
                ),
                const SizedBox(width: 8),

                // Divider line
                Container(width: 1, height: 18, color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                const SizedBox(width: 8),

                // Vehicle Type Chips: All, Lorry, Tractor, Van, Bike, Three-Wheeler, Cab
                ..._vehicleTypes.map((type) {
                  final isSelected = _selectedVehicleType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      selected: isSelected,
                      showCheckmark: false,
                      label: Text(type),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF0B1B3D) : (isDark ? Colors.white70 : const Color(0xFF475569)),
                      ),
                      backgroundColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                      selectedColor: AppColors.darkPrimaryGold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected ? AppColors.darkPrimaryGold : Colors.transparent,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedVehicleType = type);
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllVehiclesTab(bool isDark) {
    final vehiclesAsync = ref.watch(vehiclesStreamProvider);
    final groupsAsync = ref.watch(vehicleGroupsStreamProvider);
    final groups = groupsAsync.value ?? [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditVehicleDialog(isDark: isDark),
        backgroundColor: AppColors.darkPrimaryGold,
        foregroundColor: const Color(0xFF0B1B3D),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text('Add Vehicle', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search & Filter Interactive Header
          _buildSearchAndFilterHeader(isDark, groups),

          // Vehicle List with Real-Time Filtering
          Expanded(
            child: vehiclesAsync.when(
              data: (vehicles) {
                final filtered = vehicles.where((v) {
                  // 1. Search Query filter (regNumber or makeModel)
                  if (_searchQuery.isNotEmpty) {
                    final query = _searchQuery.toLowerCase();
                    final matchReg = v.regNumber.toLowerCase().contains(query);
                    final matchModel = v.makeModel.toLowerCase().contains(query);
                    if (!matchReg && !matchModel) return false;
                  }

                  // 2. No Driver filter
                  if (_filterNoDriver && v.assignedDriverIds.isNotEmpty) {
                    return false;
                  }

                  // 3. Vehicle Group filter
                  if (_selectedFilterGroupId != null && _selectedFilterGroupId!.isNotEmpty) {
                    if (v.groupId != _selectedFilterGroupId) return false;
                  }

                  // 4. Vehicle Type filter
                  if (_selectedVehicleType != 'All') {
                    if (v.vehicleType.toLowerCase() != _selectedVehicleType.toLowerCase()) return false;
                  }

                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  final isFiltered = _searchQuery.isNotEmpty ||
                      _filterNoDriver ||
                      _selectedFilterGroupId != null ||
                      _selectedVehicleType != 'All';

                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFiltered ? Icons.search_off_rounded : Icons.no_crash_rounded,
                            size: 48,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isFiltered ? 'No matching vehicles found.' : 'No vehicles registered yet.',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isFiltered
                              ? 'Try adjusting your search keywords or filter criteria.'
                              : 'Tap "+ Add Vehicle" to register a delivery vehicle or tractor.',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (ctx, idx) => _buildVehicleCard(filtered[idx], isDark),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.darkPrimaryGold)),
              error: (err, _) => Center(child: Text('Error loading vehicles: $err', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle v, bool isDark) {
    final expiringDocs = v.expiringDocuments;
    final isAnyDocExpired = v.isAnyDocumentExpired;

    Color statusBg;
    Color statusBorder;
    Color statusText;
    String statusLabel = v.status;

    if (isAnyDocExpired) {
      statusLabel = 'Inactive (Doc Expired)';
      statusBg = const Color(0x33EF4444);
      statusBorder = const Color(0xFFEF4444);
      statusText = const Color(0xFFEF4444);
    } else if (v.status == 'Under Maintenance') {
      statusBg = const Color(0x33F59E0B);
      statusBorder = const Color(0xFFF59E0B);
      statusText = const Color(0xFFF59E0B);
    } else {
      statusLabel = 'Active';
      statusBg = const Color(0x3322C55E);
      statusBorder = const Color(0xFF22C55E);
      statusText = const Color(0xFF22C55E);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAnyDocExpired
              ? const Color(0xFFEF4444).withValues(alpha: 0.6)
              : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
          width: isAnyDocExpired ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.darkPrimaryGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkPrimaryGold.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  _getVehicleIcon(v.vehicleType),
                  color: AppColors.darkPrimaryGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.regNumber,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0B1B3D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${v.vehicleType} • ${v.makeModel.isNotEmpty ? v.makeModel : "Standard"} • ${v.fuelType}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusBorder),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusText, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          if (v.groupName != null && v.groupName!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder_shared_rounded, size: 14, color: AppColors.darkPrimaryGold),
                  const SizedBox(width: 6),
                  Text(
                    'Group: ${v.groupName}',
                    style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],

          // Expiring or Expired Legal Documents Banner
          if (expiringDocs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAnyDocExpired
                    ? const Color(0x22EF4444)
                    : const Color(0x22F59E0B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isAnyDocExpired
                      ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isAnyDocExpired ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
                        size: 16,
                        color: isAnyDocExpired ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isAnyDocExpired ? 'COMPLIANCE VIOLATION (EXPIRED)' : 'UPCOMING DOCUMENT EXPIRY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isAnyDocExpired ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...expiringDocs.map((doc) {
                    final isExp = doc['isExpired'] as bool;
                    final days = doc['daysLeft'] as int;
                    final date = doc['date'] as DateTime;
                    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
                    return Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        isExp
                            ? '• ${doc['name']}: Expired on $formattedDate (${days.abs()} days overdue)'
                            : '• ${doc['name']}: Expires in $days days ($formattedDate)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isExp ? FontWeight.bold : FontWeight.w500,
                          color: isExp ? const Color(0xFFEF4444) : const Color(0xFFFCD34D),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // Assigned Drivers Chips
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              const Text('Drivers: ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold)),
              Expanded(
                child: v.assignedDriverNames.isEmpty
                    ? const Text('None assigned', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontStyle: FontStyle.italic))
                    : Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: v.assignedDriverNames.map((d) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              d,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF0F172A),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),

          // Compliance Summary Row
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1424) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDocStatusPill(
                  label: 'Insurance',
                  date: v.insuranceExpiryDate,
                  isExpired: v.isInsuranceExpired,
                ),
                _buildDocStatusPill(
                  label: 'Revenue',
                  date: v.revenueLicenseExpiryDate,
                  isExpired: v.isRevenueLicenseExpired,
                ),
                _buildDocStatusPill(
                  label: 'Eco Test',
                  date: v.ecoTestExpiryDate,
                  isExpired: v.isEcoTestExpired,
                ),
                _buildDocStatusPill(
                  label: 'Fitness',
                  date: v.fitnessCertExpiryDate,
                  isExpired: v.isFitnessExpired,
                ),
              ],
            ),
          ),

          // Action Buttons
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0x1FFFFFFF)),
          const SizedBox(height: 8),
          Row(
            children: [
              // Maintenance Logs Sheet
              Flexible(
                child: TextButton.icon(
                  onPressed: () => _showMaintenanceHistorySheet(v, isDark),
                  icon: const Icon(Icons.build_circle_outlined, size: 18, color: AppColors.darkPrimaryGold),
                  label: const Text(
                    'Maintenance',
                    style: TextStyle(color: AppColors.darkPrimaryGold, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const Spacer(),
              // Toggle Active / Under Maintenance
              IconButton(
                tooltip: v.status == 'Under Maintenance' ? 'Set as Active' : 'Set Under Maintenance',
                icon: Icon(
                  v.status == 'Under Maintenance' ? Icons.check_circle_outline_rounded : Icons.handyman_outlined,
                  size: 20,
                  color: v.status == 'Under Maintenance' ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                ),
                onPressed: () => _toggleVehicleMaintenanceStatus(v),
              ),
              // Edit Vehicle
              IconButton(
                tooltip: 'Edit Vehicle',
                icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF94A3B8)),
                onPressed: () => _showAddOrEditVehicleDialog(existingVehicle: v, isDark: isDark),
              ),
              // Delete Vehicle
              IconButton(
                tooltip: 'Delete Vehicle',
                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                onPressed: () => _confirmDeleteVehicle(v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocStatusPill({required String label, required DateTime? date, required bool isExpired}) {
    final hasDate = date != null;
    Color color;
    if (!hasDate) {
      color = const Color(0xFF64748B);
    } else if (isExpired) {
      color = const Color(0xFFEF4444);
    } else {
      final days = date.difference(DateTime.now()).inDays;
      color = days <= 10 ? const Color(0xFFF59E0B) : const Color(0xFF22C55E);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(
              hasDate ? DateFormat('MM/yy').format(date) : 'N/A',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getVehicleIcon(String type) {
    switch (type.toLowerCase()) {
      case 'lorry':
        return Icons.local_shipping_rounded;
      case 'tractor':
        return Icons.agriculture_rounded;
      case 'van':
        return Icons.airport_shuttle_rounded;
      case 'bike':
        return Icons.two_wheeler_rounded;
      case 'three-wheeler':
        return Icons.electric_rickshaw_rounded;
      default:
        return Icons.directions_car_rounded;
    }
  }

  // ==================== TOGGLE STATUS & DELETE ====================
  Future<void> _toggleVehicleMaintenanceStatus(Vehicle v) async {
    final newStatus = v.status == 'Under Maintenance' ? 'Active' : 'Under Maintenance';
    final confirmed = await _showConfirmationDialog(
      title: 'Update Vehicle Status',
      content: 'Are you sure you want to change status of ${v.regNumber} to "$newStatus"?',
      confirmText: 'UPDATE STATUS',
      confirmColor: newStatus == 'Active' ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
    );

    if (confirmed) {
      final db = ref.read(databaseServiceProvider);
      final updated = Vehicle(
        vehicleId: v.vehicleId,
        regNumber: v.regNumber,
        vehicleType: v.vehicleType,
        makeModel: v.makeModel,
        chassisNo: v.chassisNo,
        fuelType: v.fuelType,
        groupId: v.groupId,
        groupName: v.groupName,
        insurancePolicyNo: v.insurancePolicyNo,
        insuranceType: v.insuranceType,
        insuranceExpiryDate: v.insuranceExpiryDate,
        revenueLicenseNo: v.revenueLicenseNo,
        revenueLicenseExpiryDate: v.revenueLicenseExpiryDate,
        ecoTestNo: v.ecoTestNo,
        ecoTestExpiryDate: v.ecoTestExpiryDate,
        fitnessCertNo: v.fitnessCertNo,
        fitnessCertExpiryDate: v.fitnessCertExpiryDate,
        status: newStatus,
        manualStatusOverride: true,
        assignedDriverIds: v.assignedDriverIds,
        assignedDriverNames: v.assignedDriverNames,
        createdAt: v.createdAt,
      );

      await db.updateVehicle(updated);
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Vehicle ${v.regNumber} marked as $newStatus');
      }
    }
  }

  Future<void> _confirmDeleteVehicle(Vehicle v) async {
    final confirmed = await _showConfirmationDialog(
      title: 'Delete Vehicle Record',
      content: 'Are you sure you want to permanently delete vehicle "${v.regNumber}"? This action cannot be undone.',
      confirmText: 'DELETE',
      confirmColor: const Color(0xFFEF4444),
    );

    if (confirmed) {
      final db = ref.read(databaseServiceProvider);
      await db.deleteVehicle(v.vehicleId);
      if (mounted) {
        AppSnackBar.showInfo(context, 'Vehicle ${v.regNumber} deleted');
      }
    }
  }

  // ==================== MAINTENANCE HISTORY BOTTOM SHEET ====================
  void _showMaintenanceHistorySheet(Vehicle v, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F1E36) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final db = ref.read(databaseServiceProvider);
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: StreamBuilder<List<VehicleMaintenanceLog>>(
            stream: db.streamVehicleMaintenance(v.vehicleId),
            builder: (context, snapshot) {
              final logs = snapshot.data ?? [];
              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFF475569), borderRadius: BorderRadius.circular(2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(Icons.build_circle_rounded, color: AppColors.darkPrimaryGold),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Maintenance History',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0B1B3D),
                                ),
                              ),
                              Text(
                                '${v.regNumber} • ${logs.length} records',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0x22FFFFFF), height: 16),
                  Expanded(
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? const Center(child: CircularProgressIndicator(color: AppColors.darkPrimaryGold))
                        : logs.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.assignment_outlined, size: 40, color: Color(0xFF64748B)),
                                    SizedBox(height: 8),
                                    Text(
                                      'No maintenance records logged yet for this vehicle.',
                                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                itemCount: logs.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, idx) {
                                  final log = logs[idx];
                                  final dateStr = log.timestamp != null
                                      ? DateFormat('yyyy-MM-dd • hh:mm a').format(log.timestamp!)
                                      : 'Recent';
                                  return Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF162544) : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                log.maintenanceType,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.darkPrimaryGold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Rs. ${NumberFormat('#,###.00').format(log.cost)}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFEF4444)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          log.description,
                                          style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF334155), fontSize: 13),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            if (log.driverName.isNotEmpty) ...[
                                              const Icon(Icons.person, size: 14, color: Color(0xFF94A3B8)),
                                              const SizedBox(width: 4),
                                              Text(log.driverName, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                              const SizedBox(width: 12),
                                            ],
                                            if (log.odometer != null) ...[
                                              const Icon(Icons.speed, size: 14, color: Color(0xFF94A3B8)),
                                              const SizedBox(width: 4),
                                              Text('${log.odometer} km', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                              const SizedBox(width: 12),
                                            ],
                                            const Spacer(),
                                            Text(dateStr, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
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
          ),
        );
      },
    );
  }

  // ==================== ADD / EDIT VEHICLE DIALOG ====================
  void _showAddOrEditVehicleDialog({Vehicle? existingVehicle, required bool isDark}) {
    final isEditing = existingVehicle != null;
    final regNoController = TextEditingController(text: existingVehicle?.regNumber ?? '');
    final makeModelController = TextEditingController(text: existingVehicle?.makeModel ?? '');
    final chassisController = TextEditingController(text: existingVehicle?.chassisNo ?? '');
    final insurancePolicyController = TextEditingController(text: existingVehicle?.insurancePolicyNo ?? '');
    final revenueLicenseController = TextEditingController(text: existingVehicle?.revenueLicenseNo ?? '');
    final ecoTestController = TextEditingController(text: existingVehicle?.ecoTestNo ?? '');
    final fitnessCertController = TextEditingController(text: existingVehicle?.fitnessCertNo ?? '');

    String vehicleType = existingVehicle?.vehicleType ?? 'Lorry';
    String fuelType = existingVehicle?.fuelType ?? 'Diesel';
    String insuranceType = existingVehicle?.insuranceType ?? 'Comprehensive';
    String? selectedGroupId = existingVehicle?.groupId;
    String? selectedGroupName = existingVehicle?.groupName;

    DateTime? insuranceExpiry = existingVehicle?.insuranceExpiryDate;
    DateTime? revenueLicenseExpiry = existingVehicle?.revenueLicenseExpiryDate;
    DateTime? ecoTestExpiry = existingVehicle?.ecoTestExpiryDate;
    DateTime? fitnessCertExpiry = existingVehicle?.fitnessCertExpiryDate;

    List<String> assignedDriverIds = List.from(existingVehicle?.assignedDriverIds ?? []);
    List<String> assignedDriverNames = List.from(existingVehicle?.assignedDriverNames ?? []);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final groups = ref.watch(vehicleGroupsStreamProvider).value ?? [];
            final workers = ref.watch(workersStreamProvider).value ?? [];

            Future<void> pickDate(String title, DateTime? current, Function(DateTime) onPicked) async {
              final picked = await showDatePicker(
                context: dialogCtx,
                initialDate: current ?? DateTime.now().add(const Duration(days: 365)),
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
                builder: (context, child) {
                  return Theme(
                    data: isDark ? ThemeData.dark() : ThemeData.light(),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setDialogState(() {
                  onPicked(picked);
                });
              }
            }

            final uniqueGroups = <String, VehicleGroup>{};
            for (final g in groups) {
              uniqueGroups[g.id] = g;
            }
            final groupList = uniqueGroups.values.toList();
            final validGroupId = groupList.any((g) => g.id == selectedGroupId) ? selectedGroupId : null;

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF0F1E36) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              ),
              title: Text(
                isEditing ? 'Edit Vehicle: ${existingVehicle.regNumber}' : 'Register New Vehicle',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0B1B3D),
                  fontSize: 18,
                ),
              ),
              content: SizedBox(
                width: MediaQuery.of(dialogCtx).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Section 1: Vehicle Information
                      const Text('VEHICLE IDENTIFICATION', style: TextStyle(color: AppColors.darkPrimaryGold, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: regNoController,
                        textCapitalization: TextCapitalization.characters,
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
                        decoration: InputDecoration(
                          labelText: 'Registration Number * (e.g. CP CAA-1234)',
                          fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: vehicleType,
                              dropdownColor: isDark ? const Color(0xFF0B1B3D) : Colors.white,
                              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
                              decoration: InputDecoration(
                                labelText: 'Type',
                                fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                              ),
                              items: ['Lorry', 'Tractor', 'Van', 'Bike', 'Three-Wheeler', 'Cab']
                                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => vehicleType = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: fuelType,
                              dropdownColor: isDark ? const Color(0xFF0B1B3D) : Colors.white,
                              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
                              decoration: InputDecoration(
                                labelText: 'Fuel',
                                fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                              ),
                              items: ['Diesel', 'Petrol', 'Electric', 'Hybrid']
                                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => fuelType = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: makeModelController,
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
                        decoration: InputDecoration(
                          labelText: 'Make & Model (e.g. Isuzu Elf / Dimo Batta)',
                          fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: chassisController,
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
                        decoration: InputDecoration(
                          labelText: 'Chassis Number (Optional)',
                          fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Vehicle Group Assignment
                      DropdownButtonFormField<String?>(
                        value: validGroupId,
                        dropdownColor: isDark ? const Color(0xFF0B1B3D) : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
                        decoration: InputDecoration(
                          labelText: 'Vehicle Fleet Group (Optional)',
                          fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('No Group (Standalone)')),
                          ...groupList.map((g) => DropdownMenuItem<String?>(value: g.id, child: Text(g.name))),
                        ],
                        onChanged: (val) {
                          setDialogState(() {
                            selectedGroupId = val;
                            if (val == null) {
                              selectedGroupName = null;
                            } else {
                              final matched = groupList.firstWhere((g) => g.id == val);
                              selectedGroupName = matched.name;
                            }
                          });
                        },
                      ),

                      const SizedBox(height: 18),
                      const Divider(color: Color(0x22FFFFFF)),
                      const SizedBox(height: 10),

                      // Section 2: Sri Lankan Legal Compliance Documents
                      const Text(
                        'LEGAL COMPLIANCE DOCUMENTS (SRI LANKA)',
                        style: TextStyle(color: AppColors.darkPrimaryGold, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      // 1. Insurance
                      TextField(
                        controller: insurancePolicyController,
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
                        decoration: InputDecoration(
                          labelText: 'Insurance Policy No',
                          fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: insuranceType,
                              dropdownColor: isDark ? const Color(0xFF0B1B3D) : Colors.white,
                              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
                              decoration: InputDecoration(
                                labelText: 'Coverage',
                                fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                              ),
                              items: ['Comprehensive', 'Third Party']
                                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => insuranceType = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => pickDate('Insurance Expiry', insuranceExpiry, (d) => insuranceExpiry = d),
                              icon: const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.darkPrimaryGold),
                              label: FittedBox(
                                child: Text(
                                  insuranceExpiry != null ? DateFormat('yyyy-MM-dd').format(insuranceExpiry!) : 'Set Expiry',
                                  style: const TextStyle(fontSize: 12, color: Colors.white),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF334155)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 2. Revenue License
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: revenueLicenseController,
                              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
                              decoration: InputDecoration(
                                labelText: 'Revenue License No (ආදායම් බලපත්‍රය)',
                                fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () => pickDate('Revenue License Expiry', revenueLicenseExpiry, (d) => revenueLicenseExpiry = d),
                            icon: const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.darkPrimaryGold),
                            label: FittedBox(
                              child: Text(
                                revenueLicenseExpiry != null ? DateFormat('yyyy-MM-dd').format(revenueLicenseExpiry!) : 'Set Expiry',
                                style: const TextStyle(fontSize: 12, color: Colors.white),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF334155)),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 3. Eco Test
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: ecoTestController,
                              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
                              decoration: InputDecoration(
                                labelText: 'Eco Test No (දුම් සහතිකය)',
                                fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () => pickDate('Eco Test Expiry', ecoTestExpiry, (d) => ecoTestExpiry = d),
                            icon: const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.darkPrimaryGold),
                            label: FittedBox(
                              child: Text(
                                ecoTestExpiry != null ? DateFormat('yyyy-MM-dd').format(ecoTestExpiry!) : 'Set Expiry',
                                style: const TextStyle(fontSize: 12, color: Colors.white),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF334155)),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 4. Fitness Certificate
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: fitnessCertController,
                              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
                              decoration: InputDecoration(
                                labelText: 'Fitness Cert No (යෝග්‍යතා සහතිකය)',
                                fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () => pickDate('Fitness Cert Expiry', fitnessCertExpiry, (d) => fitnessCertExpiry = d),
                            icon: const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.darkPrimaryGold),
                            label: FittedBox(
                              child: Text(
                                fitnessCertExpiry != null ? DateFormat('yyyy-MM-dd').format(fitnessCertExpiry!) : 'Set Expiry',
                                style: const TextStyle(fontSize: 12, color: Colors.white),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF334155)),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),
                      const Divider(color: Color(0x22FFFFFF)),
                      const SizedBox(height: 10),

                      // Section 3: Driver Assignments (Strict Driver Role Filter & Optional)
                      const Text(
                        'ASSIGN RESPONSIBLE DRIVERS (OPTIONAL)',
                        style: TextStyle(color: AppColors.darkPrimaryGold, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Only active workers with "Driver" role are displayed. You can save without assigning a driver.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final driverWorkers = workers.where((w) => w.role.toLowerCase().contains('driver')).toList();
                          if (driverWorkers.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No registered workers with "Driver" role found. Driver assignment is optional.',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontStyle: FontStyle.italic),
                              ),
                            );
                          }
                          return Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: driverWorkers.map((worker) {
                              final isAssigned = assignedDriverIds.contains(worker.workerId);
                              return FilterChip(
                                selected: isAssigned,
                                label: Text(
                                  worker.name,
                                  style: TextStyle(
                                    color: isAssigned ? const Color(0xFF0B1B3D) : (isDark ? Colors.white : const Color(0xFF0B1B3D)),
                                    fontWeight: isAssigned ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: isDark ? const Color(0xFF162544) : const Color(0xFFF1F5F9),
                                selectedColor: AppColors.darkPrimaryGold,
                                checkmarkColor: const Color(0xFF0B1B3D),
                                onSelected: (selected) {
                                  setDialogState(() {
                                    if (selected) {
                                      assignedDriverIds.add(worker.workerId);
                                      assignedDriverNames.add(worker.name);
                                    } else {
                                      assignedDriverIds.remove(worker.workerId);
                                      assignedDriverNames.remove(worker.name);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('CANCEL', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final regNumber = regNoController.text.trim().toUpperCase();
                    if (regNumber.isEmpty) {
                      AppSnackBar.showError(context, 'Please enter a Registration Number');
                      return;
                    }

                    final confirmed = await _showConfirmationDialog(
                      title: isEditing ? 'Confirm Vehicle Update' : 'Confirm Vehicle Registration',
                      content: 'Are you sure you want to save vehicle "$regNumber" to the fleet database?',
                      confirmText: isEditing ? 'UPDATE' : 'REGISTER',
                      confirmColor: AppColors.darkPrimaryGold,
                    );

                    if (confirmed) {
                      final db = ref.read(databaseServiceProvider);
                      final vehicle = Vehicle(
                        vehicleId: isEditing ? existingVehicle.vehicleId : 'veh_${DateTime.now().millisecondsSinceEpoch}',
                        regNumber: regNumber,
                        vehicleType: vehicleType,
                        makeModel: makeModelController.text.trim(),
                        chassisNo: chassisController.text.trim(),
                        fuelType: fuelType,
                        groupId: selectedGroupId,
                        groupName: selectedGroupName,
                        insurancePolicyNo: insurancePolicyController.text.trim(),
                        insuranceType: insuranceType,
                        insuranceExpiryDate: insuranceExpiry,
                        revenueLicenseNo: revenueLicenseController.text.trim(),
                        revenueLicenseExpiryDate: revenueLicenseExpiry,
                        ecoTestNo: ecoTestController.text.trim(),
                        ecoTestExpiryDate: ecoTestExpiry,
                        fitnessCertNo: fitnessCertController.text.trim(),
                        fitnessCertExpiryDate: fitnessCertExpiry,
                        status: existingVehicle?.status ?? 'Active',
                        manualStatusOverride: existingVehicle?.manualStatusOverride ?? false,
                        assignedDriverIds: assignedDriverIds,
                        assignedDriverNames: assignedDriverNames,
                        createdAt: existingVehicle?.createdAt,
                      );

                      if (isEditing) {
                        await db.updateVehicle(vehicle);
                      } else {
                        await db.addVehicle(vehicle);
                      }

                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                      if (mounted) {
                        AppSnackBar.showSuccess(
                          context,
                          isEditing ? 'Vehicle $regNumber updated!' : 'Vehicle $regNumber registered successfully!',
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkPrimaryGold,
                    foregroundColor: const Color(0xFF0B1B3D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(isEditing ? 'SAVE CHANGES' : 'REGISTER VEHICLE', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== TAB 2: VEHICLE GROUPS ====================
  Widget _buildVehicleGroupsTab(bool isDark) {
    final groupsAsync = ref.watch(vehicleGroupsStreamProvider);
    final vehiclesAsync = ref.watch(vehiclesStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGroupDialog(isDark: isDark),
        backgroundColor: AppColors.darkPrimaryGold,
        foregroundColor: const Color(0xFF0B1B3D),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text('Create Group', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.folder_shared_outlined, size: 48, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No vehicle fleet groups created.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap "+ Create Group" to organize vehicles by route or branch.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ],
              ),
            );
          }

          final allVehicles = vehiclesAsync.value ?? [];

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (ctx, idx) {
              final group = groups[idx];
              final groupVehicles = allVehicles.where((v) => group.vehicleIds.contains(v.vehicleId) || v.groupId == group.id).toList();

              return Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.darkPrimaryGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.folder_rounded, color: AppColors.darkPrimaryGold, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0B1B3D),
                                ),
                              ),
                              if (group.description.isNotEmpty)
                                Text(
                                  group.description,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${groupVehicles.length} vehicles',
                            style: const TextStyle(color: AppColors.darkPrimaryGold, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Vehicles Chips
                    if (groupVehicles.isEmpty)
                      const Text(
                        'No vehicles assigned to this fleet group.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontStyle: FontStyle.italic),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: groupVehicles.map((v) {
                          return Chip(
                            avatar: Icon(_getVehicleIcon(v.vehicleType), size: 16, color: AppColors.darkPrimaryGold),
                            label: Text(
                              v.regNumber,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0B1B3D),
                              ),
                            ),
                            backgroundColor: isDark ? const Color(0xFF162544) : const Color(0xFFF1F5F9),
                            deleteIcon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFEF4444)),
                            onDeleted: () => _confirmRemoveVehicleFromGroup(v, group),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0x1FFFFFFF)),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _showAssignVehicleDialog(group, allVehicles, isDark),
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.darkPrimaryGold),
                          label: const Text('Assign Vehicle', style: TextStyle(color: AppColors.darkPrimaryGold, fontSize: 12)),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Delete Group',
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                          onPressed: () => _confirmDeleteVehicleGroup(group),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.darkPrimaryGold)),
        error: (err, _) => Center(child: Text('Error loading groups: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  // ==================== CREATE VEHICLE GROUP DIALOG ====================
  void _showCreateGroupDialog({required bool isDark}) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0F1E36) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
          ),
          title: Text(
            'Create Vehicle Group',
            style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
                decoration: InputDecoration(
                  labelText: 'Group Name (e.g. Egg Distribution Route A)',
                  fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
                decoration: InputDecoration(
                  labelText: 'Description / Coverage Area',
                  fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final confirmed = await _showConfirmationDialog(
                  title: 'Confirm Create Fleet Group',
                  content: 'Create new vehicle group "$name"?',
                  confirmText: 'CREATE',
                );

                if (confirmed) {
                  final db = ref.read(databaseServiceProvider);
                  final group = VehicleGroup(
                    id: 'vgrp_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    description: descController.text.trim(),
                  );
                  await db.createVehicleGroup(group);

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    AppSnackBar.showSuccess(context, 'Vehicle group "$name" created!');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkPrimaryGold,
                foregroundColor: const Color(0xFF0B1B3D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('CREATE GROUP', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ==================== ASSIGN VEHICLE TO GROUP DIALOG ====================
  void _showAssignVehicleDialog(VehicleGroup group, List<Vehicle> allVehicles, bool isDark) {
    final unassigned = allVehicles.where((v) => !group.vehicleIds.contains(v.vehicleId) && v.groupId != group.id).toList();
    final uniqueUnassigned = <String, Vehicle>{};
    for (final v in unassigned) {
      uniqueUnassigned[v.vehicleId] = v;
    }
    final unassignedList = uniqueUnassigned.values.toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        String? selectedVehicleId = unassignedList.isNotEmpty ? unassignedList.first.vehicleId : null;

        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final validSelectedId = unassignedList.any((v) => v.vehicleId == selectedVehicleId)
                ? selectedVehicleId
                : (unassignedList.isNotEmpty ? unassignedList.first.vehicleId : null);

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF0F1E36) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              ),
              title: Text(
                'Assign Vehicle to ${group.name}',
                style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
              ),
              content: unassignedList.isEmpty
                  ? const Text('All registered vehicles are already in this group or none available.')
                  : DropdownButtonFormField<String>(
                      value: validSelectedId,
                      dropdownColor: isDark ? const Color(0xFF0B1B3D) : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0B1B3D)),
                      decoration: InputDecoration(
                        labelText: 'Select Vehicle',
                        fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                      ),
                      items: unassignedList.map((v) {
                        return DropdownMenuItem(
                          value: v.vehicleId,
                          child: Text('${v.regNumber} (${v.vehicleType})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedVehicleId = val);
                      },
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('CANCEL', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
                if (unassignedList.isNotEmpty)
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedVehicleId == null) return;
                      final selectedV = unassignedList.firstWhere((v) => v.vehicleId == selectedVehicleId);

                      final confirmed = await _showConfirmationDialog(
                        title: 'Confirm Assignment',
                        content: 'Assign ${selectedV.regNumber} to fleet group "${group.name}"?',
                        confirmText: 'ASSIGN',
                      );

                      if (confirmed) {
                        final db = ref.read(databaseServiceProvider);
                        await db.assignVehicleToGroup(
                          vehicleId: selectedV.vehicleId,
                          groupId: group.id,
                          groupName: group.name,
                        );

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          AppSnackBar.showSuccess(
                            context,
                            'Vehicle ${selectedV.regNumber} assigned to ${group.name}!',
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkPrimaryGold,
                      foregroundColor: const Color(0xFF0B1B3D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('ASSIGN', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== REMOVE & DELETE GROUP ====================
  Future<void> _confirmRemoveVehicleFromGroup(Vehicle v, VehicleGroup group) async {
    final confirmed = await _showConfirmationDialog(
      title: 'Remove Vehicle from Group',
      content: 'Remove ${v.regNumber} from fleet group "${group.name}"?',
      confirmText: 'REMOVE',
      confirmColor: const Color(0xFFEF4444),
    );

    if (confirmed) {
      final db = ref.read(databaseServiceProvider);
      await db.removeVehicleFromGroup(vehicleId: v.vehicleId, groupId: group.id);
      if (mounted) {
        AppSnackBar.showInfo(context, '${v.regNumber} removed from ${group.name}');
      }
    }
  }

  Future<void> _confirmDeleteVehicleGroup(VehicleGroup group) async {
    final confirmed = await _showConfirmationDialog(
      title: 'Delete Fleet Group',
      content: 'Permanently delete group "${group.name}"? Vehicles in this group will not be deleted.',
      confirmText: 'DELETE GROUP',
      confirmColor: const Color(0xFFEF4444),
    );

    if (confirmed) {
      final db = ref.read(databaseServiceProvider);
      await db.deleteVehicleGroup(group.id);
      if (mounted) {
        AppSnackBar.showInfo(context, 'Vehicle group "${group.name}" deleted!');
      }
    }
  }
}
