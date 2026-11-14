import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseSeeder {
  static Future<void> seedIfEmpty() async {
    final firestore = FirebaseFirestore.instance;
    final metricsDoc = await firestore.collection('farm_metrics').doc('current').get();

    if (metricsDoc.exists) {
      // Database already seeded
      return;
    }

    // 1. Seed farm_metrics
    await firestore.collection('farm_metrics').doc('current').set({
      'currentHenCount': 4500,
      'todayEggCount': 4200,
      'feedPacketStock': 120,
      'unitEggPrice': 40.0,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 1b. Seed Admin User profile
    await firestore.collection('users').doc('current_user').set({
      'email': 'deshanwimalasooriya000@gmail.com',
      'name': 'Deshan Wimalasooriya',
      'role': 'Admin / Manager',
      'phone': '+94 77 123 4567',
      'nic': '199214502341',
      'farmBranch': 'Main Farm — Kurunegala',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Seed flock_ledger
    final flockCol = firestore.collection('flock_ledger');
    await flockCol.add({
      'action': 'add',
      'count': 500,
      'reason': 'New Batch Added',
      'timestamp': FieldValue.serverTimestamp(),
      'loggedBy': 'Deshan Wimalasooriya',
    });
    await flockCol.add({
      'action': 'remove',
      'count': 12,
      'reason': 'Natural Death',
      'timestamp': FieldValue.serverTimestamp(),
      'loggedBy': 'Deshan Wimalasooriya',
    });
    await flockCol.add({
      'action': 'remove',
      'count': 15,
      'reason': 'Sold',
      'timestamp': FieldValue.serverTimestamp(),
      'loggedBy': 'Deshan Wimalasooriya',
    });

    // 3. Seed financial_ledger
    final financeCol = firestore.collection('financial_ledger');
    await financeCol.add({
      'type': 'income',
      'category': 'Eggs',
      'amount': 160000.0,
      'description': 'Egg Sales (4,000 eggs @ Rs. 40)',
      'timestamp': FieldValue.serverTimestamp(),
    });
    await financeCol.add({
      'type': 'expense',
      'category': 'Food & Meds',
      'amount': 15000.0,
      'description': 'Feed Purchase (Layer Feed 50kg)',
      'timestamp': FieldValue.serverTimestamp(),
    });
    await financeCol.add({
      'type': 'expense',
      'category': 'Food & Meds',
      'amount': 4500.0,
      'description': 'Vet Medicine (Electrolytes & Vitamins)',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 4. Seed daily_tasks
    final tasksCol = firestore.collection('daily_tasks');
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    await tasksCol.add({
      'title': 'Morning Egg Collection',
      'isCompleted': true,
      'date': dateStr,
    });
    await tasksCol.add({
      'title': 'Water & Feed Line Inspections',
      'isCompleted': false,
      'date': dateStr,
    });
    await tasksCol.add({
      'title': 'Evening Yield Count Logging',
      'isCompleted': false,
      'date': dateStr,
    });
    await tasksCol.add({
      'title': 'Vehicle Dispatch check',
      'isCompleted': false,
      'date': dateStr,
    });

    // 5. Seed workers
    final workersCol = firestore.collection('workers');
    await workersCol.doc('WF-EMP-001').set({
      'workerId': 'WF-EMP-001',
      'name': 'Deshan Wimalasooriya',
      'age': 32,
      'nic': '199214502341',
      'role': 'Manager',
      'monthlySalary': 150000.0,
      'qrPayload': 'WF-EMP-001|Deshan Wimalasooriya|Manager',
      'photoUrl': null,
      'isActive': true,
      'lastPaidMonth': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await workersCol.doc('WF-EMP-002').set({
      'workerId': 'WF-EMP-002',
      'name': 'Kasun Bandara',
      'age': 28,
      'nic': '199611204489',
      'role': 'Supervisor',
      'monthlySalary': 75000.0,
      'qrPayload': 'WF-EMP-002|Kasun Bandara|Supervisor',
      'photoUrl': null,
      'isActive': true,
      'lastPaidMonth': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await workersCol.doc('WF-EMP-003').set({
      'workerId': 'WF-EMP-003',
      'name': 'Nuwan Perera',
      'age': 25,
      'nic': '199923405512',
      'role': 'Collector',
      'monthlySalary': 55000.0,
      'qrPayload': 'WF-EMP-003|Nuwan Perera|Collector',
      'photoUrl': null,
      'isActive': true,
      'lastPaidMonth': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await workersCol.doc('WF-EMP-004').set({
      'workerId': 'WF-EMP-004',
      'name': 'Sampath Silva',
      'age': 36,
      'nic': '198817809923',
      'role': 'Driver',
      'monthlySalary': 60000.0,
      'qrPayload': 'WF-EMP-004|Sampath Silva|Driver',
      'photoUrl': null,
      'isActive': true,
      'lastPaidMonth': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 6. Seed bulk_orders
    final ordersCol = firestore.collection('bulk_orders');
    await ordersCol.add({
      'clientName': 'Colombo Supermarket Chain',
      'eggQuantity': 5000,
      'totalPrice': 200000.0,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await ordersCol.add({
      'clientName': 'Kandy Bakers Ltd',
      'eggQuantity': 2500,
      'totalPrice': 100000.0,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await ordersCol.add({
      'clientName': 'Galle Fresh Mart',
      'eggQuantity': 1500,
      'totalPrice': 60000.0,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 7. Seed vehicles
    final vehiclesCol = firestore.collection('vehicles');
    await vehiclesCol.doc('V-01').set({
      'vehicleId': 'V-01',
      'regNumber': 'WP-CAD-4589',
      'type': 'Toyota Dyna 2-Ton Chilled Truck',
      'driverName': 'Sampath Silva',
      'status': 'Active',
      'insuranceExpiry': '2027-04-15',
    });
    await vehiclesCol.doc('V-02').set({
      'vehicleId': 'V-02',
      'regNumber': 'WP-LH-8821',
      'type': 'Isuzu ELF 3.5-Ton Delivery',
      'driverName': 'Kamal Fernando',
      'status': 'Active',
      'insuranceExpiry': '2027-08-30',
    });
  }
}

