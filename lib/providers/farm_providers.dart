import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/farm_models.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserStreamProvider = StreamProvider<AppUser>((ref) {
  final authUserAsync = ref.watch(authUserProvider);
  final authUser = authUserAsync.value ?? FirebaseAuth.instance.currentUser;
  final db = ref.watch(databaseServiceProvider);
  return db.streamCurrentUser(authUser?.uid);
});

final farmMetricsStreamProvider = StreamProvider<FarmMetrics>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamFarmMetrics();
});

final flockLedgerStreamProvider = StreamProvider<List<FlockLedgerEntry>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamFlockLedger();
});

final eggLogsStreamProvider = StreamProvider<List<EggLogEntry>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamEggLogs();
});

final transactionsStreamProvider = StreamProvider<List<FinancialTransaction>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamTransactions();
});

final workersStreamProvider = StreamProvider<List<Worker>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamWorkers();
});

final laborGroupsStreamProvider = StreamProvider<List<LaborGroup>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamLaborGroups();
});

final dailyTasksStreamProvider = StreamProvider<List<DailyTask>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamDailyTasks();
});

final bulkOrdersStreamProvider = StreamProvider<List<BulkOrder>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamBulkOrders();
});

final vehiclesStreamProvider = StreamProvider<List<Vehicle>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamVehicles();
});

final vehicleGroupsStreamProvider = StreamProvider<List<VehicleGroup>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamVehicleGroups();
});

final rolesStreamProvider = StreamProvider<List<String>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamRoles();
});

final farmSettingsStreamProvider = StreamProvider<FarmSettings>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamFarmSettings();
});

// ==================== CUSTOMER & LOGISTICS ORDERS PROVIDERS ====================
final customerOrdersStreamProvider = StreamProvider<List<CustomerOrder>>((ref) {
  final authUserAsync = ref.watch(authUserProvider);
  final authUser = authUserAsync.value ?? FirebaseAuth.instance.currentUser;
  if (authUser == null) return Stream.value([]);
  final db = ref.watch(databaseServiceProvider);
  return db.streamCustomerOrders(authUser.uid);
});

final allOrdersStreamProvider = StreamProvider<List<CustomerOrder>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamAllOrders();
});

final customerShopsStreamProvider = StreamProvider<List<AppUser>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamCustomerShops();
});

final adminNotificationsStreamProvider = StreamProvider<List<FarmNotification>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamAdminNotifications();
});

final customerNotificationsStreamProvider = StreamProvider<List<FarmNotification>>((ref) {
  final authUser = ref.watch(authUserProvider).value;
  if (authUser == null) return Stream.value([]);
  final db = ref.watch(databaseServiceProvider);
  return db.streamCustomerNotifications(authUser.uid);
});

final catalogsStreamProvider = StreamProvider<Map<String, List<CatalogItem>>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamCatalogs();
});

// Expiring vehicles provider (identifies vehicles with documents expiring <= 10 days or expired)
final expiringVehiclesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final vehicles = ref.watch(vehiclesStreamProvider).value ?? [];
  final List<Map<String, dynamic>> alerts = [];

  for (final v in vehicles) {
    for (final doc in v.expiringDocuments) {
      alerts.add({
        'vehicle': v,
        'regNumber': v.regNumber,
        'docName': doc['name'],
        'daysLeft': doc['daysLeft'],
        'isExpired': doc['isExpired'],
        'date': doc['date'],
      });
    }
  }

  return alerts;
});

// Time-Range Filter Provider for Dashboard (Daily, Weekly, Monthly, Yearly)
final dashboardTimeRangeProvider = StateProvider<String>((ref) => 'Weekly');

// Active Navigation Tab Provider (0: Dashboard, 1: Flock, 2: Home, 3: Finance, 4: Menu)
final activeNavTabProvider = StateProvider<int>((ref) => 2); // Default to Home
