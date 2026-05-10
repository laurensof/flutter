import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reporte_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late Future<List<ReporteModel>> _reportesFuture;

  @override
  void initState() {
    super.initState();
    _reportesFuture = _cargarReportes();
  }

  Future<List<ReporteModel>> _cargarReportes() async {
    final response = await ApiService().getReportes();
    if (!response.success) {
      throw Exception(response.message ?? 'No se pudieron cargar los reportes');
    }
    return response.data ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesion',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;
          final nombre = user?.nombreCompleto ?? user?.nombre;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _reportesFuture = _cargarReportes();
              });
              try {
                await _reportesFuture;
              } catch (_) {
                // El FutureBuilder muestra el error dentro de la pantalla.
              }
            },
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _DashboardHeader(
                  nombre: nombre,
                  rol: user?.rol,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Text(
                      'Reportes',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    IconButton.filledTonal(
                      tooltip: 'Actualizar reportes',
                      onPressed: () {
                        setState(() {
                          _reportesFuture = _cargarReportes();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                FutureBuilder<List<ReporteModel>>(
                  future: _reportesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return _ReportesMensaje(
                        icon: Icons.error_outline,
                        title: 'No se pudieron cargar los reportes',
                        message: snapshot.error.toString(),
                      );
                    }

                    final reportes = snapshot.data ?? const [];
                    if (reportes.isEmpty) {
                      return const _ReportesMensaje(
                        icon: Icons.insights,
                        title: 'Sin reportes disponibles',
                        message: 'La API respondio sin datos para mostrar.',
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 620;
                        return GridView.builder(
                          itemCount: reportes.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isWide ? 2 : 1,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            mainAxisExtent: 132,
                          ),
                          itemBuilder: (context, index) {
                            return _ReporteCard(
                              reporte: reportes[index],
                              index: index,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.nombre,
    required this.rol,
  });

  final String? nombre;
  final String? rol;

  @override
  Widget build(BuildContext context) {
    final title = nombre != null
        ? 'Bienvenido, $nombre'
        : 'Bienvenido al panel administrador';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              size: 34,
              color: Color(0xFF1769AA),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                ),
                if (rol != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    rol!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF667085),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReporteCard extends StatelessWidget {
  const _ReporteCard({
    required this.reporte,
    required this.index,
  });

  final ReporteModel reporte;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF1769AA),
      const Color(0xFF00897B),
      const Color(0xFF7B61FF),
      const Color(0xFFEF6C00),
      const Color(0xFFC62828),
    ];
    final color = colors[index % colors.length];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7EAF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _iconForTitle(reporte.titulo),
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reporte.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    reporte.valor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF101828),
                          height: 1,
                        ),
                  ),
                  Text(
                    reporte.descripcion ?? 'Total registrado',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF667085),
                          height: 1.1,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForTitle(String title) {
    final normalized = title.toLowerCase();
    if (normalized.contains('usuario')) {
      return Icons.people_alt;
    }
    if (normalized.contains('producto')) {
      return Icons.inventory_2;
    }
    if (normalized.contains('venta')) {
      return Icons.point_of_sale;
    }
    if (normalized.contains('pedido')) {
      return Icons.receipt_long;
    }
    return Icons.bar_chart;
  }
}

class _ReportesMensaje extends StatelessWidget {
  const _ReportesMensaje({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
