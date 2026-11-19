import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants/app_assets.dart';
import '../core/theme/app_colors.dart';
import '../models/farm_models.dart';
import '../providers/farm_providers.dart';
import '../utils/app_snackbar.dart';

/// Helper to generate the structured JSON string for the worker QR code payload.
String buildWorkerQrPayload(Worker worker) {
  return jsonEncode({
    'empId': worker.workerId,
    'name': worker.name,
    'nic': worker.nic,
    'role': worker.role,
    'group': worker.groupName ?? 'Unassigned',
    'phone': worker.phone,
  });
}

/// Printable ID Card UI Component designed to CR80 Standard Ratio (320 x 500).
/// Dynamically fetches Company Details from the farm_settings Firestore stream.
class WorkerIdCardPreview extends ConsumerWidget {
  final Worker worker;

  const WorkerIdCardPreview({super.key, required this.worker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(farmSettingsStreamProvider);
    final settings = settingsAsync.value ?? FarmSettings();
    final companyName = settings.companyName.isNotEmpty ? settings.companyName : 'Wimalasooriya Farms (Pvt) Ltd';
    final address = settings.address.isNotEmpty ? settings.address : 'Kurunegala, Sri Lanka';
    final contactNumber = settings.contactNumber.isNotEmpty ? settings.contactNumber : '+94 77 123 4567';
    final qrPayload = buildWorkerQrPayload(worker);

    return Container(
      width: 320,
      height: 500,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF0B1B3D), width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: [
            // Top Lanyard Slot Simulation
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 44,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
            ),
            const SizedBox(height: 6),

            // Header Section: Official Logo & Company Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.darkPrimaryGold, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        AppAssets.logo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.business_rounded,
                          color: Color(0xFF0B1B3D),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          companyName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0B1B3D),
                            letterSpacing: 0.6,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        const Text(
                          'EMPLOYEE IDENTITY CARD',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkPrimaryGold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Accent Ribbon Divider
            Container(
              height: 2,
              width: double.infinity,
              color: AppColors.darkPrimaryGold,
            ),
            const SizedBox(height: 10),

            // Profile Section: Avatar, Name, Designation & ID
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Circular Worker Photo / Avatar
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0B1B3D),
                      border: Border.all(color: AppColors.darkPrimaryGold, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.darkPrimaryGold.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: worker.photoUrl != null && worker.photoUrl!.isNotEmpty
                          ? Image.network(
                              worker.photoUrl!,
                              fit: BoxFit.cover,
                              width: 68,
                              height: 68,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person,
                                color: AppColors.darkPrimaryGold,
                                size: 38,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: AppColors.darkPrimaryGold,
                              size: 38,
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Worker Name
                  Text(
                    worker.name.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0B1B3D),
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Role / Designation Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1B3D),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      worker.role.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.darkPrimaryGold,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Employee ID
                  Text(
                    'EMP ID: ${worker.workerId}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Compact Metadata Row (NIC & Team)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (worker.nic.isNotEmpty) ...[
                        Text(
                          'NIC: ${worker.nic}',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        'Team: ${worker.groupName ?? "Main"}',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // QR Code Section (High-Contrast Printable Format)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF0B1B3D), width: 1.5),
              ),
              child: QrImageView(
                data: qrPayload,
                version: QrVersions.auto,
                size: 100.0,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF0B1B3D),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF0B1B3D),
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Scan to Verify Official Credentials',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                letterSpacing: 0.3,
              ),
            ),

            const Spacer(),

            // Footer Section: Dynamic from farm_settings
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              color: const Color(0xFF0B1B3D),
              child: Column(
                children: [
                  Text(
                    'Authorized by $companyName',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '$address • Hotline: $contactNumber',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.darkPrimaryGold,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal Dialog that wraps the ID Card with Screenshot & Share/Print capabilities.
class WorkerIdCardDialog extends StatefulWidget {
  final Worker worker;

  const WorkerIdCardDialog({super.key, required this.worker});

  static Future<void> show(BuildContext context, Worker worker) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => WorkerIdCardDialog(worker: worker),
    );
  }

  @override
  State<WorkerIdCardDialog> createState() => _WorkerIdCardDialogState();
}

class _WorkerIdCardDialogState extends State<WorkerIdCardDialog> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturing = false;

  Future<void> _shareOrPrintIdCard() async {
    setState(() => _isCapturing = true);
    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 60),
        pixelRatio: 2.5, // High resolution for crisp printing
      );

      if (imageBytes == null) {
        throw Exception('Failed to capture ID card snapshot');
      }

      final tempDir = await getTemporaryDirectory();
      final sanitizedId = widget.worker.workerId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final filePath = '${tempDir.path}/ID_Card_$sanitizedId.png';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(filePath, mimeType: 'image/png', name: 'ID_Card_$sanitizedId.png')],
        text: 'Wimalasooriya Farms Employee ID Card — ${widget.worker.name} (${widget.worker.workerId})',
        subject: 'Employee ID Card — ${widget.worker.name}',
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error sharing ID card: $e');
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Captured Widget Area
            Screenshot(
              controller: _screenshotController,
              child: WorkerIdCardPreview(worker: widget.worker),
            ),
            const SizedBox(height: 20),

            // Action Buttons: Share / Print & Close
            SizedBox(
              width: 320,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: _isCapturing ? null : _shareOrPrintIdCard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkPrimaryGold,
                        foregroundColor: const Color(0xFF0B1B3D),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      icon: _isCapturing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0B1B3D),
                              ),
                            )
                          : const Icon(Icons.print_rounded, size: 20),
                      label: Text(
                        _isCapturing ? 'GENERATING...' : 'Share / Print ID Card',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white60, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
