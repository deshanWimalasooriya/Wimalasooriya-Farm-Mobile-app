import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../models/farm_models.dart';
import '../providers/farm_providers.dart';
import '../utils/app_snackbar.dart';

class BulkOrdersScreen extends ConsumerStatefulWidget {
  const BulkOrdersScreen({super.key});

  @override
  ConsumerState<BulkOrdersScreen> createState() => _BulkOrdersScreenState();
}

class _BulkOrdersScreenState extends ConsumerState<BulkOrdersScreen> {
  final _formatter = NumberFormat('#,###');
  final _dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
  int _selectedFilter = 0; // 0: All, 1: Pending, 2: Accepted, 3: Dispatched, 4: Rejected

  final List<String> _filterTabs = [
    'All Orders',
    'Pending',
    'Accepted',
    'Dispatched',
    'Rejected',
  ];

  String _getShortId(String id) {
    return id.length > 8 ? id.substring(0, 8) : id;
  }

  Future<void> _handleAccept(CustomerOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCardSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.check_circle_outline_rounded, color: Color(0xFF0EA5E9)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Accept Order',
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
              Text('Accept order #${_getShortId(order.orderId)}?'),
              const SizedBox(height: 10),
              Text(
                'Shop / Client: ${order.shopName.isNotEmpty ? order.shopName : order.customerName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Quantity: ${_formatter.format(order.quantity)} Eggs'),
              Text('Total Price: Rs. ${_formatter.format(order.totalPrice.toInt())}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0EA5E9), foregroundColor: Colors.white),
              child: const Text('CONFIRM ACCEPT'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await ref.read(databaseServiceProvider).acceptCustomerOrder(order);
        if (mounted) {
          AppSnackBar.showSuccess(context, 'Order #${_getShortId(order.orderId)} accepted. Customer notified.');
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(context, 'Failed to accept order: $e');
        }
      }
    }
  }

