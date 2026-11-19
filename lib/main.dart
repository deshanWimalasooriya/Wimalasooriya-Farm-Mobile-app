import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'services/database_seeder.dart';
import 'providers/farm_providers.dart';
import 'screens/splash_screen.dart';
import 'screens/get_started_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_shell.dart';
import 'screens/customer_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Seed initial collections/documents if empty
    await DatabaseSeeder.seedIfEmpty();
  } catch (e) {
    debugPrint('Firebase initialization or seeding notice: $e');
  }

  runApp(
    const ProviderScope(
      child: WimalasooriyaFarmApp(),
    ),
  );
}

class WimalasooriyaFarmApp extends ConsumerStatefulWidget {
  const WimalasooriyaFarmApp({super.key});

  @override
  ConsumerState<WimalasooriyaFarmApp> createState() => _WimalasooriyaFarmAppState();
}

class _WimalasooriyaFarmAppState extends ConsumerState<WimalasooriyaFarmApp> {
  bool _isInitializing = true;
  bool _isLoggedIn = false;
  bool _hasSeenGetStarted = false;

  @override
  void initState() {
    super.initState();
    _startInitSequence();
  }

  Future<void> _startInitSequence() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAuth = prefs.getBool('is_logged_in');
    final firebaseAuthUser = FirebaseAuth.instance.currentUser;
    final hasSeenOnboarding = prefs.getBool('has_seen_get_started') ?? false;

    // Check if user is logged in (both persisted flag and active Firebase Auth session required)
    final loggedIn = (savedAuth == true) && (firebaseAuthUser != null);

    // Maintain brief splash screen duration to present official brand crest and establish listeners
    await Future.delayed(const Duration(milliseconds: 1800));

    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
        _hasSeenGetStarted = hasSeenOnboarding;
        _isInitializing = false;
      });
    }
  }

  void _onGetStartedCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_get_started', true);
    if (mounted) {
      setState(() {
        _hasSeenGetStarted = true;
      });
    }
  }

  void _onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Logout notice: $e');
    }
    ref.invalidate(authUserProvider);
    ref.invalidate(currentUserStreamProvider);
    if (mounted) {
      setState(() {
        _isLoggedIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    Widget homeWidget;
    if (_isInitializing) {
      homeWidget = const SplashScreen();
    } else if (_isLoggedIn) {
      // Role-Based Routing Guard
      final userAsync = ref.watch(currentUserStreamProvider);
      homeWidget = userAsync.when(
        data: (user) {
          if (user.role.toLowerCase().contains('customer')) {
            return CustomerHomeScreen(
              onLogout: _onLogout,
            );
          }
          return MainNavigationShell(
            onLogout: _onLogout,
          );
        },
        loading: () => const SplashScreen(),
        error: (err, stack) {
          return MainNavigationShell(
            onLogout: _onLogout,
          );
        },
      );
    } else if (!_hasSeenGetStarted) {
      // First-time intro page
      homeWidget = GetStartedScreen(
        onGetStarted: _onGetStartedCompleted,
      );
    } else {
      // Returning user who logged out
      homeWidget = LoginScreen(
        onLoginSuccess: () {
          setState(() => _isLoggedIn = true);
        },
      );
    }

    return MaterialApp(
      title: 'Wimalasooriya Farms',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: homeWidget,
    );
  }
}
