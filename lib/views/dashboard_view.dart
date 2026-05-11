import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/reportes_dashboard_model.dart';
import '../models/reporte_model.dart';
import '../models/registro_model.dart';
import '../models/venta_grafico_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/logout_modal.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late Future<List<ReporteModel>> _reportesFuture;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _reportesFuture = _cargarReportes();
  }

  void _mostrarGeneradorQr(BuildContext context) {
    final controller = TextEditingController();
    String? idActual;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Generar QR de pedido',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF101828))),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'ID del pedido',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.confirmation_number_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    final id = controller.text.trim();
                    if (id.isNotEmpty && int.tryParse(id) != null) {
                      setDialogState(() => idActual = id);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F6FED),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 46),
                  ),
                  child: const Text('Generar', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                if (idActual != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: idActual!,
                      version: QrVersions.auto,
                      size: 180,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Pedido #$idActual',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF667085), fontWeight: FontWeight.w500)),
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<List<ReporteModel>> _cargarReportes() async {
    final response = await ApiService().getReportes();
    if (response.success && (response.data ?? const []).isNotEmpty) {
      return response.data ?? const [];
    }

    final dashboardResponse = await ApiService().getReportesDashboard(
      periodo: 'hoy',
    );
    if (dashboardResponse.success && dashboardResponse.data != null) {
      return _reportesDesdeDashboard(dashboardResponse.data!);
    }

    throw Exception(
      response.message ??
          dashboardResponse.message ??
          'No se pudieron cargar los reportes',
    );
  }

  List<ReporteModel> _reportesDesdeDashboard(ReportesDashboardModel data) {
    return [
      ReporteModel(
        titulo: 'Ventas',
        valor: _formatMoney(data.ventasTotales),
        descripcion: 'Ventas de hoy',
        variacionPorcentaje: data.variacionVentas,
        tendencia: (data.variacionVentas ?? 0) < 0 ? 'baja' : 'sube',
      ),
      ReporteModel(
        titulo: 'Productos',
        valor: data.topProductos.length.toString(),
        descripcion: 'Productos con ventas',
      ),
      ReporteModel(
        titulo: 'Clientes',
        valor: data.topClientes.length.toString(),
        descripcion: 'Clientes con compras',
      ),
      ReporteModel(
        titulo: 'Proveedores',
        valor: data.topProveedores.length.toString(),
        descripcion: 'Proveedores con compras',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['Inicio', 'Reportes', 'Registro', 'Perfil'];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        title: Text(titles[_selectedIndex]),
        actions: [
          IconButton(
            tooltip: 'Generar QR de pedido',
            onPressed: () => _mostrarGeneradorQr(context),
            icon: const Icon(Icons.qr_code),
          ),
          IconButton(
            tooltip: 'Cerrar sesion',
            onPressed: () => showLogoutModal(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;
          final nombre = user?.nombreCompleto ?? user?.nombre;

          Widget buildReportesSection() {
            return const _ReportesSection();
          }

          final pages = [
            _InicioSection(
              reportesFuture: _reportesFuture,
              onRefresh: () {
                setState(() {
                  _reportesFuture = _cargarReportes();
                });
              },
              ordenarReportes: _ordenarReportes,
            ),
            buildReportesSection(),
            const _RegistroSection(),
            _PerfilSection(
              nombre: nombre,
              username: user?.usuario,
              rol: user?.rol,
            ),
          ];

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
            child: pages[_selectedIndex],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2F6FED),
        unselectedItemColor: const Color(0xFF7A8494),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        backgroundColor: Colors.white,
        elevation: 16,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Reportes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.app_registration_outlined),
            activeIcon: Icon(Icons.app_registration),
            label: 'Registro',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  List<ReporteModel> _ordenarReportes(List<ReporteModel> reportes) {
    final orden = ['venta', 'pedido', 'producto', 'usuario', 'cliente'];
    final copia = List<ReporteModel>.from(reportes);

    copia.sort((a, b) {
      final aIndex = _ordenIndex(a.titulo, orden);
      final bIndex = _ordenIndex(b.titulo, orden);
      return aIndex.compareTo(bIndex);
    });

    return copia;
  }

  int _ordenIndex(String titulo, List<String> orden) {
    final normalized = titulo.toLowerCase();
    final index = orden.indexWhere((item) => normalized.contains(item));
    return index == -1 ? orden.length : index;
  }
}

class _InicioSection extends StatelessWidget {
  const _InicioSection({
    required this.reportesFuture,
    required this.onRefresh,
    required this.ordenarReportes,
  });

  final Future<List<ReporteModel>> reportesFuture;
  final VoidCallback onRefresh;
  final List<ReporteModel> Function(List<ReporteModel>) ordenarReportes;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      children: [
        _ReportesContent(
          title: 'Estadistica',
          reportesFuture: reportesFuture,
          onRefresh: onRefresh,
          ordenarReportes: ordenarReportes,
        ),
        const SizedBox(height: 18),
        const _VentasChartCard(),
      ],
    );
  }
}

class _ReportesSection extends StatefulWidget {
  const _ReportesSection();

  @override
  State<_ReportesSection> createState() => _ReportesSectionState();
}

class _ReportesSectionState extends State<_ReportesSection> {
  late Future<ReportesDashboardModel> _future;
  String _periodo = 'hoy';
  DateTime? _desde;
  DateTime? _hasta;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ReportesDashboardModel> _load() async {
    final response = await ApiService().getReportesDashboard(
      periodo: _periodo,
      desde: _periodo == 'rango' ? _desde : null,
      hasta: _periodo == 'rango' ? _hasta : null,
    );
    if (!response.success || response.data == null) {
      throw Exception(response.message ?? 'No se pudieron cargar los reportes');
    }
    return response.data!;
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _changePeriodo(String periodo) async {
    if (periodo == 'rango') {
      await _showCustomRangeDialog();
      return;
    }
    if (_periodo == periodo) {
      return;
    }
    setState(() {
      _periodo = periodo;
      _desde = null;
      _hasta = null;
      _future = _load();
    });
  }

  Future<void> _showCustomRangeDialog() async {
    final now = DateTime.now();
    DateTime localDesde = _desde ?? DateTime(now.year, now.month, 1);
    DateTime localHasta = _hasta ?? DateTime(now.year, now.month, now.day);

    final applied = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDesde() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: localDesde,
                firstDate: DateTime(2020),
                lastDate: now,
              );
              if (picked == null) {
                return;
              }
              setDialogState(() {
                localDesde = picked;
                if (localHasta.isBefore(localDesde)) {
                  localHasta = localDesde;
                }
              });
            }

            Future<void> pickHasta() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: localHasta,
                firstDate: localDesde,
                lastDate: now,
              );
              if (picked == null) {
                return;
              }
              setDialogState(() => localHasta = picked);
            }

            return AlertDialog(
              title: const Text('Rango personalizado'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RangeDateButton(
                    label: 'Desde',
                    value: _formatDateLabel(localDesde),
                    onTap: pickDesde,
                  ),
                  const SizedBox(height: 10),
                  _RangeDateButton(
                    label: 'Hasta',
                    value: _formatDateLabel(localHasta),
                    onTap: pickHasta,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (applied != true) {
      return;
    }

    setState(() {
      _periodo = 'rango';
      _desde = localDesde;
      _hasta = localHasta;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        Row(
          children: [
            Text(
              'Reportes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const Spacer(),
            PopupMenuButton<String>(
              tooltip: 'Filtrar reportes',
              initialValue: _periodo,
              onSelected: _changePeriodo,
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'hoy', child: Text('Hoy')),
                PopupMenuItem(value: 'semana', child: Text('Esta semana')),
                PopupMenuItem(value: 'semana_pasada', child: Text('Semana pasada')),
                PopupMenuItem(value: 'mes', child: Text('Este mes')),
                PopupMenuItem(value: 'mes_pasado', child: Text('Mes pasado')),
                PopupMenuItem(value: 'anio', child: Text('Este año')),
                PopupMenuItem(value: 'rango', child: Text('Rango personalizado')),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      size: 16,
                      color: Color(0xFF2F6FED),
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 132),
                      child: Text(
                        _periodoLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF2F6FED),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: Color(0xFF2F6FED),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Actualizar reportes',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FutureBuilder<ReportesDashboardModel>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
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

            final data = snapshot.data!;
            return Column(
              children: [
                _VentasTotalesCard(data: data),
                const SizedBox(height: 12),
                _VentasBarChartCard(items: data.ventasPorDia),
                const SizedBox(height: 12),
                _RankingGrid(data: data),
              ],
            );
          },
        ),
      ],
    );
  }

  String get _periodoLabel {
    if (_periodo == 'hoy') {
      return 'Hoy';
    }
    if (_periodo == 'semana') {
      return 'Esta semana';
    }
    if (_periodo == 'semana_pasada') {
      return 'Semana pasada';
    }
    if (_periodo == 'mes_pasado') {
      return 'Mes pasado';
    }
    if (_periodo == 'anio') {
      return 'Este año';
    }
    if (_periodo == 'rango' && _desde != null && _hasta != null) {
      return '${_formatDateLabel(_desde!)} - ${_formatDateLabel(_hasta!)}';
    }
    return 'Este mes';
  }

  String _formatDateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _RangeDateButton extends StatelessWidget {
  const _RangeDateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7EAF0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: Color(0xFF2F6FED)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$label: $value',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const Icon(Icons.edit_calendar, size: 18, color: Color(0xFF667085)),
          ],
        ),
      ),
    );
  }
}

