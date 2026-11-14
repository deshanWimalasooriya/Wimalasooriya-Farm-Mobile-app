import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String phone;
  final String nic;
  final String farmBranch;
  final String? avatarUrl;
  final String? visiblePassword;
  final bool hasChangedPassword;
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.nic = '',
    this.farmBranch = 'Main Farm — Kurunegala',
    this.avatarUrl,
    this.visiblePassword,
    this.hasChangedPassword = false,
    this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String id) {
    return AppUser(
      uid: id,
      name: data['name'] ?? 'Deshan Wimalasooriya',
      email: data['email'] ?? 'deshanwimalasooriya000@gmail.com',
      role: data['role'] ?? 'Admin / Manager',
      phone: data['phone'] ?? '+94 77 123 4567',
      nic: data['nic'] ?? '199214502341',
      farmBranch: data['farmBranch'] ?? 'Main Farm — Kurunegala',
      avatarUrl: data['avatarUrl'],
      visiblePassword: data['visiblePassword'],
      hasChangedPassword: (data['hasChangedPassword'] ?? false) as bool,
      createdAt: parseDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'nic': nic,
      'farmBranch': farmBranch,
      'avatarUrl': avatarUrl,
      'visiblePassword': visiblePassword,
      'hasChangedPassword': hasChangedPassword,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}

class FarmMetrics {
  final int currentHenCount;
  final int todayEggCount;
  final int feedPacketStock;
  final double unitEggPrice;
  final DateTime? updatedAt;

  FarmMetrics({
    required this.currentHenCount,
    required this.todayEggCount,
    required this.feedPacketStock,
    required this.unitEggPrice,
    this.updatedAt,
  });

  factory FarmMetrics.fromMap(Map<String, dynamic> data) {
    return FarmMetrics(
      currentHenCount: (data['currentHenCount'] ?? 0) as int,
      todayEggCount: (data['todayEggCount'] ?? 0) as int,
      feedPacketStock: (data['feedPacketStock'] ?? 0) as int,
      unitEggPrice: ((data['unitEggPrice'] ?? 40.0) as num).toDouble(),
      updatedAt: parseDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentHenCount': currentHenCount,
      'todayEggCount': todayEggCount,
      'feedPacketStock': feedPacketStock,
      'unitEggPrice': unitEggPrice,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class FlockLedgerEntry {
  final String id;
  final String action; // 'add' | 'remove'
  final int count;
  final String reason; // 'New Batch', 'Remove', 'Natural Death', 'Culled', 'Sold', 'Reset to 0'
  final DateTime? timestamp;
  final String loggedBy;

  FlockLedgerEntry({
    required this.id,
    required this.action,
    required this.count,
    required this.reason,
    this.timestamp,
    required this.loggedBy,
  });

  factory FlockLedgerEntry.fromMap(Map<String, dynamic> data, String id) {
    return FlockLedgerEntry(
      id: id,
      action: data['action'] ?? 'add',
      count: (data['count'] ?? 0) as int,
      reason: data['reason'] ?? '',
      timestamp: parseDateTime(data['timestamp']),
      loggedBy: data['loggedBy'] ?? 'Staff',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'count': count,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
      'loggedBy': loggedBy,
    };
  }
}

class EggLogEntry {
  final String id;
  final int producedCount;
  final int brokenCount;
  final int spoiledCount;
  final String loggedBy;
  final DateTime? timestamp;

  EggLogEntry({
    required this.id,
    required this.producedCount,
    this.brokenCount = 0,
    this.spoiledCount = 0,
    required this.loggedBy,
    this.timestamp,
  });

  factory EggLogEntry.fromMap(Map<String, dynamic> data, String id) {
    return EggLogEntry(
      id: id,
      producedCount: (data['producedCount'] ?? 0) as int,
      brokenCount: (data['brokenCount'] ?? 0) as int,
      spoiledCount: (data['spoiledCount'] ?? 0) as int,
      loggedBy: data['loggedBy'] ?? 'Staff',
      timestamp: parseDateTime(data['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'producedCount': producedCount,
      'brokenCount': brokenCount,
      'spoiledCount': spoiledCount,
      'loggedBy': loggedBy,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}

class FeedMedicineLog {
  final String id;
  final String type; // 'feed' | 'medicine'
  final int packetCount;
  final double totalCost;
  final String description;
  final DateTime? timestamp;

  FeedMedicineLog({
    required this.id,
    required this.type,
    this.packetCount = 0,
    required this.totalCost,
    required this.description,
    this.timestamp,
  });

  factory FeedMedicineLog.fromMap(Map<String, dynamic> data, String id) {
    return FeedMedicineLog(
      id: id,
      type: data['type'] ?? 'feed',
      packetCount: (data['packetCount'] ?? 0) as int,
      totalCost: ((data['totalCost'] ?? 0.0) as num).toDouble(),
      description: data['description'] ?? '',
      timestamp: parseDateTime(data['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'packetCount': packetCount,
      'totalCost': totalCost,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}

class FinancialTransaction {
  final String id;
  final String type; // 'income' | 'expense'
  final String category; // 'Eggs' | 'Salary Payments' | 'Maintenance' | 'Food & Meds' | 'Other'
  final double amount;
  final String description;
  final String? vehicleId;
  final String? regNumber;
  final String? driverId;
  final String? driverName;
  final int? odometer;
  final DateTime? timestamp;

  FinancialTransaction({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    this.vehicleId,
    this.regNumber,
    this.driverId,
    this.driverName,
    this.odometer,
    this.timestamp,
  });

  factory FinancialTransaction.fromMap(Map<String, dynamic> data, String id) {
    return FinancialTransaction(
      id: id,
      type: data['type'] ?? 'income',
      category: data['category'] ?? 'Eggs',
      amount: ((data['amount'] ?? 0.0) as num).toDouble(),
      description: data['description'] ?? '',
      vehicleId: data['vehicleId'],
      regNumber: data['regNumber'],
      driverId: data['driverId'],
      driverName: data['driverName'],
      odometer: data['odometer'] != null ? (data['odometer'] as num).toInt() : null,
      timestamp: parseDateTime(data['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'category': category,
      'amount': amount,
      'description': description,
      'vehicleId': vehicleId,
      'regNumber': regNumber,
      'driverId': driverId,
      'driverName': driverName,
      'odometer': odometer,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}

class Worker {
  final String workerId;
  final String name;
  final int age;
  final String nic;
  final String phone;
  final String role; // Manager, Collector, Driver, Supervisor, or dynamic role
  final double monthlySalary;
  final String? groupId;
  final String? groupName;
  final String qrPayload;
  final String? photoUrl;
  final bool isActive;
  final String? lastPaidMonth;
  final String? visiblePassword;
  final bool hasChangedPassword;
  final DateTime? joinedDate;
  final DateTime? createdAt;

  Worker({
    required this.workerId,
    required this.name,
    this.age = 30,
    this.nic = '',
    this.phone = '',
    required this.role,
    required this.monthlySalary,
    this.groupId,
    this.groupName,
    required this.qrPayload,
    this.photoUrl,
    this.isActive = true,
    this.lastPaidMonth,
    this.visiblePassword,
    this.hasChangedPassword = false,
    this.joinedDate,
    this.createdAt,
  });

  factory Worker.fromMap(Map<String, dynamic> data, String id) {
    return Worker(
      workerId: id,
      name: data['name'] ?? '',
      age: (data['age'] ?? 30) as int,
      nic: data['nic'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? 'Collector',
      monthlySalary: ((data['monthlySalary'] ?? 0.0) as num).toDouble(),
      groupId: data['groupId'],
      groupName: data['groupName'],
      qrPayload: data['qrPayload'] ?? id,
      photoUrl: data['photoUrl'],
      isActive: (data['isActive'] ?? true) as bool,
      lastPaidMonth: data['lastPaidMonth'],
      visiblePassword: data['visiblePassword'],
      hasChangedPassword: (data['hasChangedPassword'] ?? false) as bool,
      joinedDate: parseDateTime(data['joinedDate']),
      createdAt: parseDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workerId': workerId,
      'name': name,
      'age': age,
      'nic': nic,
      'phone': phone,
      'role': role,
      'monthlySalary': monthlySalary,
      'groupId': groupId,
      'groupName': groupName,
      'qrPayload': qrPayload,
      'photoUrl': photoUrl,
      'isActive': isActive,
      'lastPaidMonth': lastPaidMonth,
      'visiblePassword': visiblePassword,
      'hasChangedPassword': hasChangedPassword,
      'joinedDate': joinedDate != null ? Timestamp.fromDate(joinedDate!) : FieldValue.serverTimestamp(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Worker && runtimeType == other.runtimeType && workerId == other.workerId;

  @override
  int get hashCode => workerId.hashCode;
}

class LaborGroup {
  final String id;
  final String name;
  final String supervisor;
  final String description;
  final List<String> memberWorkerIds;
  final DateTime? createdAt;

  LaborGroup({
    required this.id,
    required this.name,
    required this.supervisor,
    this.description = '',
    this.memberWorkerIds = const [],
    this.createdAt,
  });

  factory LaborGroup.fromMap(Map<String, dynamic> data, String id) {
    final rawMembers = data['memberWorkerIds'];
    List<String> members = [];
    if (rawMembers is List) {
      members = rawMembers.map((e) => e.toString()).toList();
    }
    return LaborGroup(
      id: id,
      name: data['name'] ?? '',
      supervisor: data['supervisor'] ?? '',
      description: data['description'] ?? '',
      memberWorkerIds: members,
      createdAt: parseDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'supervisor': supervisor,
      'description': description,
      'memberWorkerIds': memberWorkerIds,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LaborGroup && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DailyTask {
  final String id;
  final String title;
  final bool isCompleted;
  final String date;
  final DateTime? createdAt;

  DailyTask({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.date,
    this.createdAt,
  });

  factory DailyTask.fromMap(Map<String, dynamic> data, String id) {
    return DailyTask(
      id: id,
      title: data['title'] ?? '',
      isCompleted: (data['isCompleted'] ?? false) as bool,
      date: data['date'] ?? '',
      createdAt: parseDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isCompleted': isCompleted,
      'date': date,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyTask && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class BulkOrder {
  final String id;
  final String clientName;
  final int eggQuantity;
  final double totalPrice;
  final String status; // 'Pending' | 'Processing' | 'Dispatched'
  final DateTime? createdAt;

  BulkOrder({
    required this.id,
    required this.clientName,
    required this.eggQuantity,
    required this.totalPrice,
    required this.status,
    this.createdAt,
  });

  factory BulkOrder.fromMap(Map<String, dynamic> data, String id) {
    return BulkOrder(
      id: id,
      clientName: data['clientName'] ?? '',
      eggQuantity: (data['eggQuantity'] ?? 0) as int,
      totalPrice: ((data['totalPrice'] ?? 0.0) as num).toDouble(),
      status: data['status'] ?? 'Pending',
      createdAt: parseDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientName': clientName,
      'eggQuantity': eggQuantity,
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class Vehicle {
  final String vehicleId;
  final String regNumber; // e.g. CP CAA-1234
  final String vehicleType; // Lorry, Tractor, Van, Bike, Three-Wheeler
  final String makeModel;
  final String chassisNo;
  final String fuelType; // Diesel, Petrol, Electric
  final String? groupId;
  final String? groupName;

  // Sri Lankan Legal Compliance Documents
  final String insurancePolicyNo;
  final String insuranceType; // Comprehensive, Third Party
  final DateTime? insuranceExpiryDate;
  final String revenueLicenseNo;
  final DateTime? revenueLicenseExpiryDate;
  final String ecoTestNo;
  final DateTime? ecoTestExpiryDate;
  final String fitnessCertNo;
  final DateTime? fitnessCertExpiryDate;

  // Operational State
  final String status; // 'Active', 'Inactive', 'Under Maintenance'
  final bool manualStatusOverride;
  final List<String> assignedDriverIds;
  final List<String> assignedDriverNames;
  final DateTime? createdAt;

  Vehicle({
    required this.vehicleId,
    required this.regNumber,
    this.vehicleType = 'Lorry',
    this.makeModel = '',
    this.chassisNo = '',
    this.fuelType = 'Diesel',
    this.groupId,
    this.groupName,
    this.insurancePolicyNo = '',
    this.insuranceType = 'Comprehensive',
    this.insuranceExpiryDate,
    this.revenueLicenseNo = '',
    this.revenueLicenseExpiryDate,
    this.ecoTestNo = '',
    this.ecoTestExpiryDate,
    this.fitnessCertNo = '',
    this.fitnessCertExpiryDate,
    this.status = 'Active',
    this.manualStatusOverride = false,
    this.assignedDriverIds = const [],
    this.assignedDriverNames = const [],
    this.createdAt,
  });

  bool get isInsuranceExpired => insuranceExpiryDate != null && insuranceExpiryDate!.isBefore(DateTime.now());
  bool get isRevenueLicenseExpired => revenueLicenseExpiryDate != null && revenueLicenseExpiryDate!.isBefore(DateTime.now());
  bool get isEcoTestExpired => ecoTestExpiryDate != null && ecoTestExpiryDate!.isBefore(DateTime.now());
  bool get isFitnessExpired => fitnessCertExpiryDate != null && fitnessCertExpiryDate!.isBefore(DateTime.now());
  bool get isAnyDocumentExpired => isInsuranceExpired || isRevenueLicenseExpired || isEcoTestExpired || isFitnessExpired;

  String get effectiveStatus {
    if (isAnyDocumentExpired) return 'Inactive (Document Expired)';
    return status;
  }

  List<Map<String, dynamic>> get expiringDocuments {
    final now = DateTime.now();
    final List<Map<String, dynamic>> list = [];

    void checkDoc(String name, DateTime? expiry) {
      if (expiry == null) return;
      final diff = expiry.difference(now).inDays;
      if (expiry.isBefore(now)) {
        list.add({
          'name': name,
          'daysLeft': diff,
          'isExpired': true,
          'date': expiry,
        });
      } else if (diff <= 10) {
        list.add({
          'name': name,
          'daysLeft': diff,
          'isExpired': false,
          'date': expiry,
        });
      }
    }

    checkDoc('Vehicle Insurance', insuranceExpiryDate);
    checkDoc('Revenue License (ආදායම් බලපත්‍රය)', revenueLicenseExpiryDate);
    checkDoc('Eco Test (දුම් සහතිකය)', ecoTestExpiryDate);
    checkDoc('Fitness Certificate (යෝග්‍යතා සහතිකය)', fitnessCertExpiryDate);

    return list;
  }

  factory Vehicle.fromMap(Map<String, dynamic> data, String id) {
    final rawDriverIds = data['assignedDriverIds'];
    List<String> driverIds = [];
    if (rawDriverIds is List) {
      driverIds = rawDriverIds.map((e) => e.toString()).toList();
    }

    final rawDriverNames = data['assignedDriverNames'];
    List<String> driverNames = [];
    if (rawDriverNames is List) {
      driverNames = rawDriverNames.map((e) => e.toString()).toList();
    } else if (data['driverName'] != null && data['driverName'].toString().isNotEmpty) {
      driverNames = [data['driverName'].toString()];
    }

    return Vehicle(
      vehicleId: id,
      regNumber: data['regNumber'] ?? '',
      vehicleType: data['vehicleType'] ?? data['type'] ?? 'Lorry',
      makeModel: data['makeModel'] ?? '',
      chassisNo: data['chassisNo'] ?? '',
      fuelType: data['fuelType'] ?? 'Diesel',
      groupId: data['groupId'],
      groupName: data['groupName'],
      insurancePolicyNo: data['insurancePolicyNo'] ?? '',
      insuranceType: data['insuranceType'] ?? 'Comprehensive',
      insuranceExpiryDate: parseDateTime(data['insuranceExpiryDate']) ?? parseDateTime(data['insuranceExpiry']),
      revenueLicenseNo: data['revenueLicenseNo'] ?? '',
      revenueLicenseExpiryDate: parseDateTime(data['revenueLicenseExpiryDate']),
      ecoTestNo: data['ecoTestNo'] ?? '',
      ecoTestExpiryDate: parseDateTime(data['ecoTestExpiryDate']),
      fitnessCertNo: data['fitnessCertNo'] ?? '',
      fitnessCertExpiryDate: parseDateTime(data['fitnessCertExpiryDate']),
      status: data['status'] ?? 'Active',
      manualStatusOverride: (data['manualStatusOverride'] ?? false) as bool,
      assignedDriverIds: driverIds,
      assignedDriverNames: driverNames,
      createdAt: parseDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'regNumber': regNumber,
      'vehicleType': vehicleType,
      'type': vehicleType, // Backward-compatibility
      'makeModel': makeModel,
      'chassisNo': chassisNo,
      'fuelType': fuelType,
      'groupId': groupId,
      'groupName': groupName,
      'insurancePolicyNo': insurancePolicyNo,
      'insuranceType': insuranceType,
      'insuranceExpiryDate': insuranceExpiryDate != null ? Timestamp.fromDate(insuranceExpiryDate!) : null,
      'revenueLicenseNo': revenueLicenseNo,
      'revenueLicenseExpiryDate': revenueLicenseExpiryDate != null ? Timestamp.fromDate(revenueLicenseExpiryDate!) : null,
      'ecoTestNo': ecoTestNo,
      'ecoTestExpiryDate': ecoTestExpiryDate != null ? Timestamp.fromDate(ecoTestExpiryDate!) : null,
      'fitnessCertNo': fitnessCertNo,
      'fitnessCertExpiryDate': fitnessCertExpiryDate != null ? Timestamp.fromDate(fitnessCertExpiryDate!) : null,
      'status': status,
      'manualStatusOverride': manualStatusOverride,
      'assignedDriverIds': assignedDriverIds,
      'assignedDriverNames': assignedDriverNames,
      'driverName': assignedDriverNames.isNotEmpty ? assignedDriverNames.first : '',
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vehicle && runtimeType == other.runtimeType && vehicleId == other.vehicleId;

  @override
  int get hashCode => vehicleId.hashCode;
}

class VehicleGroup {
  final String id;
  final String name;
  final String description;
  final List<String> vehicleIds;
  final DateTime? createdAt;

  VehicleGroup({
    required this.id,
    required this.name,
    this.description = '',
    this.vehicleIds = const [],
    this.createdAt,
  });

  factory VehicleGroup.fromMap(Map<String, dynamic> data, String id) {
    final rawVehicles = data['vehicleIds'];
    List<String> vehicles = [];
    if (rawVehicles is List) {
      vehicles = rawVehicles.map((e) => e.toString()).toList();
    }
    return VehicleGroup(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      vehicleIds: vehicles,
      createdAt: parseDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'vehicleIds': vehicleIds,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleGroup && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class VehicleMaintenanceLog {
  final String id;
  final String vehicleId;
  final String regNumber;
  final String driverId;
  final String driverName;
  final String maintenanceType;
  final String description;
  final double cost;
  final int? odometer;
  final DateTime? timestamp;

  VehicleMaintenanceLog({
    required this.id,
    required this.vehicleId,
    required this.regNumber,
    this.driverId = '',
    this.driverName = '',
    required this.maintenanceType,
    required this.description,
    required this.cost,
    this.odometer,
    this.timestamp,
  });

  factory VehicleMaintenanceLog.fromMap(Map<String, dynamic> data, String id) {
    return VehicleMaintenanceLog(
      id: id,
      vehicleId: data['vehicleId'] ?? '',
      regNumber: data['regNumber'] ?? '',
      driverId: data['driverId'] ?? '',
      driverName: data['driverName'] ?? '',
      maintenanceType: data['maintenanceType'] ?? 'General Service',
      description: data['description'] ?? '',
      cost: ((data['cost'] ?? 0.0) as num).toDouble(),
      odometer: data['odometer'] != null ? (data['odometer'] as num).toInt() : null,
      timestamp: parseDateTime(data['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'regNumber': regNumber,
      'driverId': driverId,
      'driverName': driverName,
      'maintenanceType': maintenanceType,
      'description': description,
      'cost': cost,
      'odometer': odometer,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
