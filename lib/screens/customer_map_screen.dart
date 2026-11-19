import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme/app_colors.dart';
import '../providers/farm_providers.dart';
import '../utils/app_snackbar.dart';

class CustomerMapScreen extends ConsumerStatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialShopName;
  final String? initialShopAddress;
  final bool isPickerOnly;

  const CustomerMapScreen({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialShopName,
    this.initialShopAddress,
    this.isPickerOnly = false,
  });

  @override
  ConsumerState<CustomerMapScreen> createState() => _CustomerMapScreenState();
}

class _CustomerMapScreenState extends ConsumerState<CustomerMapScreen> {
  late MapController _mapController;
  late LatLng _selectedPoint;
  late TextEditingController _shopNameCtrl;
  late TextEditingController _shopAddressCtrl;
  bool _isSaving = false;
  bool _initialized = false;
  bool _isNorthLocked = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedPoint = LatLng(
      widget.initialLat ?? 7.4675,
      widget.initialLng ?? 80.6234,
    );
    _shopNameCtrl = TextEditingController(text: widget.initialShopName ?? '');
    _shopAddressCtrl = TextEditingController(text: widget.initialShopAddress ?? '');
  }

  @override
  void dispose() {
    _mapController.dispose();
    _shopNameCtrl.dispose();
    _shopAddressCtrl.dispose();
    super.dispose();
  }

  void _showCorporateSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      AppSnackBar.showError(context, message);
    } else {
      AppSnackBar.showSuccess(context, message);
    }
  }

  Future<void> _handleSaveLocation() async {
    final shopName = _shopNameCtrl.text.trim();
    final shopAddress = _shopAddressCtrl.text.trim();

    if (shopName.isEmpty) {
      _showCorporateSnackBar('Please enter your Shop Name', isError: true);
      return;
    }

    if (widget.isPickerOnly) {
      Navigator.pop(context, {
        'latitude': _selectedPoint.latitude,
        'longitude': _selectedPoint.longitude,
        'shopName': shopName,
        'shopAddress': shopAddress,
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showCorporateSnackBar('User not logged in', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final db = ref.read(databaseServiceProvider);
      await db.updateUserShopLocation(
        uid: user.uid,
        shopName: shopName,
        shopAddress: shopAddress,
        latitude: _selectedPoint.latitude,
        longitude: _selectedPoint.longitude,
      );

      ref.invalidate(currentUserStreamProvider);

      _showCorporateSnackBar('Shop location and address updated successfully!');
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted && Navigator.canPop(context)) Navigator.pop(context);
        });
      }
    } catch (e) {
      _showCorporateSnackBar('Failed to save location: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserAsync = ref.watch(currentUserStreamProvider);

    // Auto-populate from currentUser if available and not yet set
    if (!_initialized && !widget.isPickerOnly) {
      final user = currentUserAsync.value;
      if (user != null) {
        if (user.latitude != null && user.longitude != null) {
          _selectedPoint = LatLng(user.latitude!, user.longitude!);
        }
        if (_shopNameCtrl.text.isEmpty && user.shopName != null) {
          _shopNameCtrl.text = user.shopName!;
        }
        if (_shopAddressCtrl.text.isEmpty && user.shopAddress != null) {
          _shopAddressCtrl.text = user.shopAddress!;
        }
        _initialized = true;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isPickerOnly ? 'Pin Shop Location' : 'Shop Location & GPS',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: isDark ? const Color(0xFF0B1B3D) : AppColors.lightPrimaryNavy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Center on Pin',
            onPressed: () {
              _mapController.move(_selectedPoint, 15.0);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // OpenStreetMap Tile View
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedPoint,
                    initialZoom: 14.0,
                    interactionOptions: InteractionOptions(
                      flags: _isNorthLocked
                          ? (InteractiveFlag.all & ~InteractiveFlag.rotate)
                          : InteractiveFlag.all,
                    ),
                    onTap: (tapPosition, point) {
                      setState(() {
                        _selectedPoint = point;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.wimalasooriya.wimalasooriya_farm',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedPoint,
                          width: 60,
                          height: 60,
                          child: const Column(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 44,
                                color: Color(0xFFDC2626),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Instruction Pill
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1B3D).withOpacity(0.88),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.darkPrimaryGold, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_rounded, color: AppColors.darkPrimaryGold, size: 16),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Tap anywhere on map to set shop pin',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Floating Compass / North-Lock Button
                Positioned(
                  top: 58,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isNorthLocked = !_isNorthLocked;
                        });
                        _mapController.rotate(0.0);
                        AppSnackBar.showInfo(
                          context,
                          _isNorthLocked ? 'Map locked to True North (0°)' : 'Map rotation unlocked',
                        );
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _isNorthLocked ? AppColors.darkPrimaryGold : const Color(0xFF0B1B3D).withOpacity(0.9),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.darkPrimaryGold,
                            width: _isNorthLocked ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isNorthLocked ? Icons.explore : Icons.explore_outlined,
                          color: _isNorthLocked ? const Color(0xFF0B1B3D) : AppColors.darkPrimaryGold,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Details & Action Card
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F2656) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // GPS Readout
                  Row(
                    children: [
                      const Icon(Icons.gps_fixed_rounded, size: 14, color: AppColors.darkPrimaryGold),
                      const SizedBox(width: 6),
                      Text(
                        'GPS: ${_selectedPoint.latitude.toStringAsFixed(5)}, ${_selectedPoint.longitude.toStringAsFixed(5)}',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Shop Name Field
                  TextField(
                    controller: _shopNameCtrl,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Shop / Business Name *',
                      labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                      prefixIcon: const Icon(Icons.storefront_outlined, color: AppColors.darkPrimaryGold, size: 20),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF16264C) : const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Shop Address Field
                  TextField(
                    controller: _shopAddressCtrl,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Delivery Address',
                      labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                      prefixIcon: const Icon(Icons.pin_drop_outlined, color: AppColors.darkPrimaryGold, size: 20),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF16264C) : const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Save Button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkPrimaryGold,
                        foregroundColor: const Color(0xFF0B1B3D),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Color(0xFF0B1B3D), strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded, size: 20),
                      label: Text(
                        _isSaving
                            ? 'Saving Location...'
                            : (widget.isPickerOnly ? 'Confirm Pinned Location' : 'Save Shop Location'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: _isSaving ? null : _handleSaveLocation,
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
}
