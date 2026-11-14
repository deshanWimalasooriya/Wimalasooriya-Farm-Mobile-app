import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../models/farm_models.dart';
import '../providers/farm_providers.dart';

class BulkOrdersScreen extends ConsumerStatefulWidget {
  const BulkOrdersScreen({super.key});

  @override
  ConsumerState<BulkOrdersScreen> createState() => _BulkOrdersScreenState();
}

class _BulkOrdersScreenState extends ConsumerState<BulkOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formatter = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(bulkOrdersStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackgroundWarm,
      appBar: AppBar(
        title: const Text('Bulk Orders (B2B)', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.darkPrimaryGold,
          labelColor: AppColors.darkPrimaryGold,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Processing'),
            Tab(text: 'Dispatched'),
          ],
        ),
      ),
      body: ordersAsync.when(
        data: (orders) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersList(orders.where((o) => o.status == 'Pending').toList(), isDark),
              _buildOrdersList(orders.where((o) => o.status == 'Processing').toList(), isDark),
              _buildOrdersList(orders.where((o) => o.status == 'Dispatched').toList(), isDark),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.darkPrimaryGold)),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white70))),
      ),
    );
  }

  Widget _buildOrdersList(List<BulkOrder> list, bool isDark) {
    if (list.isEmpty) {
      return const Center(child: Text('No orders in this category', style: TextStyle(color: Colors.white60)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (ctx, idx) {
        final order = list[idx];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order.clientName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.darkPrimaryGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.darkPrimaryGold),
                    ),
                    child: Text(
                      order.status,
                      style: const TextStyle(color: AppColors.darkPrimaryGold, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.egg_outlined, size: 20, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text('${_formatter.format(order.eggQuantity)} Eggs', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(
                    'Rs. ${_formatter.format(order.totalPrice.toInt())}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF22C55E)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (order.status == 'Pending')
                    TextButton(
                      onPressed: () {
                        ref.read(databaseServiceProvider).updateOrderStatus(order.id, 'Processing');
                      },
                      child: const Text('Mark Processing'),
                    ),
                  if (order.status == 'Processing')
                    ElevatedButton(
                      onPressed: () {
                        ref.read(databaseServiceProvider).updateOrderStatus(order.id, 'Dispatched');
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkGreen, foregroundColor: Colors.white),
                      child: const Text('Mark Dispatched'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

