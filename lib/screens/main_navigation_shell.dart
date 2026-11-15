import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/custom_bottom_nav_bar.dart';
import '../core/widgets/custom_drawer.dart';
import '../core/widgets/hen_icon.dart';
import '../providers/farm_providers.dart';
import 'dashboard_screen.dart';
import 'flock_screen.dart';
import 'home_screen.dart';
import 'finance_screen.dart';
import 'team_labor_screen.dart';
import 'bulk_orders_screen.dart';
import 'fleet_screen.dart';

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
      backgroundColor: const Color(0xFF16264C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.notifications_active_rounded, color: AppColors.darkPrimaryGold, size: 28),
                  SizedBox(width: 12),
                  Text('Farm Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: const Icon(Icons.warning_amber_rounded, color: AppColors.warningYellow),
                title: const Text('Layer Feed Stock Low', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Only 2 days of feed reserve remaining.', style: TextStyle(color: Color(0xFF94A3B8))),
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                leading: const Icon(Icons.shopping_bag_outlined, color: AppColors.darkGreen),
                title: const Text('New Wholesale Order Received', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Colombo Supermarkets requested 5,000 eggs.', style: TextStyle(color: Color(0xFF94A3B8))),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
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

