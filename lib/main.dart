import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'features/repartidor/views/repartidor_view.dart';
import 'providers/auth_provider.dart';
import 'services/firebase_push_service.dart';
import 'services/notification_service.dart';
import 'views/dashboard_view.dart';
import 'views/login_view.dart';
import 'views/tienda_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await _tryInitializeFirebase();
  await NotificationService.instance.initialize();
  if (firebaseReady) {
    await FirebasePushService.instance.initialize();
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..initialize(),
      child: const MyApp(),
    ),
  );
}

Future<bool> _tryInitializeFirebase() async {
  try {
    await Firebase.initializeApp();
    return true;
  } on FirebaseException catch (error) {
    debugPrint('Firebase disabled: ${error.message ?? error.code}');
  } catch (error) {
    debugPrint('Firebase disabled: $error');
  }
  return false;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tech-Metrics',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routes: {
        AppRoutes.login: (_) => const LoginView(),
        AppRoutes.dashboard: (_) => const ProtectedRoute(child: DashboardView()),
        AppRoutes.tienda: (_) => const TiendaView(),
        AppRoutes.repartidor: (_) => const RepartidorView(),
      },
      home: const AuthGate(),
    );
  }
}

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String tienda = '/tienda';
  static const String repartidor = '/repartidor';
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final authStatus = authProvider.status;

    if (authStatus == AuthStatus.checking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authStatus == AuthStatus.authenticated) {
      if (authProvider.user?.isSuperAdmin == true) return const DashboardView();
      if (authProvider.user?.isRepartidor == true) return const RepartidorView();
      return const TiendaView();
    }

    return const LoginView();
  }
}

class ProtectedRoute extends StatelessWidget {
  const ProtectedRoute({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final authStatus = context.watch<AuthProvider>().status;

    if (authStatus == AuthStatus.checking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authStatus != AuthStatus.authenticated ||
        context.read<AuthProvider>().user?.isSuperAdmin != true) {
      return const LoginView();
    }

    return child;
  }
}
