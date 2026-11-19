import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'auth_service.dart';
import '../models/farm_models.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get farmMetricsCollection => _firestore.collection('farm_metrics');
  CollectionReference get flockLedgerCollection => _firestore.collection('flock_ledger');
  CollectionReference get eggLogsCollection => _firestore.collection('egg_logs');
  CollectionReference get feedMedicineCollection => _firestore.collection('feed_medicine_logs');
  CollectionReference get financialLedgerCollection => _firestore.collection('financial_ledger');
  CollectionReference get workersCollection => _firestore.collection('workers');
  CollectionReference get laborGroupsCollection => _firestore.collection('labor_groups');
  CollectionReference get salaryPaymentsCollection => _firestore.collection('salary_payments');
  CollectionReference get dailyTasksCollection => _firestore.collection('daily_tasks');
  CollectionReference get bulkOrdersCollection => _firestore.collection('bulk_orders');
  CollectionReference get vehiclesCollection => _firestore.collection('vehicles');
  CollectionReference get vehicleGroupsCollection => _firestore.collection('vehicle_groups');
  CollectionReference get farmSettingsCollection => _firestore.collection('farm_settings');
  CollectionReference get ordersCollection => _firestore.collection('orders');
  CollectionReference get notificationsCollection => _firestore.collection('notifications');

  // ==================== USER PROFILE ====================
  Stream<AppUser> streamCurrentUser([String? uid]) {
    final activeUid = uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (activeUid == null || activeUid.isEmpty) {
      return Stream.value(
        AppUser(
          uid: 'unauthenticated',
          name: 'Guest User',
          email: '',
          role: 'Customer',
        ),
      );
    }

    return usersCollection.doc(activeUid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }

      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser != null && authUser.email == 'deshanwimalasooriya000@gmail.com') {
        return AppUser(
          uid: activeUid,
          name: 'Deshan Wimalasooriya',
          email: 'deshanwimalasooriya000@gmail.com',
          role: 'Admin / Manager',
          phone: '+94 77 123 4567',
          nic: '199214502341',
          farmBranch: 'Main Farm — Kurunegala',
        );
      }

      return AppUser(
        uid: activeUid,
        name: authUser?.displayName ?? (authUser?.email != null ? authUser!.email!.split('@').first : 'Customer'),
        email: authUser?.email ?? '',
        role: 'Customer',
        phone: authUser?.phoneNumber ?? '',
      );
    });
  }

  Future<void> ensureAdminProfileSeeded({required String uid, String? email}) async {
    final adminEmail = email ?? 'deshanwimalasooriya000@gmail.com';
    final userDoc = await usersCollection.doc(uid).get();
    if (!userDoc.exists) {
      await usersCollection.doc(uid).set({
        'email': adminEmail,
        'name': 'Deshan Wimalasooriya',
        'role': 'Admin / Manager',
        'phone': '+94 77 123 4567',
        'nic': '199214502341',
        'farmBranch': 'Main Farm — Kurunegala',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Keep 'current_user' synced
    final currentDoc = await usersCollection.doc('current_user').get();
    if (!currentDoc.exists) {
      await usersCollection.doc('current_user').set({
        'email': adminEmail,
        'name': 'Deshan Wimalasooriya',
        'role': 'Admin / Manager',
        'phone': '+94 77 123 4567',
        'nic': '199214502341',
        'farmBranch': 'Main Farm — Kurunegala',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> updateUserProfile(AppUser user) async {
    await usersCollection.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  // ==================== FARM METRICS ====================
  Stream<FarmMetrics> streamFarmMetrics() {
    return farmMetricsCollection.doc('current').snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return FarmMetrics.fromMap(doc.data() as Map<String, dynamic>);
      }
      return FarmMetrics(
        currentHenCount: 0,
        todayEggCount: 0,
        feedPacketStock: 0,
        unitEggPrice: 40.0,
      );
    });
  }

  Future<void> updateUnitEggPrice(double price) async {
    await farmMetricsCollection.doc('current').set({
      'unitEggPrice': price,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ==================== FLOCK LEDGER ====================
  Future<void> recordFlockChange({
    required String action, // 'add' | 'remove'
    required int count,
    required String reason,
    required String loggedBy,
  }) async {
    final batch = _firestore.batch();
    final newEntryRef = flockLedgerCollection.doc();

    batch.set(newEntryRef, {
      'action': action,
      'count': count,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
      'loggedBy': loggedBy,
    });

    final metricsDoc = farmMetricsCollection.doc('current');
    final delta = action == 'add' ? count : -count;
    batch.set(
      metricsDoc,
      {
        'currentHenCount': FieldValue.increment(delta),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<void> resetHenCountToZero({required String loggedBy}) async {
    final batch = _firestore.batch();
    final newEntryRef = flockLedgerCollection.doc();

    batch.set(newEntryRef, {
      'action': 'remove',
      'count': 0,
      'reason': 'Reset to 0',
      'timestamp': FieldValue.serverTimestamp(),
      'loggedBy': loggedBy,
    });

    final metricsDoc = farmMetricsCollection.doc('current');
    batch.set(
      metricsDoc,
      {
        'currentHenCount': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Stream<List<FlockLedgerEntry>> streamFlockLedger() {
    return flockLedgerCollection
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return FlockLedgerEntry.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // ==================== EGG LOGS & PRODUCTION ====================
  Stream<List<EggLogEntry>> streamEggLogs() {
    return eggLogsCollection
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return EggLogEntry.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> recordEggProduction({
    required int producedCount,
    required String loggedBy,
  }) async {
    final batch = _firestore.batch();
    final eggLogRef = eggLogsCollection.doc();

    batch.set(eggLogRef, {
      'producedCount': producedCount,
      'soldCount': 0,
      'revenue': 0.0,
      'timestamp': FieldValue.serverTimestamp(),
      'loggedBy': loggedBy,
    });

    final metricsDoc = farmMetricsCollection.doc('current');
    batch.set(
      metricsDoc,
      {
        'todayEggCount': producedCount,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<void> recordEggSale({
    required int count,
    required double unitPrice,
    required String loggedBy,
  }) async {
    final double calculatedIncome = count * unitPrice;
    final batch = _firestore.batch();

    // 1. Financial Ledger Entry
    final financeRef = financialLedgerCollection.doc();
    batch.set(financeRef, {
      'type': 'income',
      'category': 'Eggs',
      'amount': calculatedIncome,
      'description': 'Egg Sales ($count eggs @ Rs. ${unitPrice.toStringAsFixed(2)})',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Egg Log Entry
    final eggLogRef = eggLogsCollection.doc();
    batch.set(eggLogRef, {
      'producedCount': 0,
      'soldCount': count,
      'revenue': calculatedIncome,
      'timestamp': FieldValue.serverTimestamp(),
      'loggedBy': loggedBy,
    });

    // 3. Deduct sold quantity from farm_metrics current document so egg inventory remains accurate
    final metricsDoc = farmMetricsCollection.doc('current');
    batch.set(
      metricsDoc,
      {
        'todayEggCount': FieldValue.increment(-count),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  // ==================== FINANCIAL LEDGER ====================
  Stream<List<FinancialTransaction>> streamTransactions({String? category}) {
    Query query = financialLedgerCollection.orderBy('timestamp', descending: true).limit(100);
    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return FinancialTransaction.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> recordTransaction({
    required String type, // 'income' | 'expense'
    required String category,
    required double amount,
    required String description,
  }) async {
    await financialLedgerCollection.add({
      'type': type,
      'category': category,
      'amount': amount,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> recordMaintenanceExpense({
    required String title,
    required double cost,
    required String notes,
  }) async {
    await financialLedgerCollection.add({
      'type': 'expense',
      'category': 'Maintenance',
      'amount': cost,
      'description': notes.isNotEmpty ? '$title ($notes)' : title,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> recordFeedOrMedicine({
    required String type, // 'feed' | 'medicine'
    required int packetCount,
    required double totalCost,
    required String description,
  }) async {
    final batch = _firestore.batch();

    final logRef = feedMedicineCollection.doc();
    batch.set(logRef, {
      'type': type,
      'packetCount': packetCount,
      'totalCost': totalCost,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final financeRef = financialLedgerCollection.doc();
    batch.set(financeRef, {
      'type': 'expense',
      'category': 'Food & Meds',
      'amount': totalCost,
      'description': type == 'feed'
          ? 'Feed Purchase ($packetCount packets — $description)'
          : 'Vet Medicine ($description)',
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (type == 'feed' && packetCount > 0) {
      final metricsDoc = farmMetricsCollection.doc('current');
      batch.set(
        metricsDoc,
        {
          'feedPacketStock': FieldValue.increment(packetCount),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<void> recordSalaryPayment({
    required String workerId,
    required String workerName,
    required double amount,
    required String monthYear,
    required String note,
  }) async {
    final batch = _firestore.batch();

    final salaryRef = salaryPaymentsCollection.doc();
    batch.set(salaryRef, {
      'workerId': workerId,
      'workerName': workerName,
      'amount': amount,
      'monthYear': monthYear,
      'note': note,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final financeRef = financialLedgerCollection.doc();
    batch.set(financeRef, {
      'type': 'expense',
      'category': 'Salary Payments',
      'amount': amount,
      'description': note.isNotEmpty
          ? 'Salary: $workerName ($monthYear) — $note'
          : 'Salary: $workerName ($monthYear)',
      'timestamp': FieldValue.serverTimestamp(),
    });

    final workerRef = workersCollection.doc(workerId);
    batch.set(
      workerRef,
      {'lastPaidMonth': monthYear},
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<void> paySalary({
    required Worker worker,
    required String monthYear,
    String note = '',
  }) async {
    await recordSalaryPayment(
      workerId: worker.workerId,
      workerName: worker.name,
      amount: worker.monthlySalary,
      monthYear: monthYear,
      note: note,
    );
  }

  // ==================== DAILY TASKS ====================
  Stream<List<DailyTask>> streamDailyTasks() {
    return dailyTasksCollection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return DailyTask.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> addNewTask(String title) async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await dailyTasksCollection.add({
      'title': title,
      'isCompleted': false,
      'date': dateStr,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTask(String taskId) async {
    await dailyTasksCollection.doc(taskId).delete();
  }

  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    await dailyTasksCollection.doc(taskId).update({
      'isCompleted': isCompleted,
    });
  }

  // ==================== WORKERS & LABOR GROUPS ====================
  Stream<List<Worker>> streamWorkers() {
    return workersCollection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Worker.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> addWorker(Worker worker) async {
    await workersCollection.doc(worker.workerId).set(worker.toMap());
  }

  // Safe Employee Account Creation via Secondary Firebase App
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
    return AuthService().createEmployeeWithAuth(
      name: name,
      email: email,
      role: role,
      phone: phone,
      nic: nic,
      age: age,
      monthlySalary: monthlySalary,
      groupId: groupId,
      groupName: groupName,
      qrPayload: qrPayload,
      workerId: workerId,
      initialPassword: initialPassword,
    );
  }

  Future<void> deleteWorker(String workerId) async {
    final batch = _firestore.batch();
    batch.delete(workersCollection.doc(workerId));

    // Also remove from any labor groups
    final groupsSnap = await laborGroupsCollection.get();
    for (final doc in groupsSnap.docs) {
      final members = List<String>.from((doc.data() as Map)['memberWorkerIds'] ?? []);
      if (members.contains(workerId)) {
        members.remove(workerId);
        batch.update(doc.reference, {'memberWorkerIds': members});
      }
    }

    await batch.commit();
  }

  Stream<List<LaborGroup>> streamLaborGroups() {
    return laborGroupsCollection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return LaborGroup.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> createLaborGroup(LaborGroup group) async {
    await laborGroupsCollection.doc(group.id).set(group.toMap());
  }

  Future<void> deleteLaborGroup(String groupId) async {
    final batch = _firestore.batch();
    batch.delete(laborGroupsCollection.doc(groupId));

    // Clear groupId on assigned workers
    final workersSnap = await workersCollection.where('groupId', isEqualTo: groupId).get();
    for (final doc in workersSnap.docs) {
      batch.update(doc.reference, {'groupId': null, 'groupName': null});
    }

    await batch.commit();
  }

  Future<void> assignWorkerToGroup({
    required String workerId,
    required String groupId,
    required String groupName,
  }) async {
    final batch = _firestore.batch();

    // 1. Update worker document
    final workerRef = workersCollection.doc(workerId);
    batch.update(workerRef, {
      'groupId': groupId,
      'groupName': groupName,
    });

    // 2. Add worker to group's memberWorkerIds list
    final groupRef = laborGroupsCollection.doc(groupId);
    batch.update(groupRef, {
      'memberWorkerIds': FieldValue.arrayUnion([workerId]),
    });

    await batch.commit();
  }

  Future<void> removeWorkerFromGroup({
    required String workerId,
    required String groupId,
  }) async {
    final batch = _firestore.batch();

    // 1. Clear worker's group
    final workerRef = workersCollection.doc(workerId);
    batch.update(workerRef, {
      'groupId': null,
      'groupName': null,
    });

    // 2. Remove from group's member list
    final groupRef = laborGroupsCollection.doc(groupId);
    batch.update(groupRef, {
      'memberWorkerIds': FieldValue.arrayRemove([workerId]),
    });

    await batch.commit();
  }

  // ==================== DYNAMIC ROLES ====================
  Stream<List<String>> streamRoles() {
    return farmMetricsCollection.doc('roles').snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        final raw = (doc.data() as Map)['roles'];
        if (raw is List) {
          final list = raw.map((e) => e.toString()).toList();
          if (list.isNotEmpty) return list;
        }
      }
      return ['Manager', 'Supervisor', 'Collector', 'Driver'];
    });
  }

  Future<void> addRole(String newRole) async {
    final cleanRole = newRole.trim();
    if (cleanRole.isEmpty) return;
    await farmMetricsCollection.doc('roles').set({
      'roles': FieldValue.arrayUnion([cleanRole]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ==================== PASSWORD LIFECYCLE ====================
  Future<void> updateUserPassword({
    required String uid,
    required String newPassword,
    required bool isAdminReset,
  }) async {
    final Map<String, dynamic> updateData = {
      'hasChangedPassword': !isAdminReset,
      'visiblePassword': isAdminReset ? newPassword : null,
      'passwordUpdatedAt': FieldValue.serverTimestamp(),
    };

    await usersCollection.doc(uid).set(updateData, SetOptions(merge: true));
    await usersCollection.doc('current_user').set(updateData, SetOptions(merge: true));
  }

  Future<void> updateWorkerPassword({
    required String workerId,
    required String newPassword,
    required bool isAdminReset,
  }) async {
    final Map<String, dynamic> updateData = {
      'hasChangedPassword': !isAdminReset,
      'visiblePassword': isAdminReset ? newPassword : null,
      'passwordUpdatedAt': FieldValue.serverTimestamp(),
    };

    await workersCollection.doc(workerId).set(updateData, SetOptions(merge: true));
  }

  // ==================== BULK ORDERS & VEHICLES ====================
  Stream<List<BulkOrder>> streamBulkOrders() {
    return bulkOrdersCollection.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return BulkOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await bulkOrdersCollection.doc(orderId).update({
      'status': newStatus,
    });
  }

  // ==================== VEHICLES & COMPLIANCE ====================
  Stream<List<Vehicle>> streamVehicles() {
    return vehiclesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Vehicle.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    await vehiclesCollection.doc(vehicle.vehicleId).set(vehicle.toMap());
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    await vehiclesCollection.doc(vehicle.vehicleId).set(vehicle.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteVehicle(String vehicleId) async {
    await vehiclesCollection.doc(vehicleId).delete();
  }

  Stream<List<VehicleGroup>> streamVehicleGroups() {
    return vehicleGroupsCollection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return VehicleGroup.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> createVehicleGroup(VehicleGroup group) async {
    await vehicleGroupsCollection.doc(group.id).set(group.toMap());
  }

  Future<void> deleteVehicleGroup(String groupId) async {
    final batch = _firestore.batch();
    batch.delete(vehicleGroupsCollection.doc(groupId));

    // Clear groupId on vehicles
    final vehiclesSnap = await vehiclesCollection.where('groupId', isEqualTo: groupId).get();
    for (final doc in vehiclesSnap.docs) {
      batch.update(doc.reference, {'groupId': null, 'groupName': null});
    }

    await batch.commit();
  }

  Future<void> assignVehicleToGroup({
    required String vehicleId,
    required String groupId,
    required String groupName,
  }) async {
    final batch = _firestore.batch();

    final vehicleRef = vehiclesCollection.doc(vehicleId);
    batch.update(vehicleRef, {
      'groupId': groupId,
      'groupName': groupName,
    });

    final groupRef = vehicleGroupsCollection.doc(groupId);
    batch.update(groupRef, {
      'vehicleIds': FieldValue.arrayUnion([vehicleId]),
    });

    await batch.commit();
  }

  Future<void> removeVehicleFromGroup({
    required String vehicleId,
    required String groupId,
  }) async {
    final batch = _firestore.batch();

    final vehicleRef = vehiclesCollection.doc(vehicleId);
    batch.update(vehicleRef, {
      'groupId': null,
      'groupName': null,
    });

    final groupRef = vehicleGroupsCollection.doc(groupId);
    batch.update(groupRef, {
      'vehicleIds': FieldValue.arrayRemove([vehicleId]),
    });

    await batch.commit();
  }

  // ==================== VEHICLE MAINTENANCE (DUAL WRITE) ====================
  Future<void> recordVehicleMaintenance({
    required VehicleMaintenanceLog log,
  }) async {
    final batch = _firestore.batch();

    // 1. Write to general financial_ledger
    final financeRef = financialLedgerCollection.doc();
    batch.set(financeRef, {
      'type': 'expense',
      'category': 'Maintenance',
      'amount': log.cost,
      'description': log.regNumber.isNotEmpty
          ? 'Vehicle Maintenance (${log.regNumber}) — ${log.description}'
          : 'Farm Maintenance — ${log.description}',
      'vehicleId': log.vehicleId,
      'regNumber': log.regNumber,
      'driverId': log.driverId,
      'driverName': log.driverName,
      'odometer': log.odometer,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Write to vehicle's specific maintenance_history subcollection
    if (log.vehicleId.isNotEmpty) {
      final logRef = vehiclesCollection.doc(log.vehicleId).collection('maintenance_history').doc();
      batch.set(logRef, log.toMap());
    }

    await batch.commit();
  }

  Stream<List<VehicleMaintenanceLog>> streamVehicleMaintenance(String vehicleId) {
    return vehiclesCollection
        .doc(vehicleId)
        .collection('maintenance_history')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return VehicleMaintenanceLog.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // ==================== FARM SETTINGS ====================
  Stream<FarmSettings> streamFarmSettings() {
    return farmSettingsCollection.doc('main_settings').snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return FarmSettings.fromMap(doc.data() as Map<String, dynamic>);
      }
      return FarmSettings();
    });
  }

  Future<void> saveFarmSettings(FarmSettings settings) async {
    await farmSettingsCollection.doc('main_settings').set(settings.toMap(), SetOptions(merge: true));
    // Also keep unitEggPrice synced in farmMetricsCollection current doc
    await farmMetricsCollection.doc('current').set({
      'unitEggPrice': settings.unitEggPrice,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ==================== DANGER ZONE / ADMIN OPERATIONS ====================
  Future<void> clearAllDailyTasks() async {
    final snapshot = await dailyTasksCollection.get();
    final docs = snapshot.docs;
    for (var i = 0; i < docs.length; i += 400) {
      final end = (i + 400 < docs.length) ? i + 400 : docs.length;
      final batch = _firestore.batch();
      for (var j = i; j < end; j++) {
        batch.delete(docs[j].reference);
      }
      await batch.commit();
    }
  }

  Future<void> factoryResetDatabase() async {
    // List of farm operational collections to completely clear.
    // CRITICAL: NEVER delete the 'users' collection or Admin profile!
    final collectionsToClear = [
      flockLedgerCollection,
      eggLogsCollection,
      feedMedicineCollection,
      financialLedgerCollection,
      workersCollection,
      laborGroupsCollection,
      salaryPaymentsCollection,
      dailyTasksCollection,
      bulkOrdersCollection,
      vehiclesCollection,
      vehicleGroupsCollection,
      ordersCollection,
      notificationsCollection,
    ];

    for (final col in collectionsToClear) {
      final snapshot = await col.get();
      final docs = snapshot.docs;
      for (var i = 0; i < docs.length; i += 400) {
        final end = (i + 400 < docs.length) ? i + 400 : docs.length;
        final batch = _firestore.batch();
        for (var j = i; j < end; j++) {
          batch.delete(docs[j].reference);
        }
        await batch.commit();
      }
    }

    // Reset farm metrics to zero state
    await farmMetricsCollection.doc('current').set({
      'currentHenCount': 0,
      'todayEggCount': 0,
      'feedPacketStock': 0,
      'unitEggPrice': 40.0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== CUSTOMER & LOGISTICS ORDERS ====================
  Future<void> placeCustomerOrder(CustomerOrder order) async {
    final docRef = ordersCollection.doc(order.orderId.isNotEmpty ? order.orderId : null);
    final finalOrderId = docRef.id;
    final orderToSave = order.orderId.isEmpty ? order.copyWith(orderId: finalOrderId) : order;
    await docRef.set(orderToSave.toMap());

    // Task 4: Write real notification for Admin
    try {
      final senderTitle = orderToSave.shopName.isNotEmpty ? orderToSave.shopName : orderToSave.customerName;
      await notificationsCollection.add({
        'recipientId': 'admin',
        'title': 'New Bulk Order Received',
        'message': '$senderTitle placed an order for ${orderToSave.quantity} eggs.',
        'orderId': finalOrderId,
        'type': 'order_placed',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Notice: Error creating admin notification: $e');
    }
  }

  Stream<List<CustomerOrder>> streamCustomerOrders(String customerId) {
    return ordersCollection
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return CustomerOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      list.sort((a, b) {
        final aTime = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  Stream<List<CustomerOrder>> streamAllOrders() {
    return ordersCollection.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return CustomerOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      list.sort((a, b) {
        final aTime = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  Future<void> updateCustomerOrderStatus(String orderId, String newStatus) async {
    await ordersCollection.doc(orderId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptCustomerOrder(CustomerOrder order) async {
    await ordersCollection.doc(order.orderId).set({
      'status': 'Accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Task 3: Write notification to customer
    try {
      final shortId = order.orderId.length > 8 ? order.orderId.substring(0, 8) : order.orderId;
      await notificationsCollection.add({
        'recipientId': order.customerId,
        'title': 'Order Accepted!',
        'message': 'Your order #$shortId for ${order.quantity} eggs has been accepted by Wimalasooriya Farms.',
        'orderId': order.orderId,
        'type': 'order_accepted',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Notice: Error creating customer acceptance notification: $e');
    }
  }

  Future<void> rejectCustomerOrder(CustomerOrder order, [String? reason]) async {
    await ordersCollection.doc(order.orderId).set({
      'status': 'Rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
      if (reason != null && reason.isNotEmpty) 'rejectionReason': reason,
    }, SetOptions(merge: true));

    try {
      final shortId = order.orderId.length > 8 ? order.orderId.substring(0, 8) : order.orderId;
      await notificationsCollection.add({
        'recipientId': order.customerId,
        'title': 'Order Update',
        'message': 'Your order #$shortId could not be fulfilled at this time${reason != null && reason.isNotEmpty ? ": $reason" : "."}',
        'orderId': order.orderId,
        'type': 'order_rejected',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Notice: Error creating customer rejection notification: $e');
    }
  }

  Future<void> dispatchCustomerOrder(CustomerOrder order) async {
    await ordersCollection.doc(order.orderId).set({
      'status': 'Dispatched',
      'dispatchedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      final shortId = order.orderId.length > 8 ? order.orderId.substring(0, 8) : order.orderId;
      await notificationsCollection.add({
        'recipientId': order.customerId,
        'title': 'Order Dispatched!',
        'message': 'Your order #$shortId for ${order.quantity} eggs has been dispatched and is on the way.',
        'orderId': order.orderId,
        'type': 'order_dispatched',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Notice: Error creating customer dispatch notification: $e');
    }
  }

  Future<void> deliverCustomerOrder(CustomerOrder order) async {
    await ordersCollection.doc(order.orderId).set({
      'status': 'Delivered',
      'deliveredAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      final shortId = order.orderId.length > 8 ? order.orderId.substring(0, 8) : order.orderId;
      await notificationsCollection.add({
        'recipientId': order.customerId,
        'title': 'Order Delivered!',
        'message': 'Your order #$shortId for ${order.quantity} eggs has been delivered successfully.',
        'orderId': order.orderId,
        'type': 'order_delivered',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Notice: Error creating customer delivery notification: $e');
    }
  }

  Future<String> remakeCustomerOrder({
    required CustomerOrder previousOrder,
    required double currentUnitPrice,
  }) async {
    final docRef = ordersCollection.doc();
    final newOrderId = docRef.id;
    final total = previousOrder.quantity * currentUnitPrice;

    final newOrder = CustomerOrder(
      orderId: newOrderId,
      customerId: previousOrder.customerId,
      customerName: previousOrder.customerName,
      customerPhone: previousOrder.customerPhone,
      shopName: previousOrder.shopName,
      shopAddress: previousOrder.shopAddress,
      latitude: previousOrder.latitude,
      longitude: previousOrder.longitude,
      quantity: previousOrder.quantity,
      unitPrice: currentUnitPrice,
      totalPrice: total,
      status: 'Pending',
      timestamp: DateTime.now(),
    );

    await docRef.set(newOrder.toMap());

    try {
      final senderTitle = newOrder.shopName.isNotEmpty ? newOrder.shopName : newOrder.customerName;
      await notificationsCollection.add({
        'recipientId': 'admin',
        'title': 'Re-Order Received',
        'message': '$senderTitle re-ordered ${newOrder.quantity} eggs.',
        'orderId': newOrderId,
        'type': 'order_placed',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Notice: Error creating admin notification for re-order: $e');
    }

    return newOrderId;
  }

  Future<void> cancelCustomerOrder(String orderId) async {
    await updateCustomerOrderStatus(orderId, 'Cancelled');
  }

  Future<void> updateUserShopLocation({
    required String uid,
    required String shopName,
    required String shopAddress,
    required double latitude,
    required double longitude,
  }) async {
    await usersCollection.doc(uid).set({
      'shopName': shopName.trim(),
      'shopAddress': shopAddress.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ==================== REGISTERED SHOPS ====================
  Stream<List<AppUser>> streamCustomerShops() {
    return usersCollection
        .where('role', isEqualTo: 'Customer')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      list.sort((a, b) => a.shopNameOrName.toLowerCase().compareTo(b.shopNameOrName.toLowerCase()));
      return list;
    });
  }

  // ==================== NOTIFICATIONS ====================
  Stream<List<FarmNotification>> streamAdminNotifications() {
    return notificationsCollection
        .where('recipientId', isEqualTo: 'admin')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return FarmNotification.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      list.sort((a, b) {
        final aTime = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  Stream<List<FarmNotification>> streamCustomerNotifications(String customerId) {
    if (customerId.isEmpty) return Stream.value([]);
    return notificationsCollection
        .where('recipientId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return FarmNotification.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      list.sort((a, b) {
        final aTime = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await notificationsCollection.doc(notificationId).set({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markAllNotificationsAsRead(String recipientId) async {
    final snapshot = await notificationsCollection
        .where('recipientId', isEqualTo: recipientId)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true, 'readAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }

  // ==================== FOOD & MEDS CATALOG ====================
  Stream<Map<String, List<CatalogItem>>> streamCatalogs() {
    return farmSettingsCollection.doc('catalogs').snapshots().map((doc) {
      final defaultFeeds = [
        CatalogItem(name: 'Layer Mash - High Calcium', description: 'Optimal nutrition for egg-laying hens'),
        CatalogItem(name: 'Grower Mash', description: 'Balanced growth feed for pullets'),
        CatalogItem(name: 'Chick Starter', description: 'High protein starter crumbs for chicks'),
        CatalogItem(name: 'Broiler Finisher', description: 'Energy dense feed for mature flock'),
      ];
      final defaultMeds = [
        CatalogItem(name: 'Multivitamin ADE', description: 'Stress-relief and immunity booster'),
        CatalogItem(name: 'Electrolytes Soluble Powder', description: 'Hydration and heat stress prevention'),
        CatalogItem(name: 'Newcastle Vaccine (LaSota)', description: 'ND viral protection via drinking water'),
        CatalogItem(name: 'Gumboro (IBD) Vaccine', description: 'Infectious bursal disease protection'),
        CatalogItem(name: 'Antibiotic Oxytetracycline', description: 'Broad-spectrum bacterial treatment'),
      ];

      if (!doc.exists || doc.data() == null) {
        return {
          'feed': defaultFeeds,
          'medicine': defaultMeds,
        };
      }

      final data = doc.data() as Map<String, dynamic>;
      final rawFeeds = data['feedItems'] as List<dynamic>? ?? [];
      final rawMeds = data['medicineItems'] as List<dynamic>? ?? [];

      final feedList = rawFeeds.map((e) => CatalogItem.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      final medList = rawMeds.map((e) => CatalogItem.fromMap(Map<String, dynamic>.from(e as Map))).toList();

      return {
        'feed': feedList.isNotEmpty ? feedList : defaultFeeds,
        'medicine': medList.isNotEmpty ? medList : defaultMeds,
      };
    });
  }

  Future<void> addCatalogItem({
    required String type, // 'feed' | 'medicine'
    required String name,
    required String description,
  }) async {
    final docRef = farmSettingsCollection.doc('catalogs');
    final doc = await docRef.get();
    final key = type.toLowerCase() == 'feed' ? 'feedItems' : 'medicineItems';

    final newItem = {'name': name.trim(), 'description': description.trim()};

    if (!doc.exists) {
      await docRef.set({
        key: [newItem],
      }, SetOptions(merge: true));
    } else {
      await docRef.update({
        key: FieldValue.arrayUnion([newItem]),
      });
    }
  }
}