class _VentasTotalesCard extends StatelessWidget {
  const _VentasTotalesCard({required this.data});

  final ReportesDashboardModel data;

  @override
  Widget build(BuildContext context) {
    final variation = data.variacionVentas ?? 0;
    final isDown = variation < 0;
    final color = isDown ? const Color(0xFFE5484D) : const Color(0xFF30B566);

    return _ReportCardShell(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 13,
                      backgroundColor: Color(0xFFEAF3FF),
                      child: Icon(
                        Icons.attach_money,
                        size: 17,
                        color: Color(0xFF2F6FED),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ventas totales',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF667085),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _formatMoney(data.ventasTotales),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF101828),
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isDown ? Icons.trending_down : Icons.trending_up,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${variation >= 0 ? '+' : ''}${variation.toStringAsFixed(1)}% vs. mes anterior',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VentasBarChartCard extends StatefulWidget {
  const _VentasBarChartCard({required this.items});

  final List<ReporteBarItem> items;

  @override
  State<_VentasBarChartCard> createState() => _VentasBarChartCardState();
}

class _VentasBarChartCardState extends State<_VentasBarChartCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _VentasBarChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ReportCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ventas por dia',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF101828),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _controller.forward(from: 0),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ReportesBarChartPainter(
                      widget.items,
                      progress: _animation.value,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingGrid extends StatelessWidget {
  const _RankingGrid({required this.data});

  final ReportesDashboardModel data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 340 ? 2 : 1;
        final cards = [
          _RankingCard(
            title: 'Top productos mas vendidos',
            items: data.topProductos,
            accent: const Color(0xFF2F6FED),
          ),
          _RankingCard(
            title: 'Top clientes con mas compras',
            items: data.topClientes,
            accent: const Color(0xFF2F6FED),
          ),
          _RankingCard(
            title: 'Top proveedores mas comprados',
            items: data.topProveedores,
            accent: const Color(0xFF2F6FED),
          ),
          _BestDayCard(day: data.diaMasVendido),
        ];

        return GridView.builder(
          itemCount: cards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 178,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({
    required this.title,
    required this.items,
    required this.accent,
  });

  final String title;
  final List<ReporteRankingItem> items;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _ReportCardShell(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF101828),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('Sin datos'))
                : Column(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        _RankingRow(
                          index: i + 1,
                          item: items[i],
                          accent: accent,
                          sectionTitle: title,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.index,
    required this.item,
    required this.accent,
    required this.sectionTitle,
  });

  final int index;
  final ReporteRankingItem item;
  final Color accent;
  final String sectionTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showRankingDetail(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: accent,
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF344054),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    item.detalle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF667085),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: Color(0xFF98A2B3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRankingDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: accent,
                      child: Text(
                        '$index',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sectionTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF667085),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  item.nombre,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF101828),
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.detalle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF344054),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BestDayCard extends StatelessWidget {
  const _BestDayCard({required this.day});

  final DiaMasVendidoModel? day;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF9F0),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D2939).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: day == null
          ? const Center(child: Text('Sin datos'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mejor dia registrado',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF30B566),
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF45B649),
                      child: Icon(Icons.calendar_month, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        day!.fecha,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: const Color(0xFF101828),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _formatMoney(day!.total),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF30B566),
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  '${day!.ventas} ventas realizadas',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF667085),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
    );
  }
}

