import 'package:flutter/material.dart';

import '../models/pedido_repartidor_model.dart';

class PedidoCard extends StatelessWidget {
  const PedidoCard({
    required this.pedido,
    required this.onVerMapa,
    required this.onCambiarEstado,
    super.key,
  });

  final PedidoRepartidorModel pedido;
  final VoidCallback onVerMapa;
  final VoidCallback onCambiarEstado;

  // Estados de ESTADO_PEDIDO (estado oficial del pedido, controlado por admin)
  static const Map<String, _EstadoInfo> _estadosPedido = {
    'PENDIENTE':  _EstadoInfo(Color(0xFFFFF3CD), Color(0xFF856404), Icons.schedule),
    'PROCESADO':  _EstadoInfo(Color(0xFFE8EEFF), Color(0xFF3451B2), Icons.inventory_2),
    'EN CAMINO':  _EstadoInfo(Color(0xFFCFE2FF), Color(0xFF084298), Icons.local_shipping),
    'ENTREGADO':  _EstadoInfo(Color(0xFFD1E7DD), Color(0xFF0F5132), Icons.check_circle),
    'CANCELADO':  _EstadoInfo(Color(0xFFF8D7DA), Color(0xFF842029), Icons.cancel),
  };

  // Estados de ENTREGA_PEDIDO (para lógica de acciones, no para el badge)
  static const Map<String, _EstadoInfo> _estadosEntrega = {
    'PENDIENTE':     _EstadoInfo(Color(0xFFFFF3CD), Color(0xFF856404), Icons.schedule),
    'EN_CAMINO':     _EstadoInfo(Color(0xFFCFE2FF), Color(0xFF084298), Icons.local_shipping),
    'ENTREGADO':     _EstadoInfo(Color(0xFFD1E7DD), Color(0xFF0F5132), Icons.check_circle),
    'NO_ENTREGADO':  _EstadoInfo(Color(0xFFF8D7DA), Color(0xFF842029), Icons.cancel),
  };

  @override
  Widget build(BuildContext context) {
    final estadoBadge = (pedido.estadoEntrega ?? pedido.estadoNombre ?? 'PENDIENTE').toUpperCase();
    final info = _estadosEntrega[estadoBadge]
        ?? _estadosPedido[estadoBadge]
        ?? const _EstadoInfo(Color(0xFFE2E8F0), Color(0xFF475569), Icons.help_outline);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con número de pedido y estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pedido #${pedido.idPedido}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF101828)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: info.bgColor, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(info.icon, size: 12, color: info.textColor),
                      const SizedBox(width: 4),
                      Text(estadoBadge.replaceAll('_', ' '), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: info.textColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Contenido
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(icon: Icons.person_outline, label: 'Receptor', value: pedido.receptor.isNotEmpty ? pedido.receptor : 'N/A'),
                const SizedBox(height: 8),
                _InfoRow(icon: Icons.location_on_outlined, label: 'Dirección', value: pedido.direccionCompleta.isNotEmpty ? pedido.direccionCompleta : 'N/A'),
                if (pedido.telefonoReceptor != null) ...[
                  const SizedBox(height: 8),
                  _InfoRow(icon: Icons.phone_outlined, label: 'Teléfono', value: pedido.telefonoReceptor!),
                ],
                if (pedido.fechaEstimadaEntrega != null) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Fecha estimada',
                    value: _formatFecha(pedido.fechaEstimadaEntrega!),
                  ),
                ],
                if (pedido.total != null) ...[
                  const SizedBox(height: 8),
                  _InfoRow(icon: Icons.attach_money, label: 'Total', value: '\$${pedido.total!.toStringAsFixed(0)}'),
                ],
                if (pedido.informacionAdicional != null) ...[
                  const SizedBox(height: 8),
                  _InfoRow(icon: Icons.info_outline, label: 'Notas', value: pedido.informacionAdicional!),
                ],
              ],
            ),
          ),
          // Botones de acción
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onVerMapa,
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text('Ver ruta'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2F6FED),
                      side: const BorderSide(color: Color(0xFF2F6FED)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onCambiarEstado,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Estado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F6FED),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF667085)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontSize: 13, color: Color(0xFF667085), fontWeight: FontWeight.w500)),
                TextSpan(text: value, style: const TextStyle(fontSize: 13, color: Color(0xFF101828), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EstadoInfo {
  const _EstadoInfo(this.bgColor, this.textColor, this.icon);
  final Color bgColor;
  final Color textColor;
  final IconData icon;
}
