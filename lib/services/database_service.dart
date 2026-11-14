import 'package:cloud_firestore/cloud_firestore.dart';
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

  // ==================== USER PROFILE ====================
  Stream<AppUser> streamCurrentUser([String? uid]) {
    final targetDocId = uid ?? 'current_user';
    return usersCollection.doc(targetDocId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return AppUser(
        uid: targetDocId,
        name: 'Deshan Wimalasooriya',
        email: 'deshanwimalasooriya000@gmail.com',
        role: 'Admin / Manager',
        phone: '+94 77 123 4567',
        nic: '199214502341',
        farmBranch: 'Main Farm — Kurunegala',
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
    await usersCollection.doc('current_user').set(user.toMap(), SetOptions(merge: true));
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
}
