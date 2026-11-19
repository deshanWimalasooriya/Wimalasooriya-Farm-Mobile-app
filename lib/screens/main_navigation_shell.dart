import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/custom_bottom_nav_bar.dart';
import '../core/widgets/custom_drawer.dart';
import '../core/widgets/hen_icon.dart';
import '../models/farm_models.dart';
import '../providers/farm_providers.dart';
import 'dashboard_screen.dart';
import 'flock_screen.dart';
import 'home_screen.dart';
import 'finance_screen.dart';
import 'team_labor_screen.dart';
import 'bulk_orders_screen.dart';
import 'fleet_screen.dart';
import 'admin_shops_screen.dart';

class MainNavigationShell extends ConsumerStatefulWidget {
  final VoidCallback onLogout;

  const MainNavigationShell({super.key, required this.onLogout});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      _updateConnectionStatus(results);
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _updateConnectionStatus(results);
    } catch (_) {}
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final offline = results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (mounted && offline != _isOffline) {
      setState(() => _isOffline = offline);
    }
  }

  Widget _buildOfflineBanner() {
    if (!_isOffline) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: const Color(0xFFDC2626),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No Internet Connection. Please check your network.',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B1B3D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final notifsAsync = ref.watch(adminNotificationsStreamProvider);
            final dateFormat = DateFormat('MMM dd, hh:mm a');

            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.notifications_active_rounded, color: AppColors.darkPrimaryGold, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Admin Notifications',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      notifsAsync.maybeWhen(
                        data: (notifs) {
                          final unreadCount = notifs.where((n) => !n.isRead).length;
                          if (unreadCount == 0) return const SizedBox.shrink();
                          return TextButton(
                            onPressed: () {
                              ref.read(databaseServiceProvider).markAllNotificationsAsRead('admin');
                            },
                            child: const Text(
                              'Mark all read',
                              style: TextStyle(color: AppColors.darkPrimaryGold, fontSize: 12),
                            ),
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Color(0x22FFFFFF), height: 1),
                  const SizedBox(height: 10),
                  Expanded(
                    child: notifsAsync.when(
                      data: (notifs) {
                        if (notifs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.notifications_off_outlined, color: Colors.white30, size: 48),
                                SizedBox(height: 10),
                                Text('No notifications yet', style: TextStyle(color: Colors.white60)),
                              ],
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: notifs.length,
                          separatorBuilder: (_, __) => const Divider(color: Color(0x15FFFFFF), height: 1),
                          itemBuilder: (ctx, idx) {
                            final n = notifs[idx];
                            IconData leadingIcon = Icons.notifications_none_rounded;
                            Color iconColor = AppColors.darkPrimaryGold;
                            if (n.type == 'order_placed') {
                              leadingIcon = Icons.shopping_bag_outlined;
                              iconColor = AppColors.darkPrimaryGold;
                            } else if (n.type == 'order_accepted') {
                              leadingIcon = Icons.check_circle_outline;
                              iconColor = const Color(0xFF0EA5E9);
                            }

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: iconColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(leadingIcon, color: iconColor, size: 20),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (!n.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text(
                                    n.message,
                                    style: TextStyle(
                                      color: n.isRead ? Colors.white60 : Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (n.timestamp != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      dateFormat.format(n.timestamp!),
                                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                                    ),
                                  ],
                                ],
                              ),
                              onTap: () {
                                if (!n.isRead) {
                                  ref.read(databaseServiceProvider).markNotificationAsRead(n.id);
                                }
                                if (n.orderId != null) {
                                  Navigator.pop(ctx);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const BulkOrdersScreen()),
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: AppColors.darkPrimaryGold),
                      ),
                      error: (err, _) => Center(
                        child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(activeNavTabProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    final pages = [
      DashboardScreen(onOpenNotifications: () => _showNotificationsSheet(context)),
      FlockScreen(onOpenNotifications: () => _showNotificationsSheet(context)),
      HomeScreen(onOpenNotifications: () => _showNotificationsSheet(context)),
      FinanceScreen(onOpenNotifications: () => _showNotificationsSheet(context)),
      // Tab 4 (Menu) triggers drawer, or shows HomeScreen as fallback
      HomeScreen(onOpenNotifications: () => _showNotificationsSheet(context)),
    ];

    if (isTablet) {
      // Tablet Layout: Persistent Left Navigation Rail
      return Scaffold(
        key: _scaffoldKey,
        drawer: CustomNavigationDrawer(
          onOpenTeamLabor: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamLaborScreen())),
          onOpenShops: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminShopsScreen())),
          onOpenBulkOrders: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkOrdersScreen())),
          onOpenFleet: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FleetScreen())),
          onLogout: widget.onLogout,
        ),
        body: Column(
          children: [
            _buildOfflineBanner(),
            Expanded(
              child: Container(
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
                child: Row(
                  children: [
                    NavigationRail(
                      backgroundColor: const Color(0xFF0B1B3D),
                      selectedIndex: activeTab.clamp(0, 3),
                      onDestinationSelected: (idx) {
                        ref.read(activeNavTabProvider.notifier).state = idx;
                      },
                      leading: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: IconButton(
                          icon: const Icon(Icons.menu_rounded, color: AppColors.darkPrimaryGold, size: 30),
                          onPressed: _openDrawer,
                        ),
                      ),
                      selectedIconTheme: const IconThemeData(color: Color(0xFF0B1B3D)),
                      selectedLabelTextStyle: const TextStyle(color: AppColors.darkPrimaryGold, fontWeight: FontWeight.bold),
                      unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.grid_view_rounded, color: Colors.white),
                          selectedIcon: CircleAvatar(
                            backgroundColor: AppColors.darkPrimaryGold,
                            child: Icon(Icons.grid_view_rounded, color: Color(0xFF0B1B3D)),
                          ),
                          label: Text('Dashboard'),
                        ),
                        NavigationRailDestination(
                          icon: HenIcon(size: 24, color: Colors.white),
                          selectedIcon: CircleAvatar(
                            backgroundColor: AppColors.darkPrimaryGold,
                            child: HenIcon(size: 24, color: Color(0xFF0B1B3D)),
                          ),
                          label: Text('Flock'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.home_rounded, color: Colors.white),
                          selectedIcon: CircleAvatar(
                            backgroundColor: AppColors.darkPrimaryGold,
                            child: Icon(Icons.home_rounded, color: Color(0xFF0B1B3D)),
                          ),
                          label: Text('Home'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.monetization_on_outlined, color: Colors.white),
                          selectedIcon: CircleAvatar(
                            backgroundColor: AppColors.darkPrimaryGold,
                            child: Icon(Icons.monetization_on_outlined, color: Color(0xFF0B1B3D)),
                          ),
                          label: Text('Finance'),
                        ),
                      ],
                    ),
                    const VerticalDivider(thickness: 1, width: 1, color: Color(0x22FFFFFF)),
                    Expanded(
                      child: IndexedStack(
                        index: activeTab.clamp(0, 3),
                        children: pages,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile Layout: Single column with Animated Morphing 5-Tab Bottom Bar
    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomNavigationDrawer(
        onOpenTeamLabor: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamLaborScreen())),
        onOpenShops: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminShopsScreen())),
        onOpenBulkOrders: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkOrdersScreen())),
        onOpenFleet: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FleetScreen())),
        onLogout: widget.onLogout,
      ),
      body: Column(
        children: [
          _buildOfflineBanner(),
          Expanded(
            child: Container(
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
              child: IndexedStack(
                index: activeTab.clamp(0, 3),
                children: pages,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomCurvedNavBar(
        selectedIndex: activeTab,
        onTabSelected: (index) {
          ref.read(activeNavTabProvider.notifier).state = index;
        },
        onOpenMenu: _openDrawer,
      ),
    );
  }
}

