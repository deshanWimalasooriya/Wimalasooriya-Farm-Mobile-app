import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_assets.dart';
import '../core/theme/app_colors.dart';
import '../models/farm_models.dart';
import '../providers/farm_providers.dart';
import 'customer_history_screen.dart';
import 'customer_map_screen.dart';
import 'user_profile_screen.dart';
import 'login_screen.dart';
import '../utils/app_snackbar.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onLogout;

  const CustomerHomeScreen({super.key, this.onLogout});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  final _quantityController = TextEditingController(text: '500');
  int _quantity = 500;
  bool _isSubmitting = false;
  final _currencyFormatter = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_onQuantityChanged);
  }

  @override
  void dispose() {
    _quantityController.removeListener(_onQuantityChanged);
    _quantityController.dispose();
    super.dispose();
  }

  void _onQuantityChanged() {
    final parsed = int.tryParse(_quantityController.text.replaceAll(',', ''));
    if (parsed != null && parsed != _quantity) {
      setState(() {
        _quantity = parsed;
      });
    }
  }

  void _adjustQuantity(int delta) {
    final newQty = (_quantity + delta).clamp(50, 500000);
    _quantityController.text = newQty.toString();
    setState(() {
      _quantity = newQty;
    });
  }

  void _setPresetQuantity(int preset) {
    _quantityController.text = preset.toString();
    setState(() {
      _quantity = preset;
    });
  }

  void _showCorporateSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      AppSnackBar.showError(context, message);
    } else {
      AppSnackBar.showSuccess(context, message);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16264C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of your customer account?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('LOGOUT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      await FirebaseAuth.instance.signOut();
      ref.invalidate(authUserProvider);
      ref.invalidate(currentUserStreamProvider);

      if (widget.onLogout != null) {
        widget.onLogout!();
      } else if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginScreen(
              onLoginSuccess: () {},
            ),
          ),
          (route) => false,
        );
      }
    }
  }

  Future<void> _handlePlaceOrder(AppUser user, double unitPrice) async {
    if (_quantity < 50) {
      _showCorporateSnackBar('Minimum order quantity is 50 eggs', isError: true);
      return;
    }

    final totalPrice = _quantity * unitPrice;
    final shopName = user.shopName ?? 'Shop / Commercial Customer';
    final shopAddress = user.shopAddress ?? 'Pickup / Registered Address';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16264C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.shopping_bag_outlined, color: AppColors.darkPrimaryGold, size: 22),
            SizedBox(width: 8),
            Text('Confirm Egg Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please verify your order details before placing:', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 14),
            _buildConfirmationRow('Egg Quantity:', '${_currencyFormatter.format(_quantity)} Eggs'),
            _buildConfirmationRow('Unit Price:', 'Rs. ${unitPrice.toStringAsFixed(2)}'),
            _buildConfirmationRow('Total Amount:', 'Rs. ${_currencyFormatter.format(totalPrice.toInt())}', isBold: true),
            const Divider(color: Color(0x33FFFFFF), height: 16),
            _buildConfirmationRow('Destination:', shopName),
            if (shopAddress.isNotEmpty)
              _buildConfirmationRow('Address:', shopAddress),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkPrimaryGold,
              foregroundColor: const Color(0xFF0B1B3D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CONFIRM ORDER', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      final db = ref.read(databaseServiceProvider);
      final newOrderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

      final newOrder = CustomerOrder(
        orderId: newOrderId,
        customerId: user.uid,
        customerName: user.name,
        customerPhone: user.phone,
        shopName: shopName,
        shopAddress: shopAddress,
        latitude: user.latitude,
        longitude: user.longitude,
        quantity: _quantity,
        unitPrice: unitPrice,
        totalPrice: totalPrice,
        status: 'Pending',
        timestamp: DateTime.now(),
      );

      await db.placeCustomerOrder(newOrder);

      ref.invalidate(customerOrdersStreamProvider);
      ref.invalidate(allOrdersStreamProvider);

      _showCorporateSnackBar('Order placed successfully! ID: #${newOrderId.substring(0, 8)}');
      setState(() {
        _quantity = 500;
        _quantityController.text = '500';
      });
    } catch (e) {
      _showCorporateSnackBar('Failed to place order: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildConfirmationRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isBold ? AppColors.darkPrimaryGold : Colors.white,
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDrawer(BuildContext context, AppUser user, bool isDark) {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0B1B3D) : Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.6, -0.6),
                radius: 1.2,
                colors: [
                  Color(0xFF0F2656),
                  Color(0xFF0B1B3D),
                  Color(0xFF071229),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.darkPrimaryGold, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset(AppAssets.logo, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user.name.isNotEmpty ? user.name : 'Customer',
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  user.shopName?.isNotEmpty == true ? user.shopName! : 'Wimalasooriya Farm Customer',
                  style: const TextStyle(color: AppColors.darkPrimaryGold, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ListTile(
                  leading: const Icon(Icons.shopping_bag_outlined, color: AppColors.darkPrimaryGold),
                  title: const Text('Place Order', style: TextStyle(fontWeight: FontWeight.w600)),
                  selected: true,
                  selectedTileColor: isDark ? const Color(0x33C59B27) : const Color(0x15C59B27),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined, color: AppColors.darkPrimaryGold),
                  title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerHistoryScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined, color: AppColors.darkPrimaryGold),
                  title: const Text('Shop Location', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerMapScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded, color: AppColors.darkPrimaryGold),
                  title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen()));
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            title: const Text('Log Out', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              _handleLogout();
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserAsync = ref.watch(currentUserStreamProvider);
    final settingsAsync = ref.watch(farmSettingsStreamProvider);

    final user = currentUserAsync.value ??
        AppUser(
          uid: FirebaseAuth.instance.currentUser?.uid ?? 'guest',
          name: 'Valued Customer',
          email: FirebaseAuth.instance.currentUser?.email ?? '',
          role: 'Customer',
        );

    final unitEggPrice = settingsAsync.value?.unitEggPrice ?? 40.0;
    final calculatedTotal = _quantity * unitEggPrice;
    final notifsAsync = ref.watch(customerNotificationsStreamProvider);
    final unreadNotifs = notifsAsync.value?.where((n) => !n.isRead).toList() ?? [];

    return Scaffold(
      drawer: _buildCustomerDrawer(context, user, isDark),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0B1B3D) : AppColors.lightPrimaryNavy,
        foregroundColor: Colors.white,
        title: const Text(
          'Customer Portal',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          // Circular Logo wrapped in GestureDetector to open drawer
          Builder(
            builder: (ctx) => Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.darkPrimaryGold, width: 1.5),
                  ),
                  child: ClipOval(
                    child: Image.asset(AppAssets.logo, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ),
        ],
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer Notification Banner (if any unread notifications)
              if (unreadNotifs.isNotEmpty) ...[
                ...unreadNotifs.map((n) {
                  final isAccepted = n.type == 'order_accepted';
                  final bannerColor = isAccepted ? const Color(0xFF0EA5E9) : const Color(0xFFEF4444);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: bannerColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: bannerColor, width: 1.2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isAccepted ? Icons.check_circle_rounded : Icons.info_rounded,
                          color: bannerColor,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                n.message,
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(Icons.close_rounded, size: 18, color: isDark ? Colors.white60 : Colors.black45),
                          tooltip: 'Dismiss',
                          onPressed: () {
                            ref.read(databaseServiceProvider).markNotificationAsRead(n.id);
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],

              // Live Price Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC59B27), Color(0xFFE5B73B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC59B27).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.trending_up_rounded, color: Color(0xFF0B1B3D), size: 26),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Unit Egg Price",
                              style: TextStyle(
                                color: Color(0xFF0B1B3D),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Standard Commercial Grade',
                              style: TextStyle(color: Color(0x990B1B3D), fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      'Rs. ${unitEggPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF0B1B3D),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Order Configuration Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF16264C) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, color: AppColors.darkPrimaryGold, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Place Commercial Order',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Minimum commercial order quantity: 50 eggs',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                    const SizedBox(height: 20),

                    // Interactive Quantity Stepper Row
                    Row(
                      children: [
                        _buildStepperButton(
                          icon: Icons.remove,
                          label: '-100',
                          onPressed: () => _adjustQuantity(-100),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 6),
                        _buildStepperButton(
                          icon: Icons.remove,
                          label: '-10',
                          onPressed: () => _adjustQuantity(-10),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 10),

                        // Center Editable Field
                        Expanded(
                          child: TextField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                                ),
                              ),
                              suffixText: 'Eggs',
                              suffixStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),
                        _buildStepperButton(
                          icon: Icons.add,
                          label: '+10',
                          onPressed: () => _adjustQuantity(10),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 6),
                        _buildStepperButton(
                          icon: Icons.add,
                          label: '+100',
                          onPressed: () => _adjustQuantity(100),
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quick Preset Chips
                    const Text('Quick Select Presets:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [100, 250, 500, 1000, 2500, 5000].map((preset) {
                        final isSelected = _quantity == preset;
                        return InkWell(
                          onTap: () => _setPresetQuantity(preset),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.darkPrimaryGold
                                  : (isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.darkPrimaryGold
                                    : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                              ),
                            ),
                            child: Text(
                              '${_currencyFormatter.format(preset)} Eggs',
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF0B1B3D) : (isDark ? Colors.white : Colors.black87),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Dynamic Price Calculation Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0x33C59B27) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Calculation:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                              Text(
                                '${_currencyFormatter.format(_quantity)} x Rs. ${unitEggPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black54,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 18, color: Color(0x22FFFFFF)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Estimated Cost:',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Rs. ${_currencyFormatter.format(calculatedTotal.toInt())}',
                                style: const TextStyle(
                                  color: AppColors.darkPrimaryGold,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Destination Shop Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F2656) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.storefront, size: 16, color: AppColors.darkPrimaryGold),
                                  SizedBox(width: 6),
                                  Text(
                                    'Delivery Destination',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CustomerMapScreen()),
                                ),
                                child: const Text(
                                  'Change Location',
                                  style: TextStyle(
                                    color: AppColors.darkPrimaryGold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user.shopName?.isNotEmpty == true ? user.shopName! : 'Shop Location Not Specified',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (user.shopAddress?.isNotEmpty == true)
                            Text(
                              user.shopAddress!,
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            ),
                          if (user.latitude == null || user.longitude == null) ...[
                            const SizedBox(height: 6),
                            const Text(
                              '⚠️ GPS coordinates missing. Tap "Change Location" to pin your shop on OpenStreetMap.',
                              style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Place Order Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkPrimaryGold,
                          foregroundColor: const Color(0xFF0B1B3D),
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Color(0xFF0B1B3D), strokeWidth: 2.5),
                              )
                            : const Icon(Icons.check_circle_rounded, size: 22),
                        label: Text(
                          _isSubmitting ? 'Placing Order...' : 'PLACE ORDER NOW',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        onPressed: _isSubmitting ? null : () => _handlePlaceOrder(user, unitEggPrice),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // View Past Orders Quick Link Card
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerHistoryScreen()),
                ),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF16264C) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.history_rounded, color: AppColors.darkPrimaryGold, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order Tracking & History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('Track live status and view past purchases', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B1B3D) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
