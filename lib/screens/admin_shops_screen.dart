import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme/app_colors.dart';
import '../models/farm_models.dart';
import '../providers/farm_providers.dart';

class AdminShopsScreen extends ConsumerStatefulWidget {
  const AdminShopsScreen({super.key});

  @override
  ConsumerState<AdminShopsScreen> createState() => _AdminShopsScreenState();
}

class _AdminShopsScreenState extends ConsumerState<AdminShopsScreen> {
  late final MapController _mapController;
  final TextEditingController _searchCtrl = TextEditingController();
  String? _selectedShopUid;
  String _searchQuery = '';

  // Default center: Kurunegala / Sri Lanka central region
  static final LatLng _defaultCenter = LatLng(7.4863, 80.3623);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _focusShop(AppUser shop) {
    setState(() {
      _selectedShopUid = shop.uid;
    });

    if (shop.hasGps) {
      _mapController.move(LatLng(shop.latitude!, shop.longitude!), 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopsAsync = ref.watch(customerShopsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackgroundWarm,
      appBar: AppBar(
        title: const Text('Registered Shops', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          shopsAsync.maybeWhen(
            data: (shops) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.darkPrimaryGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkPrimaryGold, width: 1),
                  ),
                  child: Text(
                    '${shops.length} Shops',
                    style: const TextStyle(color: AppColors.darkPrimaryGold, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: shopsAsync.when(
        data: (shops) {
          final filteredShops = shops.where((s) {
            final q = _searchQuery.toLowerCase();
            return s.shopNameOrName.toLowerCase().contains(q) ||
                s.name.toLowerCase().contains(q) ||
                (s.shopAddress ?? '').toLowerCase().contains(q) ||
                s.phone.contains(q);
          }).toList();

          final shopsWithGps = filteredShops.where((s) => s.hasGps).toList();

          return Column(
            children: [
              // 1. Top Section: Interactive Map
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.40,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: shopsWithGps.isNotEmpty
                            ? LatLng(shopsWithGps.first.latitude!, shopsWithGps.first.longitude!)
                            : _defaultCenter,
                        initialZoom: 11.5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.wimalasooriya.wimalasooriya_farm',
                        ),
                        MarkerLayer(
                          markers: shopsWithGps.map((shop) {
                            final isSelected = shop.uid == _selectedShopUid;
                            return Marker(
                              point: LatLng(shop.latitude!, shop.longitude!),
                              width: isSelected ? 64 : 48,
                              height: isSelected ? 64 : 48,
                              child: GestureDetector(
                                onTap: () => _focusShop(shop),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.darkPrimaryGold : const Color(0xFF0B1B3D),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? Colors.white : AppColors.darkPrimaryGold,
                                      width: isSelected ? 3 : 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.storefront_rounded,
                                    size: isSelected ? 32 : 24,
                                    color: isSelected ? const Color(0xFF0B1B3D) : AppColors.darkPrimaryGold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    // Top Overlay: Stats banner
                    Positioned(
                      top: 12,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1B3D).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.darkPrimaryGold.withOpacity(0.7), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.pin_drop_rounded, color: AppColors.darkPrimaryGold, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '${shopsWithGps.length} of ${filteredShops.length} Mapped on GPS',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            if (shopsWithGps.isNotEmpty)
                              InkWell(
                                onTap: () {
                                  _mapController.move(
                                    LatLng(shopsWithGps.first.latitude!, shopsWithGps.first.longitude!),
                                    11.5,
                                  );
                                },
                                child: const Text(
                                  'Reset View',
                                  style: TextStyle(color: AppColors.darkPrimaryGold, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Search Box
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search by shop name, owner, or address...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.darkPrimaryGold, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? AppColors.darkCardSurface : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                    ),
                  ),
                ),
              ),

              // 3. Bottom Section: Scrollable Shop List
              Expanded(
                child: filteredShops.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.store_mall_directory_outlined, size: 48, color: isDark ? Colors.white24 : Colors.black26),
                            const SizedBox(height: 10),
                            Text(
                              _searchQuery.isNotEmpty ? 'No shops match "$_searchQuery"' : 'No customer shops registered yet',
                              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredShops.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, idx) {
                          final shop = filteredShops[idx];
                          final isSelected = shop.uid == _selectedShopUid;

                          return InkWell(
                            onTap: () => _focusShop(shop),
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCardSurface : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.darkPrimaryGold
                                      : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.darkPrimaryGold.withOpacity(0.2)
                                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.storefront_rounded,
                                      size: 24,
                                      color: isSelected ? AppColors.darkPrimaryGold : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          shop.shopNameOrName,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                        ),
                                        if (shop.name.isNotEmpty && shop.name != shop.shopName)
                                          Text(
                                            'Owner: ${shop.name}',
                                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                                          ),
                                        const SizedBox(height: 4),
                                        if (shop.phone.isNotEmpty)
                                          Row(
                                            children: [
                                              const Icon(Icons.phone_outlined, size: 14, color: AppColors.darkPrimaryGold),
                                              const SizedBox(width: 6),
                                              Text(
                                                shop.phone,
                                                style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                                              ),
                                            ],
                                          ),
                                        if (shop.shopAddress != null && shop.shopAddress!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.darkPrimaryGold),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  shop.shopAddress!,
                                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // GPS Badge / Action
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (shop.hasGps)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF22C55E).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFF22C55E), width: 0.8),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.gps_fixed_rounded, size: 12, color: Color(0xFF22C55E)),
                                              SizedBox(width: 4),
                                              Text(
                                                'GPS',
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF22C55E)),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'No GPS',
                                            style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.darkPrimaryGold)),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error loading shops: $err', style: const TextStyle(color: Colors.redAccent)),
          ),
        ),
      ),
    );
  }
}
