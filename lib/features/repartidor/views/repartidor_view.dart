import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../widgets/logout_modal.dart';
import '../models/pedido_repartidor_model.dart';
import '../providers/repartidor_provider.dart';
import '../widgets/mapa_ruta_widget.dart';
import '../widgets/pedido_card.dart';
import 'firma_screen.dart';
import 'qr_scanner_screen.dart';

class RepartidorView extends StatefulWidget {
  const RepartidorView({super.key});

  @override
  State<RepartidorView> createState() => _RepartidorViewState();
}

class _RepartidorViewState extends State<RepartidorView> {
  int _selectedIndex = 0;
  late RepartidorProvider _provider;

  static const List<String> _titles = ['Mis Pedidos', 'Mapa', 'Mi Perfil'];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _provider = RepartidorProvider(
      authToken: auth.token,
      sessionCookie: auth.sessionCookie,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([_provider.cargarPerfil(), _provider.cargarPedidos()]);
      await _provider.iniciarTracking();
    });
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() => _selectedIndex = index);
    if (index == 1 && _provider.pedidoSeleccionado != null && _provider.rutaPuntos.isEmpty) {
      _provider.cargarRuta();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF4F6FA),
          elevation: 0,
          title: Text(_titles[_selectedIndex], style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF101828))),
          actions: [
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: () => showLogoutModal(context),
              icon: const Icon(Icons.logout, color: Color(0xFF101828)),
            ),
          ],
        ),
        body: Consumer<RepartidorProvider>(
          builder: (context, provider, _) {
            return IndexedStack(
              index: _selectedIndex,
              children: [
                _PedidosTab(provider: provider, onVerMapa: (pedido) {
                  provider.seleccionarPedido(pedido);
                  _onTabChanged(1);
                }),
                _MapaTab(provider: provider),
                _PerfilTab(provider: provider),
              ],
            );
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTabChanged,
          selectedItemColor: const Color(0xFF2F6FED),
          unselectedItemColor: const Color(0xFF7A8494),
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: 'Pedidos'),
            BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Mapa'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Pedidos ────────────────────────────────────────────────────────────

class _PedidosTab extends StatelessWidget {
  const _PedidosTab({required this.provider, required this.onVerMapa});
  final RepartidorProvider provider;
  final void Function(PedidoRepartidorModel) onVerMapa;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Botón escanear QR
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _escanearQr(context),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Escanear pedido', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F6FED),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        // Lista de pedidos
        Expanded(
          child: _buildLista(context),
        ),
      ],
    );
  }

  Future<void> _escanearQr(BuildContext context) async {
    final idPedido = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (idPedido == null || !context.mounted) return;

    final ok = await provider.tomarPedido(idPedido);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Pedido #$idPedido asignado correctamente' : 'No se pudo asignar el pedido'),
      backgroundColor: ok ? const Color(0xFF30B566) : const Color(0xFFE5484D),
    ));
  }

  Widget _buildLista(BuildContext context) {
    if (provider.cargandoPedidos) return const Center(child: CircularProgressIndicator());
    if (provider.error != null) {
      return Center(child: Text(provider.error!, style: const TextStyle(color: Color(0xFFE5484D))));
    }
    if (provider.pedidos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Color(0xFF7A8494)),
            SizedBox(height: 12),
            Text('No tienes pedidos asignados', style: TextStyle(color: Color(0xFF667085), fontSize: 15)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: provider.cargarPedidos,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: provider.pedidos.length,
        itemBuilder: (_, i) {
          final pedido = provider.pedidos[i];
          return PedidoCard(
            pedido: pedido,
            onVerMapa: () => onVerMapa(pedido),
            onCambiarEstado: () => _mostrarCambioEstado(context, pedido),
          );
        },
      ),
    );
  }

  Future<void> _mostrarCambioEstado(BuildContext context, PedidoRepartidorModel pedido) async {
    final estado = (pedido.estadoEntrega ?? 'PENDIENTE').toUpperCase();

    // Estados finales: no se puede cambiar
    if (estado == 'ENTREGADO' || estado == 'NO_ENTREGADO') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('El pedido ya está $estado'),
        backgroundColor: const Color(0xFF667085),
      ));
      return;
    }

    // Si no tiene entrega creada, crearla primero
    int? idEntrega = pedido.idEntrega;
    if (idEntrega == null) {
      final created = await provider.iniciarEntrega(pedido.idPedido);
      if (!context.mounted) return;
      if (created == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo iniciar la entrega'),
          backgroundColor: Color(0xFFE5484D),
        ));
        return;
      }
      idEntrega = created;
    }

    // Flujo según estado actual
    if (estado == 'PENDIENTE') {
      await _confirmarAccion(
        context: context,
        titulo: 'Iniciar entrega',
        mensaje: '¿Confirmas que ya recogiste el pedido #${pedido.idPedido} y estás en camino?',
        boton: 'Sí, estoy en camino',
        color: const Color(0xFF2F6FED),
        icono: Icons.local_shipping_outlined,
        onConfirm: () => provider.actualizarEstadoEntrega(idEntrega!, 'EN_CAMINO'),
      );
    } else if (estado == 'EN_CAMINO') {
      await _mostrarOpcionesFinalizacion(context, pedido, idEntrega);
    }
  }

  Future<void> _confirmarAccion({
    required BuildContext context,
    required String titulo,
    required String mensaje,
    required String boton,
    required Color color,
    required IconData icono,
    required Future<String?> Function() onConfirm, // null = éxito, string = mensaje error
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icono, color: color, size: 22),
            const SizedBox(width: 10),
            Text(titulo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(mensaje, style: const TextStyle(color: Color(0xFF667085))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF667085))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(boton, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;
    final errorMsg = await onConfirm();
    if (context.mounted) {
      final exito = errorMsg == null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(exito ? 'Estado actualizado' : errorMsg),
        backgroundColor: exito ? const Color(0xFF30B566) : const Color(0xFFE5484D),
      ));
    }
  }

  Future<void> _mostrarOpcionesFinalizacion(
    BuildContext context,
    PedidoRepartidorModel pedido,
    int idEntrega,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFD0D5DD), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('¿Cómo finalizó la entrega?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF101828))),
            const SizedBox(height: 6),
            Text('Pedido #${pedido.idPedido} · ${pedido.receptor}',
                style: const TextStyle(color: Color(0xFF667085), fontSize: 13)),
            const SizedBox(height: 24),

            // Botón: Entregado (con firma)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  if (!context.mounted) return;
                  final firma = await Navigator.of(context).push<String>(
                    MaterialPageRoute(builder: (_) => const FirmaScreen()),
                  );
                  if (firma == null || !context.mounted) return;
                  final errorMsg = await provider.actualizarEstadoEntrega(
                    idEntrega, 'ENTREGADO', firma: firma,
                  );
                  if (context.mounted) {
                    final exito = errorMsg == null;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(exito ? 'Entrega confirmada con foto' : errorMsg),
                      backgroundColor: exito ? const Color(0xFF30B566) : const Color(0xFFE5484D),
                    ));
                  }
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Entregado — capturar firma del receptor',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF30B566),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Botón: No entregado (con notas)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  if (!context.mounted) return;
                  await _pedirNotasNoEntregado(context, idEntrega);
                },
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('No entregado — agregar motivo',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE5484D),
                  side: const BorderSide(color: Color(0xFFE5484D)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pedirNotasNoEntregado(BuildContext context, int idEntrega) async {
    final notasCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Color(0xFFE5484D), size: 22),
            SizedBox(width: 10),
            Text('No entregado', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: TextField(
          controller: notasCtrl,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Ej: Nadie en casa, dirección incorrecta...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF667085))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5484D),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;
    final errorMsg = await provider.actualizarEstadoEntrega(
      idEntrega, 'NO_ENTREGADO', notas: notasCtrl.text,
    );
    if (context.mounted) {
      final exito = errorMsg == null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(exito ? 'Marcado como no entregado' : errorMsg),
        backgroundColor: exito ? const Color(0xFF667085) : const Color(0xFFE5484D),
      ));
    }
  }
}

