import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/repartidor/views/repartidor_view.dart';
import 'providers/auth_provider.dart';
import 'views/dashboard_view.dart';
import 'views/login_view.dart';
import 'views/tienda_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..initialize(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin App',
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
      if (authProvider.isAdmin) return const DashboardView();
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

    if (authStatus != AuthStatus.authenticated) {
      return const LoginView();
    }

    return child;
  }
}
