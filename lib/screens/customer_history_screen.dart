import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../models/farm_models.dart';
import '../providers/farm_providers.dart';
import '../utils/app_snackbar.dart';

class CustomerHistoryScreen extends ConsumerStatefulWidget {
  const CustomerHistoryScreen({super.key});

  @override
  ConsumerState<CustomerHistoryScreen> createState() => _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState extends ConsumerState<CustomerHistoryScreen> {
  int _selectedFilter = 0; // 0: All, 1: Pending, 2: Accepted, 3: Rejected, 4: Cancelled

  final List<String> _filterTabs = [
    'All Orders',
    'Pending',
    'Accepted',
    'Rejected',
    'Cancelled',
  ];

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return const Color(0xFF0EA5E9);
      case 'assigned':
      case 'dispatched':
      case 'in-transit':
        return const Color(0xFFF97316);
      case 'delivered':
        return const Color(0xFF22C55E);
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFEF4444);
      case 'pending':
      default:
        return AppColors.darkPrimaryGold;
    }
  }

  Future<void> _confirmCancelOrder(BuildContext context, CustomerOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16264C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.cancel_outlined, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cancel Order',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel this pending order of ${order.quantity} eggs (Rs. ${order.totalPrice.toStringAsFixed(2)})?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Order', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CANCEL ORDER', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final db = ref.read(databaseServiceProvider);
        await db.cancelCustomerOrder(order.orderId);
        if (mounted) {
          final shortId = order.orderId.length > 8 ? order.orderId.substring(0, 8) : order.orderId;
          AppSnackBar.showSuccess(context, 'Order #$shortId has been cancelled.');
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(context, 'Failed to cancel order: $e');
        }
      }
    }
  }

  Future<void> _handleReorder(BuildContext context, CustomerOrder order) async {
    final settings = ref.read(farmSettingsStreamProvider).value;
    final currentUnitPrice = settings?.unitEggPrice ?? 40.0;
    final totalCost = order.quantity * currentUnitPrice;
    final formatter = NumberFormat('#,###');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF16264C) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.refresh_rounded, color: AppColors.darkPrimaryGold),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Confirm Re-order',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Re-order ${formatter.format(order.quantity)} eggs with current farm pricing?'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Quantity:'),
                        Text('${formatter.format(order.quantity)} Eggs', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Current Unit Price:'),
                        Text('Rs. ${currentUnitPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Updated Total:'),
                        Text(
                          'Rs. ${formatter.format(totalCost.toInt())}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF22C55E)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkPrimaryGold,
                foregroundColor: const Color(0xFF0B1B3D),
              ),
              child: const Text('CONFIRM RE-ORDER', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final newOrderId = await ref.read(databaseServiceProvider).remakeCustomerOrder(
          previousOrder: order,
          currentUnitPrice: currentUnitPrice,
        );
        if (mounted) {
          final shortId = newOrderId.length > 8 ? newOrderId.substring(0, 8) : newOrderId;
          AppSnackBar.showSuccess(
            context,
            'Order #$shortId placed successfully! Pending admin approval.',
          );
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(context, 'Failed to re-order: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ordersAsync = ref.watch(customerOrdersStreamProvider);
    final formatter = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Order History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: isDark ? const Color(0xFF0B1B3D) : AppColors.lightPrimaryNavy,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const RadialGradient(
                  center: Alignment(0.0, -0.4),
                  radius: 1.4,
                  colors: [
                    Color(0xFF0F2656),
                    Color(0xFF0B1B3D),
                    Color(0xFF071229),
                  ],
                )
              : null,
        ),
        child: Column(
          children: [
            // Horizontally Scrollable Filter Bar (Prevents any 360dp overflow)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B1B3D).withOpacity(0.8) : Colors.white,
                border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: List.generate(_filterTabs.length, (idx) {
                    final isSelected = _selectedFilter == idx;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedFilter = idx),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.darkPrimaryGold
                                : (isDark ? const Color(0xFF16264C) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.darkPrimaryGold : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            _filterTabs[idx],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? const Color(0xFF0B1B3D) : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Orders List
            Expanded(
              child: ordersAsync.when(
                data: (orders) {
                  final sortedOrders = List<CustomerOrder>.from(orders)
                    ..sort((a, b) {
                      final aTime = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
                      final bTime = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
                      return bTime.compareTo(aTime);
                    });

                  final filtered = sortedOrders.where((o) {
                    final s = o.status.toLowerCase();
                    switch (_selectedFilter) {
                      case 1:
                        return s == 'pending';
                      case 2:
                        return s == 'accepted';
                      case 3:
                        return s == 'rejected';
                      case 4:
                        return s == 'cancelled';
                      case 0:
                      default:
                        return true;
                    }
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? const Color(0xFF16264C) : const Color(0xFFF1F5F9),
                              ),
                              child: const Icon(Icons.receipt_long_outlined, size: 54, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _selectedFilter == 0 ? 'No orders placed yet' : 'No ${_filterTabs[_selectedFilter].toLowerCase()} orders',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Your commercial egg orders will appear here with live tracking status.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, index) {
                      final order = filtered[index];
                      final statusColor = _getStatusColor(order.status);
                      final formattedDate = order.timestamp != null
                          ? DateFormat('dd MMM yyyy, hh:mm a').format(order.timestamp!)
                          : 'Just now';
                      final statusLower = order.status.toLowerCase();
                      final isPending = statusLower == 'pending';
                      final isCancelled = statusLower == 'cancelled';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF16264C) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Order ID & Status Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.egg_outlined, size: 18, color: AppColors.darkPrimaryGold),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Order #${order.orderId.length > 8 ? order.orderId.substring(0, 8).toUpperCase() : order.orderId.toUpperCase()}',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.16),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: statusColor, width: 1),
                                  ),
                                  child: Text(
                                    order.status.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            Text(
                              formattedDate,
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            ),
                            const Divider(height: 18, color: Color(0x22FFFFFF)),

                            // Quantity & Pricing Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Quantity', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${formatter.format(order.quantity)} Eggs',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Total Cost', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Rs. ${formatter.format(order.totalPrice.toInt())}',
                                      style: const TextStyle(
                                        color: AppColors.darkPrimaryGold,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            if (order.shopName.isNotEmpty || order.shopAddress.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${order.shopName}${order.shopAddress.isNotEmpty ? " • ${order.shopAddress}" : ""}',
                                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Rejection reason if any
                            if (order.rejectionReason != null && order.rejectionReason!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Reason: ${order.rejectionReason}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
                              ),
                            ],

                            // Action buttons: Cancel for Pending, Re-order for Cancelled
                            if (isPending) ...[
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFFEF4444),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(Icons.cancel_outlined, size: 15),
                                  label: const Text('Cancel Order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  onPressed: () => _confirmCancelOrder(context, order),
                                ),
                              ),
                            ] else if (isCancelled) ...[
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.darkPrimaryGold,
                                    foregroundColor: const Color(0xFF0B1B3D),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text('Re-order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  onPressed: () => _handleReorder(context, order),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.darkPrimaryGold),
                ),
                error: (err, _) => Center(
                  child: Text('Error loading orders: $err', style: const TextStyle(color: Colors.white70)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