class _ReportCardShell extends StatelessWidget {
  const _ReportCardShell({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D2939).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ReportesBarChartPainter extends CustomPainter {
  const _ReportesBarChartPainter(
    this.items, {
    required this.progress,
  });

  final List<ReporteBarItem> items;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final animationValue = progress.clamp(0.0, 1.0).toDouble();
    final left = 30.0;
    final top = 10.0;
    final right = size.width - 8;
    final bottom = size.height - 28;
    final width = right - left;
    final height = bottom - top;
    final maxValue = items
        .map((item) => item.total)
        .fold<double>(0, (previous, value) => value > previous ? value : previous);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final gridPaint = Paint()
      ..color = const Color(0xFFE7EAF0)
      ..strokeWidth = 1;

    for (var i = 0; i <= 3; i++) {
      final y = bottom - (height / 3 * i);
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
      textPainter.text = TextSpan(
        text: _formatShortMoney(safeMax / 3 * i),
        style: const TextStyle(
          color: Color(0xFF98A2B3),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 7));
    }

    if (items.isEmpty) {
      return;
    }

    final gap = width / items.length;
    final barWidth = gap * 0.42;
    final barPaint = Paint()..color = const Color(0xFF2F6FED);

    for (var i = 0; i < items.length; i++) {
      final x = left + gap * i + (gap - barWidth) / 2;
      final itemProgress = (animationValue * items.length - i)
          .clamp(0.0, 1.0)
          .toDouble();
      final barHeight = (items[i].total / safeMax) *
          height *
          Curves.easeOutCubic.transform(itemProgress);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, bottom - barHeight, barWidth, barHeight),
        const Radius.circular(5),
      );
      canvas.drawRRect(rect, barPaint);

      textPainter.text = TextSpan(
        text: items[i].label,
        style: const TextStyle(
          color: Color(0xFF667085),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout(maxWidth: gap);
      textPainter.paint(
        canvas,
        Offset(left + gap * i + gap / 2 - textPainter.width / 2, bottom + 9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ReportesBarChartPainter oldDelegate) {
    return oldDelegate.items != items || oldDelegate.progress != progress;
  }
}

String _formatMoney(double value) {
  return '\$${value.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      )}';
}

String _formatShortMoney(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(0)}m';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(0)}k';
  }
  return value.toStringAsFixed(0);
}

class _VentasChartCard extends StatefulWidget {
  const _VentasChartCard();

  @override
  State<_VentasChartCard> createState() => _VentasChartCardState();
}

class _VentasChartCardState extends State<_VentasChartCard>
    with SingleTickerProviderStateMixin {
  String _periodo = 'diaria';
  late Future<List<VentaGraficoModel>> _ventasFuture;
  late final AnimationController _chartController;
  late final Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeOutCubic,
    );
    _ventasFuture = _cargarVentas();
  }

  @override
  void dispose() {
    _chartController.dispose();
    super.dispose();
  }

  Future<List<VentaGraficoModel>> _cargarVentas() async {
    final response = await ApiService().getVentasGrafico(_periodo);
    if (!response.success) {
      throw Exception(response.message ?? 'No se pudieron cargar las ventas');
    }
    return response.data ?? const [];
  }

