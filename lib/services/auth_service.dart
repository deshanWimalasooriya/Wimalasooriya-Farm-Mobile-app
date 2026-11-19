import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/farm_models.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get workersCollection => _firestore.collection('workers');

  /// Safe Employee Account Creation via Secondary Firebase App
  ///
  /// This creates an employee auth account without logging out the currently
  /// authenticated Admin session.
  Future<Map<String, String>> createEmployeeWithAuth({
    required String name,
    required String email,
    required String role,
    required String phone,
    required String nic,
    int age = 28,
    required double monthlySalary,
    String? groupId,
    String? groupName,
    String? qrPayload,
    String? workerId,
    String? initialPassword,
  }) async {
    final generatedPassword = (initialPassword != null && initialPassword.trim().isNotEmpty)
        ? initialPassword.trim()
        : 'Farm@${1000 + Random().nextInt(9000)}';

    FirebaseApp? secondaryApp;
    String authUid;

    try {
      // 1. Fetch Current Firebase Options from default app
      final FirebaseOptions options = Firebase.app().options;

      // 2. Initialize secondary app instance with unique name
      final appName = 'SecondaryAuthApp_${DateTime.now().millisecondsSinceEpoch}';
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: options,
      );

      // 3. Obtain FirebaseAuth instance from secondary app
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // 4. Create user account inside secondary app
      final userCred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: generatedPassword,
      );

      authUid = userCred.user!.uid;
    } catch (e) {
      debugPrint('Secondary Auth provisioning error: $e');
      rethrow;
    } finally {
      // 5. Always delete the secondary app to prevent memory leaks and dangling listeners
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }

    final id = (workerId != null && workerId.isNotEmpty) ? workerId : authUid;
    final payload = qrPayload ?? id;

    final worker = Worker(
      workerId: id,
      name: name.trim(),
      age: age,
      role: role.trim(),
      phone: phone.trim(),
      nic: nic.trim(),
      monthlySalary: monthlySalary,
      groupId: groupId,
      groupName: groupName,
      qrPayload: payload,
      visiblePassword: generatedPassword,
      hasChangedPassword: false,
      joinedDate: DateTime.now(),
      createdAt: DateTime.now(),
    );

    // Save in workers collection
    await workersCollection.doc(id).set(worker.toMap());

    // Save in users collection for RBAC
    await usersCollection.doc(authUid).set({
      'uid': authUid,
      'workerId': id,
      'name': name.trim(),
      'email': email.trim(),
      'role': role.trim(),
      'phone': phone.trim(),
      'nic': nic.trim(),
      'visiblePassword': generatedPassword,
      'hasChangedPassword': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return {
      'workerId': id,
      'authUid': authUid,
      'password': generatedPassword,
      'email': email.trim(),
    };
  }
}