// ─── Tab Mapa ───────────────────────────────────────────────────────────────

class _MapaTab extends StatelessWidget {
  const _MapaTab({required this.provider});
  final RepartidorProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.posicionActual == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Obteniendo ubicación...', style: TextStyle(color: Color(0xFF667085))),
          ],
        ),
      );
    }

    final pos = provider.posicionActual!;
    final pedido = provider.pedidoSeleccionado;

    return Column(
      children: [
        if (pedido != null)
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFFE5484D), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pedido #${pedido.idPedido}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(pedido.direccionCompleta, style: const TextStyle(fontSize: 12, color: Color(0xFF667085))),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: provider.cargarRuta,
                  child: const Text('Recalcular'),
                ),
              ],
            ),
          )
        else
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF2F6FED), size: 18),
                SizedBox(width: 8),
                Text('Selecciona un pedido para ver la ruta', style: TextStyle(color: Color(0xFF2F6FED), fontSize: 13)),
              ],
            ),
          ),
        Expanded(
          child: MapaRutaWidget(
            posicionActual: LatLng(pos.latitude, pos.longitude),
            destinoLat: pedido?.latitudEntrega,
            destinoLng: pedido?.longitudEntrega,
            rutaPuntos: provider.rutaPuntos,
            cargando: provider.cargandoRuta,
            instruccionActual: provider.pasoActual?.instruccion,
            heading: provider.heading,
          ),
        ),
      ],
    );
  }
}