  void _cambiarPeriodo(String periodo) {
    if (_periodo == periodo) {
      return;
    }
    setState(() {
      _periodo = periodo;
      _ventasFuture = _cargarVentas();
    });
    _chartController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D2939).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _chartTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF101828),
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Filtrar ventas',
                initialValue: _periodo,
                onSelected: _cambiarPeriodo,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'mes', child: Text('Mes')),
                  PopupMenuItem(value: 'quincenal', child: Text('Quincenal')),
                  PopupMenuItem(value: 'diaria', child: Text('Diaria')),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE7EAF0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _periodoLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF344054),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<VentaGraficoModel>>(
            future: _ventasFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 245,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SizedBox(
                  height: 245,
                  child: _ChartMessage(
                    icon: Icons.error_outline,
                    message: snapshot.error.toString(),
                  ),
                );
              }

              final ventas = snapshot.data ?? const [];
              if (ventas.isEmpty) {
                return const SizedBox(
                  height: 245,
                  child: _ChartMessage(
                    icon: Icons.show_chart,
                    message: 'Sin ventas para este filtro.',
                  ),
                );
              }

              if (_chartController.status == AnimationStatus.dismissed) {
                _chartController.forward();
              }

              return SizedBox(
                height: 245,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _chartController.forward(from: 0),
                  child: AnimatedBuilder(
                    animation: _chartAnimation,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _VentasLineChartPainter(
                          ventas,
                          progress: _chartAnimation.value,
                        ),
                        child: const SizedBox.expand(),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String get _periodoLabel {
    if (_periodo == 'mes') {
      return 'Mes';
    }
    if (_periodo == 'quincenal') {
      return 'Quincenal';
    }
    return 'Diaria';
  }

  String get _chartTitle {
    if (_periodo == 'mes') {
      return 'Ventas por mes';
    }
    if (_periodo == 'quincenal') {
      return 'Ventas quincenales';
    }
    return 'Ventas diarias';
  }
}

class _ChartMessage extends StatelessWidget {
  const _ChartMessage({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF98A2B3)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF667085),
                ),
          ),
        ],
      ),
    );
  }
}

class _VentasLineChartPainter extends CustomPainter {
  const _VentasLineChartPainter(
    this.ventas, {
    required this.progress,
  });

  final List<VentaGraficoModel> ventas;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final animationValue = progress.clamp(0.0, 1.0).toDouble();
    final chartLeft = 36.0;
    final chartTop = 10.0;
    final chartRight = size.width - 12;
    final chartBottom = size.height - 28;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;
    final maxValue = ventas
        .map((venta) => venta.total)
        .fold<double>(0, (previous, value) => value > previous ? value : previous);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    final axisPaint = Paint()
      ..color = const Color(0xFFE7EAF0)
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i <= 3; i++) {
      final y = chartBottom - (chartHeight / 3 * i);
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), axisPaint);
      textPainter.text = TextSpan(
        text: _formatAxisValue(safeMax / 3 * i),
        style: const TextStyle(
          color: Color(0xFF98A2B3),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 7));
    }

    final points = <Offset>[];
    for (var i = 0; i < ventas.length; i++) {
      final x = ventas.length == 1
          ? chartLeft + chartWidth / 2
          : chartLeft + (chartWidth / (ventas.length - 1) * i);
      final y = chartBottom - ((ventas[i].total / safeMax) * chartHeight);
      points.add(Offset(x, y));

      textPainter.text = TextSpan(
        text: ventas[i].label,
        style: const TextStyle(
          color: Color(0xFF667085),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout(maxWidth: 44);
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chartBottom + 9),
      );
    }

    if (points.isEmpty) {
      return;
    }

    final visiblePoints = _visiblePoints(points, animationValue);
    if (visiblePoints.isEmpty) {
      return;
    }

    final fillPath = Path()
      ..moveTo(visiblePoints.first.dx, chartBottom);
    for (final point in visiblePoints) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath
      ..lineTo(visiblePoints.last.dx, chartBottom)
      ..close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x332F6FED),
          Color(0x002F6FED),
        ],
      ).createShader(Rect.fromLTRB(chartLeft, chartTop, chartRight, chartBottom));
    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()
      ..moveTo(visiblePoints.first.dx, visiblePoints.first.dy);
    for (var i = 1; i < visiblePoints.length; i++) {
      linePath.lineTo(visiblePoints[i].dx, visiblePoints[i].dy);
    }

    final linePaint = Paint()
      ..color = const Color(0xFF2F6FED)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = Colors.white;
    final dotBorderPaint = Paint()
      ..color = const Color(0xFF2F6FED)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < points.length; i++) {
      final pointProgress = (animationValue * points.length - i)
          .clamp(0.0, 1.0)
          .toDouble();
      if (pointProgress <= 0) {
        continue;
      }
      final radius = 4.5 * Curves.easeOutBack.transform(pointProgress);
      canvas.drawCircle(points[i], radius, dotPaint);
      canvas.drawCircle(points[i], radius, dotBorderPaint);
    }
  }

  List<Offset> _visiblePoints(List<Offset> points, double progress) {
    if (points.length <= 1) {
      return progress > 0 ? points : const [];
    }

    final totalSegments = points.length - 1;
    final scaledProgress = progress * totalSegments;
    final completedSegments = scaledProgress.floor();
    final segmentProgress = scaledProgress - completedSegments;
    final visible = <Offset>[];

    for (var i = 0; i <= completedSegments && i < points.length; i++) {
      visible.add(points[i]);
    }

    final nextIndex = completedSegments + 1;
    if (nextIndex < points.length && segmentProgress > 0) {
      final start = points[completedSegments];
      final end = points[nextIndex];
      visible.add(
        Offset.lerp(start, end, segmentProgress) ?? end,
      );
    }

    return visible;
  }

  String _formatAxisValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(0)}m';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _VentasLineChartPainter oldDelegate) {
    return oldDelegate.ventas != ventas || oldDelegate.progress != progress;
  }
}

