import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class FirmaScreen extends StatefulWidget {
  const FirmaScreen({super.key});

  @override
  State<FirmaScreen> createState() => _FirmaScreenState();
}

class _FirmaScreenState extends State<FirmaScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _foto;
  bool _enviando = false;

  Future<void> _capturar(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 60,   // comprime para no enviar MBs por HTTP
      maxWidth: 1200,
      maxHeight: 1600,
    );
    if (picked == null) return;
    setState(() => _foto = File(picked.path));
  }

  Future<void> _confirmar() async {
    if (_foto == null) return;
    setState(() => _enviando = true);
    final bytes = await _foto!.readAsBytes();
    final base64Str = base64Encode(bytes);
    if (mounted) Navigator.of(context).pop(base64Str);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        title: const Text(
          'Foto del documento firmado',
          style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF101828)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF101828)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instrucción
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF2F6FED), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Toma una foto clara del documento de entrega con la firma del receptor. Asegúrate de que sea legible.',
                      style: TextStyle(color: Color(0xFF2F6FED), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Área de previsualización
            Expanded(
              child: _foto == null ? _buildPlaceholder() : _buildPreview(),
            ),
            const SizedBox(height: 20),

            // Botones de captura
            if (_foto == null) ...[
              _BotonFoto(
                icono: Icons.camera_alt_outlined,
                label: 'Tomar foto con la cámara',
                color: const Color(0xFF2F6FED),
                onTap: () => _capturar(ImageSource.camera),
              ),
              const SizedBox(height: 12),
              _BotonFoto(
                icono: Icons.photo_library_outlined,
                label: 'Seleccionar de la galería',
                color: const Color(0xFF667085),
                onTap: () => _capturar(ImageSource.gallery),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _enviando ? null : () => setState(() => _foto = null),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Repetir foto'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF667085),
                        side: const BorderSide(color: Color(0xFFD0D5DD)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _enviando ? null : _confirmar,
                      icon: _enviando
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(
                        _enviando ? 'Procesando...' : 'Confirmar entrega',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF30B566),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFD0D5DD),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD0D5DD), width: 2),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.document_scanner_outlined, size: 72, color: Color(0xFFD0D5DD)),
          SizedBox(height: 16),
          Text(
            'Sin foto todavía',
            style: TextStyle(color: Color(0xFF7A8494), fontSize: 15, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 6),
          Text(
            'Usa los botones de abajo para\ncapturar el documento firmado',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFADB5BD), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            _foto!,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        // Badge de confirmación visual
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF30B566),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('Foto lista', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BotonFoto extends StatelessWidget {
  const _BotonFoto({
    required this.icono,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icono;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icono, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
