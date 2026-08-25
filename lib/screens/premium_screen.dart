import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/peticion.dart';
import '../providers/app_provider.dart';

class PremiumScreen extends StatefulWidget {
  final Peticion peticion;
  const PremiumScreen({super.key, required this.peticion});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final _comprobanteController = TextEditingController();

  @override
  void dispose() {
    _comprobanteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final actualizada = provider.peticiones.firstWhere(
      (p) => p.id == widget.peticion.id,
      orElse: () => widget.peticion,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        title: const Text('Visibilidad Premium'),
        backgroundColor: const Color(0xFFFAF7F0),
        foregroundColor: const Color(0xFF26312D),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAEEDA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFAD7A16), size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Destaca tu publicación por \$10.000 y aparece primero en el feed de tu zona',
                      style: TextStyle(color: Color(0xFFAD7A16), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (actualizada.premiumAprobada) ...[
              const Icon(Icons.check_circle, color: Color(0xFF0F6E56), size: 48),
              const SizedBox(height: 12),
              const Text('¡Tu publicación ya tiene Visibilidad Premium activa!', textAlign: TextAlign.center),
            ] else if (actualizada.premiumSolicitada) ...[
              const Icon(Icons.hourglass_top, color: Color(0xFFAD7A16), size: 48),
              const SizedBox(height: 12),
              const Text('Tu solicitud está en revisión', textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                'Comprobante: ${actualizada.comprobantePago}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => context.read<AppProvider>().aprobarPremiumDemo(actualizada.id),
                child: const Text('Simular aprobación (demo)'),
              ),
            ] else if (actualizada.cerrada) ...[
              Icon(Icons.info_outline, color: Colors.grey.shade500, size: 48),
              const SizedBox(height: 12),
              Text(
                'Esta publicación ya está finalizada, no se puede solicitar Visibilidad Premium',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ] else ...[
              const Text(
                'Referencia del comprobante de pago',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _comprobanteController,
                decoration: InputDecoration(
                  hintText: 'Ej: código de la transferencia',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_comprobanteController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ingresa la referencia del comprobante')),
                    );
                    return;
                  }
                  context
                      .read<AppProvider>()
                      .solicitarPremium(actualizada.id, _comprobanteController.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F6E56),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Solicitar Visibilidad Premium', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