class _ReportesContent extends StatelessWidget {
  const _ReportesContent({
    required this.title,
    required this.reportesFuture,
    required this.onRefresh,
    required this.ordenarReportes,
  });

  final String title;
  final Future<List<ReporteModel>> reportesFuture;
  final VoidCallback onRefresh;
  final List<ReporteModel> Function(List<ReporteModel>) ordenarReportes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Spacer(),
            IconButton.filledTonal(
              tooltip: 'Actualizar reportes',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<ReporteModel>>(
          future: reportesFuture,
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

            final reportes = ordenarReportes(snapshot.data ?? const []);
            if (reportes.isEmpty) {
              return const _ReportesMensaje(
                icon: Icons.insights,
                title: 'Sin reportes disponibles',
                message: 'La API respondio sin datos para mostrar.',
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 340 ? 2 : 1;
                return GridView.builder(
                  itemCount: reportes.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 142,
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
    );
  }
}

enum _RegistroView {
  menu,
  proveedores,
  proveedorForm,
  productos,
  productoForm,
}

class _RegistroSection extends StatefulWidget {
  const _RegistroSection();

  @override
  State<_RegistroSection> createState() => _RegistroSectionState();
}

class _RegistroSectionState extends State<_RegistroSection> {
  _RegistroView _view = _RegistroView.menu;
  ProveedorRegistroModel? _selectedProveedor;
  ProductoRegistroModel? _selectedProducto;

  void _go(_RegistroView view) {
    setState(() {
      _view = view;
    });
  }

  void _back() {
    setState(() {
      if (_view == _RegistroView.menu) {
        return;
      }
      if (_view == _RegistroView.proveedorForm) {
        _view = _RegistroView.proveedores;
        _selectedProveedor = null;
        return;
      }
      if (_view == _RegistroView.productoForm) {
        _view = _RegistroView.productos;
        _selectedProducto = null;
        return;
      }
      _view = _RegistroView.menu;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_view == _RegistroView.proveedores) {
      content = _ProveedoresList(
        onBack: _back,
        onNew: () {
          _selectedProveedor = null;
          _go(_RegistroView.proveedorForm);
        },
        onEdit: (proveedor) {
          _selectedProveedor = proveedor;
          _go(_RegistroView.proveedorForm);
        },
      );
    } else if (_view == _RegistroView.proveedorForm) {
      content = _ProveedorForm(
        proveedor: _selectedProveedor,
        onBack: _back,
        onSaved: () {
          _selectedProveedor = null;
          _go(_RegistroView.proveedores);
        },
      );
    } else if (_view == _RegistroView.productos) {
      content = _ProductosList(
        onBack: _back,
        onNew: () {
          _selectedProducto = null;
          _go(_RegistroView.productoForm);
        },
        onEdit: (producto) {
          _selectedProducto = producto;
          _go(_RegistroView.productoForm);
        },
      );
    } else if (_view == _RegistroView.productoForm) {
      content = _ProductoForm(
        producto: _selectedProducto,
        onBack: _back,
        onSaved: () {
          _selectedProducto = null;
          _go(_RegistroView.productos);
        },
      );
    } else {
      content = ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          Text(
            'Registro',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Administra proveedores y productos sin salir de este apartado.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF667085),
                ),
          ),
          const SizedBox(height: 18),
          const _RegistroActionBanner(),
          const SizedBox(height: 18),
          _RegistroMenuButton(
            icon: Icons.business,
            title: 'Proveedores',
            subtitle: 'Registrar, buscar y editar proveedores',
            accentColor: const Color(0xFF2F6FED),
            backgroundColor: const Color(0xFFEAF3FF),
            onTap: () => _go(_RegistroView.proveedores),
          ),
          const SizedBox(height: 14),
          _RegistroMenuButton(
            icon: Icons.inventory_2_outlined,
            title: 'Productos',
            subtitle: 'Ver stock, registrar y actualizar productos',
            accentColor: const Color(0xFF7C3AED),
            backgroundColor: const Color(0xFFF3ECFF),
            onTap: () => _go(_RegistroView.productos),
          ),
        ],
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(_view),
        child: content,
      ),
    );
  }
}

class _RegistroActionBanner extends StatelessWidget {
  const _RegistroActionBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF1F6FED), Color(0xFF20C8B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F6FED).withOpacity(0.22),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_graph, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestion rapida',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Toca una tarjeta para entrar, editar y volver al mismo menu.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.86),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistroMenuButton extends StatefulWidget {
  const _RegistroMenuButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  State<_RegistroMenuButton> createState() => _RegistroMenuButtonState();
}