// ─── Tab Perfil ─────────────────────────────────────────────────────────────

class _PerfilTab extends StatelessWidget {
  const _PerfilTab({required this.provider});
  final RepartidorProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.cargandoPerfil) return const Center(child: CircularProgressIndicator());
    final p = provider.perfil;
    if (p == null) {
      return const Center(child: Text('No se pudo cargar el perfil', style: TextStyle(color: Color(0xFF667085))));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar y nombre
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12)],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(color: Color(0xFFEAF3FF), shape: BoxShape.circle),
                  child: const Icon(Icons.delivery_dining, color: Color(0xFF2F6FED), size: 40),
                ),
                const SizedBox(height: 12),
                Text(p.nombreCompleto, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF101828))),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.isActivo ? const Color(0xFFD1E7DD) : const Color(0xFFF8D7DA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    p.estado ?? 'INACTIVO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: p.isActivo ? const Color(0xFF0F5132) : const Color(0xFF842029),
                    ),
                  ),
                ),
                if (p.calificacion != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 22),
                      const SizedBox(width: 4),
                      Text(p.calificacion!.toStringAsFixed(1), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const Text(' / 5', style: TextStyle(color: Color(0xFF667085))),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Datos de contacto
          _SeccionPerfil(
            titulo: 'Contacto',
            icon: Icons.contact_phone_outlined,
            items: [
              if (p.correo != null) _ItemPerfil('Correo', p.correo!),
              if (p.telefono != null) _ItemPerfil('Teléfono', p.telefono!),
            ],
          ),
          const SizedBox(height: 12),
          // Datos del vehículo
          _SeccionPerfil(
            titulo: 'Vehículo',
            icon: Icons.two_wheeler_outlined,
            items: [
              if (p.tipoVehiculo != null) _ItemPerfil('Tipo', p.tipoVehiculo!),
              if (p.placaVehiculo != null) _ItemPerfil('Placa', p.placaVehiculo!),
              if (p.licenciaConduccion != null) _ItemPerfil('Licencia', p.licenciaConduccion!),
              if (p.categoriaLicencia != null) _ItemPerfil('Categoría', p.categoriaLicencia!),
            ],
          ),
          const SizedBox(height: 12),
          // Zona asignada
          if (p.zonaAsignada != null)
            _SeccionPerfil(
              titulo: 'Zona asignada',
              icon: Icons.map_outlined,
              items: [_ItemPerfil('Zona', p.zonaAsignada!)],
            ),
        ],
      ),
    );
  }
}

class _SeccionPerfil extends StatelessWidget {
  const _SeccionPerfil({required this.titulo, required this.icon, required this.items});
  final String titulo;
  final IconData icon;
  final List<_ItemPerfil> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF2F6FED)),
              const SizedBox(width: 8),
              Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF101828))),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(item.label, style: const TextStyle(fontSize: 13, color: Color(0xFF667085))),
                    ),
                    Expanded(
                      child: Text(item.valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF101828))),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ItemPerfil {
  const _ItemPerfil(this.label, this.valor);
  final String label;
  final String valor;
}