  Future<void> _handleReject(CustomerOrder order) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCardSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.cancel_outlined, color: Color(0xFFEF4444)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reject Order',
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
              Text(
                'Are you sure you want to reject order #${_getShortId(order.orderId)} from ${order.shopName.isNotEmpty ? order.shopName : order.customerName}?',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text('Quantity: ${_formatter.format(order.quantity)} Eggs'),
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason for rejection (Optional)',
                  hintText: 'e.g. Stock unavailable, delivery unreachable',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
              child: const Text('REJECT ORDER'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await ref.read(databaseServiceProvider).rejectCustomerOrder(order, reasonController.text.trim());
        if (mounted) {
          AppSnackBar.showInfo(context, 'Order #${_getShortId(order.orderId)} rejected. Customer notified.');
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(context, 'Failed to reject order: $e');
        }
      }
    }
  }

  Future<void> _handleDispatch(CustomerOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCardSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.local_shipping_outlined, color: Color(0xFFF97316)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Confirm Dispatch',
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
              Text('Mark order #${_getShortId(order.orderId)} as dispatched?'),
              const SizedBox(height: 10),
              Text(
                'Destination: ${order.shopName.isNotEmpty ? order.shopName : order.customerName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (order.shopAddress.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Address: ${order.shopAddress}', style: const TextStyle(fontSize: 12)),
              ],
              const SizedBox(height: 4),
              Text('Quantity: ${_formatter.format(order.quantity)} Eggs'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316), foregroundColor: Colors.white),
              child: const Text('CONFIRM DISPATCH'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await ref.read(databaseServiceProvider).dispatchCustomerOrder(order);
        if (mounted) {
          AppSnackBar.showSuccess(context, 'Order #${_getShortId(order.orderId)} marked as Dispatched!');
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(context, 'Failed to dispatch order: $e');
        }
      }
    }
  }

  Future<void> _handleDeliver(CustomerOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCardSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.task_alt_rounded, color: Color(0xFF22C55E)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Confirm Delivery',
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
              Text('Mark order #${_getShortId(order.orderId)} as successfully delivered?'),
              const SizedBox(height: 10),
              Text(
                'Client: ${order.shopName.isNotEmpty ? order.shopName : order.customerName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Quantity: ${_formatter.format(order.quantity)} Eggs'),
              Text('Total Price: Rs. ${_formatter.format(order.totalPrice.toInt())}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E), foregroundColor: Colors.white),
              child: const Text('MARK DELIVERED'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await ref.read(databaseServiceProvider).deliverCustomerOrder(order);
        if (mounted) {
          AppSnackBar.showSuccess(context, 'Order #${_getShortId(order.orderId)} marked as Delivered!');
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(context, 'Failed to update order: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(allOrdersStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackgroundWarm,
      appBar: AppBar(
        title: const Text('Bulk Orders (B2B)', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // 5-Tab Horizontally Scrollable Filter Bar (Prevents any 360dp overflow)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1B3D) : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.darkPrimaryGold
                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.darkPrimaryGold : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          _filterTabs[idx],
                          style: TextStyle(
                            fontSize: 13,
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
                final filtered = orders.where((o) {
                  final s = o.status.toLowerCase();
                  switch (_selectedFilter) {
                    case 1:
                      return s == 'pending';
                    case 2:
                      return s == 'accepted';
                    case 3:
                      return s == 'dispatched';
                    case 4:
                      return s == 'rejected';
                    case 0:
                    default:
                      return true;
                  }
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 56, color: isDark ? Colors.white24 : Colors.black26),
                        const SizedBox(height: 12),
                        Text(
                          'No ${_filterTabs[_selectedFilter].toLowerCase()} found',
                          style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) => _buildOrderCard(filtered[idx], isDark),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.darkPrimaryGold)),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error loading orders: $err', style: const TextStyle(color: Colors.redAccent)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(CustomerOrder order, bool isDark) {
    Color statusColor;
    Color statusBg;
    final statusLower = order.status.toLowerCase();

    if (statusLower == 'accepted') {
      statusColor = const Color(0xFF0EA5E9);
      statusBg = const Color(0xFF0EA5E9).withOpacity(0.15);
    } else if (statusLower == 'pending') {
      statusColor = AppColors.darkPrimaryGold;
      statusBg = AppColors.darkPrimaryGold.withOpacity(0.15);
    } else if (statusLower == 'dispatched') {
      statusColor = const Color(0xFFF97316);
      statusBg = const Color(0xFFF97316).withOpacity(0.15);
    } else if (statusLower == 'delivered') {
      statusColor = const Color(0xFF22C55E);
      statusBg = const Color(0xFF22C55E).withOpacity(0.15);
    } else if (statusLower == 'rejected' || statusLower == 'cancelled') {
      statusColor = const Color(0xFFEF4444);
      statusBg = const Color(0xFFEF4444).withOpacity(0.15);
    } else {
      statusColor = Colors.grey;
      statusBg = Colors.grey.withOpacity(0.15);
    }

    final displayName = order.shopName.isNotEmpty
        ? order.shopName
        : (order.customerName.isNotEmpty ? order.customerName : 'Bulk Customer');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Shop/Customer Name + Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.darkPrimaryGold.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront_rounded, color: AppColors.darkPrimaryGold, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (order.shopName.isNotEmpty && order.customerName.isNotEmpty)
                      Text(
                        'Owner: ${order.customerName}',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    if (order.timestamp != null)
                      Text(
                        _dateFormat.format(order.timestamp!),
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Contact Details: Phone & Address
          if (order.customerPhone.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 15, color: AppColors.darkPrimaryGold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.customerPhone,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          if (order.shopAddress.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 15, color: AppColors.darkPrimaryGold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.shopAddress,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Order Items & Pricing Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.egg_outlined, size: 18, color: AppColors.darkPrimaryGold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_formatter.format(order.quantity)} Eggs (Rs. ${order.unitPrice.toStringAsFixed(1)})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Rs. ${_formatter.format(order.totalPrice.toInt())}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF22C55E)),
                ),
              ],
            ),
          ),

          // Rejection note if any
          if (order.rejectionReason != null && order.rejectionReason!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Color(0xFFEF4444)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reason: ${order.rejectionReason}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Action Buttons with Confirmations
          if (statusLower == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleReject(order),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleAccept(order),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: const Text('Accept Order', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (statusLower == 'accepted') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleDispatch(order),
                icon: const Icon(Icons.local_shipping_outlined, size: 18),
                label: const Text('Mark as Dispatched', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ] else if (statusLower == 'dispatched') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleDeliver(order),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Mark Delivered', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