class _RegistroMenuButtonState extends State<_RegistroMenuButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _pressed
                  ? widget.accentColor.withOpacity(0.34)
                  : Colors.white,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_pressed ? 0.06 : 0.04),
                blurRadius: _pressed ? 14 : 22,
                offset: Offset(0, _pressed ? 8 : 12),
              ),
            ],
          ),
          child: Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.94, end: 1),
                duration: const Duration(milliseconds: 420),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(widget.icon, color: widget.accentColor, size: 31),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF667085),
                          ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(_pressed ? 0.16 : 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chevron_right, color: widget.accentColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProveedoresList extends StatefulWidget {
  const _ProveedoresList({
    required this.onBack,
    required this.onNew,
    required this.onEdit,
  });

  final VoidCallback onBack;
  final VoidCallback onNew;
  final ValueChanged<ProveedorRegistroModel> onEdit;

  @override
  State<_ProveedoresList> createState() => _ProveedoresListState();
}

class _ProveedoresListState extends State<_ProveedoresList> {
  late Future<List<ProveedorRegistroModel>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ProveedorRegistroModel>> _load() async {
    final response = await ApiService().getProveedores();
    if (!response.success) {
      throw Exception(response.message ?? 'No se pudieron cargar proveedores');
    }
    return response.data ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    return _RegistroListScaffold<ProveedorRegistroModel>(
      title: 'Proveedores',
      hint: 'Buscar proveedores...',
      future: _future,
      query: _query,
      onQueryChanged: (value) => setState(() => _query = value),
      onBack: widget.onBack,
      onNew: widget.onNew,
      filter: (item, query) =>
          item.nombre.toLowerCase().contains(query) ||
          item.rut.toLowerCase().contains(query),
      itemBuilder: (context, item) {
        return _RegistroListTile(
          title: item.nombre,
          subtitle: '${item.rut} - ${item.telefono}',
          trailing: item.estado,
          icon: Icons.business,
          accentColor: const Color(0xFF2F6FED),
          onEdit: () => widget.onEdit(item),
        );
      },
    );
  }
}

class _ProductosList extends StatefulWidget {
  const _ProductosList({
    required this.onBack,
    required this.onNew,
    required this.onEdit,
  });

  final VoidCallback onBack;
  final VoidCallback onNew;
  final ValueChanged<ProductoRegistroModel> onEdit;

  @override
  State<_ProductosList> createState() => _ProductosListState();
}

class _ProductosListState extends State<_ProductosList> {
  late Future<List<ProductoRegistroModel>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ProductoRegistroModel>> _load() async {
    final response = await ApiService().getProductosRegistro();
    if (!response.success) {
      throw Exception(response.message ?? 'No se pudieron cargar productos');
    }
    return response.data ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    return _RegistroListScaffold<ProductoRegistroModel>(
      title: 'Productos',
      hint: 'Buscar productos...',
      future: _future,
      query: _query,
      onQueryChanged: (value) => setState(() => _query = value),
      onBack: widget.onBack,
      onNew: widget.onNew,
      filter: (item, query) =>
          item.nombre.toLowerCase().contains(query) ||
          item.codigo.toLowerCase().contains(query),
      itemBuilder: (context, item) {
        return _RegistroListTile(
          title: item.nombre,
          subtitle:
              '${item.codigo.isEmpty ? 'Sin codigo' : item.codigo} - ${item.categoria ?? 'Sin categoria'} - Stock ${item.stock}',
          trailing: '\$${item.precio.toStringAsFixed(2)}',
          icon: Icons.inventory_2_outlined,
          accentColor: const Color(0xFF7C3AED),
          onEdit: () => widget.onEdit(item),
        );
      },
    );
  }
}

class _RegistroListScaffold<T> extends StatelessWidget {
  const _RegistroListScaffold({
    required this.title,
    required this.hint,
    required this.future,
    required this.query,
    required this.onQueryChanged,
    required this.onBack,
    required this.onNew,
    required this.filter,
    required this.itemBuilder,
  });

  final String title;
  final String hint;
  final Future<List<T>> future;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onBack;
  final VoidCallback onNew;
  final bool Function(T, String) filter;
  final Widget Function(BuildContext, T) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        Row(
          children: [
            IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            FilledButton.icon(
              onPressed: onNew,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: onQueryChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<T>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return _ReportesMensaje(
                icon: Icons.error_outline,
                title: 'No se pudo cargar',
                message: snapshot.error.toString(),
              );
            }
            final normalizedQuery = query.toLowerCase().trim();
            final sourceItems = snapshot.data ?? <T>[];
            final items = sourceItems
                .where((item) =>
                    normalizedQuery.isEmpty || filter(item, normalizedQuery))
                .toList();
            if (items.isEmpty) {
              return const _ReportesMensaje(
                icon: Icons.search_off,
                title: 'Sin resultados',
                message: 'No hay datos para mostrar.',
              );
            }
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Column(
                key: ValueKey('${items.length}-$normalizedQuery'),
                children: [
                  _RegistroResultPill(
                    count: items.length,
                    query: normalizedQuery,
                  ),
                  const SizedBox(height: 12),
                  for (var index = 0; index < items.length; index++) ...[
                    _StaggeredListItem(
                      index: index,
                      child: itemBuilder(context, items[index]),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RegistroResultPill extends StatelessWidget {
  const _RegistroResultPill({
    required this.count,
    required this.query,
  });

  final int count;
  final String query;

  @override
  Widget build(BuildContext context) {
    final label = query.isEmpty
        ? '$count registros cargados'
        : '$count resultados para "$query"';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3FF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt, size: 16, color: Color(0xFF2F6FED)),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF2F6FED),
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaggeredListItem extends StatelessWidget {
  const _StaggeredListItem({
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delaySteps = index < 6 ? index : 6;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + (delaySteps * 38)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _RegistroListTile extends StatefulWidget {
  const _RegistroListTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.icon,
    required this.accentColor,
    required this.onEdit,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onEdit;

  @override
  State<_RegistroListTile> createState() => _RegistroListTileState();
}

class _RegistroListTileState extends State<_RegistroListTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onEdit,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _pressed
                  ? widget.accentColor.withOpacity(0.26)
                  : const Color(0xFFF0F2F6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_pressed ? 0.03 : 0.025),
                blurRadius: _pressed ? 10 : 18,
                offset: Offset(0, _pressed ? 5 : 9),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: widget.accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF667085),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.trailing,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF344054),
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.edit, color: widget.accentColor, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProveedorForm extends StatefulWidget {
  const _ProveedorForm({
    required this.proveedor,
    required this.onBack,
    required this.onSaved,
  });

  final ProveedorRegistroModel? proveedor;
  final VoidCallback onBack;
  final VoidCallback onSaved;

  @override
  State<_ProveedorForm> createState() => _ProveedorFormState();
}

class _ProveedorFormState extends State<_ProveedorForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _rut;
  late final TextEditingController _telefono;
  late final TextEditingController _correo;
  late final TextEditingController _direccion;
  String _estado = 'ACTIVO';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final proveedor = widget.proveedor;
    _nombre = TextEditingController(text: proveedor?.nombre ?? '');
    _rut = TextEditingController(text: proveedor?.rut ?? '');
    _telefono = TextEditingController(text: proveedor?.telefono ?? '');
    _correo = TextEditingController(text: proveedor?.correo ?? '');
    _direccion = TextEditingController(text: proveedor?.direccion ?? '');
    _estado = proveedor?.estado ?? 'ACTIVO';
  }

  @override
  void dispose() {
    _nombre.dispose();
    _rut.dispose();
    _telefono.dispose();
    _correo.dispose();
    _direccion.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final proveedor = ProveedorRegistroModel(
      idProveedor: widget.proveedor?.idProveedor,
      nombre: _nombre.text.trim(),
      rut: _rut.text.trim(),
      direccion: _direccion.text.trim(),
      telefono: _telefono.text.trim(),
      correo: _correo.text.trim(),
      estado: _estado,
    );
    final response = await ApiService().guardarProveedor(proveedor);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (!response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? 'No se pudo guardar')),
      );
      return;
    }
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return _RegistroFormShell(
      title: widget.proveedor == null ? 'Registrar Proveedor' : 'Editar Proveedor',
      onBack: widget.onBack,
      saving: _saving,
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _RegistroTextField(controller: _nombre, label: 'Nombre del proveedor'),
            _RegistroTextField(controller: _rut, label: 'RUC / RUT'),
            _RegistroTextField(controller: _telefono, label: 'Telefono'),
            _RegistroTextField(controller: _correo, label: 'Correo electronico'),
            _RegistroTextField(controller: _direccion, label: 'Direccion'),
            _EstadoDropdown(value: _estado, onChanged: (v) => setState(() => _estado = v)),
          ],
        ),
      ),
    );
  }
}

class _ProductoForm extends StatefulWidget {
  const _ProductoForm({
    required this.producto,
    required this.onBack,
    required this.onSaved,
  });

  final ProductoRegistroModel? producto;
  final VoidCallback onBack;
  final VoidCallback onSaved;

  @override
  State<_ProductoForm> createState() => _ProductoFormState();
}

class _ProductoFormState extends State<_ProductoForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _codigo;
  late final TextEditingController _precio;
  late final TextEditingController _descripcion;
  String _estado = 'ACTIVO';
  int? _idCategoria;
  late Future<List<CategoriaRegistroModel>> _categoriasFuture;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final producto = widget.producto;
    _nombre = TextEditingController(text: producto?.nombre ?? '');
    _codigo = TextEditingController(text: producto?.codigo ?? '');
    _precio = TextEditingController(
      text: producto == null ? '' : producto.precio.toStringAsFixed(2),
    );
    _descripcion = TextEditingController(text: producto?.descripcion ?? '');
    _estado = producto?.estado ?? 'ACTIVO';
    _idCategoria = producto?.idCategoria == 0 ? null : producto?.idCategoria;
    _categoriasFuture = _loadCategorias();
  }

  Future<List<CategoriaRegistroModel>> _loadCategorias() async {
    final response = await ApiService().getCategoriasRegistro();
    if (!response.success) {
      throw Exception(response.message ?? 'No se pudieron cargar categorias');
    }
    return response.data ?? const [];
  }

  @override
  void dispose() {
    _nombre.dispose();
    _codigo.dispose();
    _precio.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _idCategoria == null) {
      return;
    }
    setState(() => _saving = true);
    final producto = ProductoRegistroModel(
      idProducto: widget.producto?.idProducto,
      nombre: _nombre.text.trim(),
      codigo: _codigo.text.trim(),
      descripcion: _descripcion.text.trim(),
      precio: double.tryParse(_precio.text.trim()) ?? 0,
      estado: _estado,
      idCategoria: _idCategoria!,
    );
    final response = await ApiService().guardarProducto(producto);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (!response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? 'No se pudo guardar')),
      );
      return;
    }

    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return _RegistroFormShell(
      title: widget.producto == null ? 'Registrar Producto' : 'Editar Producto',
      onBack: widget.onBack,
      saving: _saving,
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _RegistroTextField(controller: _nombre, label: 'Nombre'),
            _RegistroTextField(controller: _codigo, label: 'Codigo'),
            FutureBuilder<List<CategoriaRegistroModel>>(
              future: _categoriasFuture,
              builder: (context, snapshot) {
                final categorias = _uniqueCategorias(snapshot.data ?? const []);
                final selectedCategory = categorias.any(
                  (categoria) => categoria.idCategoria == _idCategoria,
                )
                    ? _idCategoria
                    : null;
                if (_idCategoria != null && selectedCategory == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _idCategoria = null);
                    }
                  });
                }
                return DropdownButtonFormField<int>(
                  value: selectedCategory,
                  decoration: _inputDecoration('Categoria'),
                  items: [
                    for (final categoria in categorias)
                      DropdownMenuItem(
                        value: categoria.idCategoria,
                        child: Text(categoria.nombre),
                      ),
                  ],
                  onChanged: (value) => setState(() => _idCategoria = value),
                  validator: (value) => value == null ? 'Selecciona categoria' : null,
                );
              },
            ),
            const SizedBox(height: 14),
            _RegistroTextField(controller: _precio, label: 'Precio'),
            _RegistroTextField(
              controller: _descripcion,
              label: 'Descripcion',
              maxLines: 4,
              required: false,
            ),
            _EstadoDropdown(value: _estado, onChanged: (v) => setState(() => _estado = v)),
            if (widget.producto != null) ...[
              const SizedBox(height: 12),
              _InfoPanel(
                icon: Icons.inventory,
                title: 'Stock actual',
                message: '${widget.producto!.stock} unidades disponibles',
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<CategoriaRegistroModel> _uniqueCategorias(
    List<CategoriaRegistroModel> categorias,
  ) {
    final seen = <int>{};
    return [
      for (final categoria in categorias)
        if (seen.add(categoria.idCategoria)) categoria,
    ];
  }
}

class _RegistroFormShell extends StatelessWidget {
  const _RegistroFormShell({
    required this.title,
    required this.onBack,
    required this.saving,
    required this.onSave,
    required this.child,
  });

  final String title;
  final VoidCallback onBack;
  final bool saving;
  final VoidCallback onSave;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        Row(
          children: [
            IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 14 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE7EAF0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.035),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: child,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: saving ? null : onBack,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: saving ? null : onSave,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RegistroTextField extends StatelessWidget {
  const _RegistroTextField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.required = true,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: _inputDecoration(label),
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return 'Campo requerido';
          }
          return null;
        },
      ),
    );
  }
}

