import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class TiendaView extends StatelessWidget {
  const TiendaView({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final nombre = user?.nombreCompleto ?? user?.usuario ?? 'invitado';

    return Scaffold(
      appBar: AppBar(
        title: const Text('NAYLEX Store'),
        actions: [
          if (authProvider.isAuthenticated)
            IconButton(
              tooltip: 'Cerrar sesion',
              onPressed: () async {
                await context.read<AuthProvider>().logout();
              },
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.storefront,
                size: 72,
                color: Colors.teal,
              ),
              const SizedBox(height: 16),
              Text(
                'Bienvenido, $nombre',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                authProvider.isAuthenticated
                    ? 'Sesion activa como ${user?.rol ?? 'Usuario'}'
                    : 'Explorando la tienda',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