class _EstadoDropdown extends StatelessWidget {
  const _EstadoDropdown({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedValue = value == 'ACTIVO' || value == 'INACTIVO'
        ? value
        : 'ACTIVO';
    return DropdownButtonFormField<String>(
      value: selectedValue,
      decoration: _inputDecoration('Estado'),
      items: const [
        DropdownMenuItem(value: 'ACTIVO', child: Text('Activo')),
        DropdownMenuItem(value: 'INACTIVO', child: Text('Inactivo')),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE7EAF0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE7EAF0)),
    ),
  );
}

class _PerfilSection extends StatelessWidget {
  const _PerfilSection({
    required this.nombre,
    required this.username,
    required this.rol,
  });

  final String? nombre;
  final String? username;
  final String? rol;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        _InfoPanel(
          icon: Icons.person,
          title: nombre ?? username ?? 'Perfil',
          message: rol ?? 'Administrador',
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D2939).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEAF3FF),
            child: Icon(icon, color: const Color(0xFF1769AA)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF667085),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReporteCard extends StatefulWidget {
  const _ReporteCard({
    required this.reporte,
    required this.index,
  });

  final ReporteModel reporte;
  final int index;

  @override
  State<_ReporteCard> createState() => _ReporteCardState();
}

class _ReporteCardState extends State<_ReporteCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF00897B),
      const Color(0xFF3F7DF6),
      const Color(0xFF7B61FF),
      const Color(0xFF00A896),
      const Color(0xFFEF6C00),
    ];
    final color = colors[widget.index % colors.length];
    final title = _displayTitle(widget.reporte.titulo);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 520 + (widget.index * 90)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapCancel: () => setState(() => _isPressed = false),
        onTapUp: (_) => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isPressed ? color.withOpacity(0.45) : Colors.white,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(_isPressed ? 0.18 : 0.08),
                  blurRadius: _isPressed ? 28 : 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: _isPressed ? 52 : 46,
                      height: _isPressed ? 52 : 46,
                      decoration: BoxDecoration(
                        color: color.withOpacity(_isPressed ? 0.18 : 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _iconForTitle(title),
                        color: color,
                        size: _isPressed ? 28 : 25,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    right: 48,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF667085),
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 18),
                        _AnimatedReporteValue(value: widget.reporte.valor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _displayTitle(String title) {
    if (title.toLowerCase().contains('usuario')) {
      return 'Clientes';
    }
    return title;
  }

  IconData _iconForTitle(String title) {
    final normalized = title.toLowerCase();
    if (normalized.contains('usuario') || normalized.contains('cliente')) {
      return Icons.groups_2_outlined;
    }
    if (normalized.contains('producto')) {
      return Icons.inventory_2_outlined;
    }
    if (normalized.contains('venta')) {
      return Icons.attach_money;
    }
    if (normalized.contains('pedido')) {
      return Icons.shopping_bag_outlined;
    }
    return Icons.bar_chart;
  }
}

class _AnimatedReporteValue extends StatelessWidget {
  const _AnimatedReporteValue({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final numericValue = double.tryParse(value.replaceAll(',', ''));
    if (numericValue == null) {
      return _valueText(context, value);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: numericValue),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return _valueText(context, _formatValue(animatedValue, value));
      },
    );
  }

  Widget _valueText(BuildContext context, String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF101828),
            height: 1,
          ),
    );
  }

  String _formatValue(double animatedValue, String original) {
    if (original.contains('.')) {
      return animatedValue.toStringAsFixed(1);
    }
    return animatedValue.round().toString();
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
