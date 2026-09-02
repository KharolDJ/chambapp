import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/premium_trabajador.dart';
import '../providers/app_provider.dart';

class PremiumTrabajadorScreen extends StatelessWidget {
  const PremiumTrabajadorScreen({super.key});

  void _abrirSolicitud(BuildContext context, String oficio) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Visibilidad Premium — $oficio',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Destaca tu perfil en el Podio de Recomendados de $oficio por 30 días — \$10.000',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Referencia del comprobante de pago',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingresa la referencia del comprobante')),
                  );
                  return;
                }
                final navigator = Navigator.of(context);
                final mensajero = ScaffoldMessenger.of(context);
                final error = await context.read<AppProvider>().solicitarPremiumTrabajador(
                      oficio: oficio,
                      comprobante: controller.text.trim(),
                    );
                navigator.pop();
                if (error != null) {
                  mensajero.showSnackBar(SnackBar(content: Text(error)));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F6E56),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Solicitar Visibilidad Premium', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final usuario = provider.usuarioActual;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        title: const Text('Visibilidad Premium'),
        backgroundColor: const Color(0xFFFAF7F0),
        foregroundColor: const Color(0xFF26312D),
        elevation: 0,
      ),
      body: (usuario == null || usuario.oficios.isEmpty)
          ? Center(
              child: Text(
                'Agrega al menos un oficio en tu perfil para poder destacarte.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: usuario.oficios.length,
              itemBuilder: (context, i) {
                final oficio = usuario.oficios[i];
                PremiumTrabajador? vigente;
                for (final p in provider.premiumTrabajadores) {
                  if (p.usuarioId == usuario.id && p.oficio == oficio && (p.activo || (p.solicitada && !p.aprobada))) {
                    vigente = p;
                    break;
                  }
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(oficio, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 10),
                      if (vigente != null && vigente.activo) ...[
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF0F6E56), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Activa hasta ${_formatearFecha(vigente.expiraEn!)}',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF0F6E56)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.read<AppProvider>().irAlPodioDe(oficio);
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                            icon: const Icon(Icons.visibility_outlined, size: 16),
                            label: const Text('Ver mi podio'),
                          ),
                        ),
                      ] else if (vigente != null && vigente.solicitada && !vigente.aprobada) ...[
                        Row(
                          children: [
                            const Icon(Icons.hourglass_top, color: Color(0xFFAD7A16), size: 18),
                            const SizedBox(width: 6),
                            const Expanded(child: Text('Tu solicitud está en revisión', style: TextStyle(fontSize: 13))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => context.read<AppProvider>().aprobarPremiumTrabajadorDemo(vigente!.id),
                          child: const Text('Simular aprobación (demo)'),
                        ),
                      ] else if (provider.podioLleno(oficio)) ...[
                        Row(
                          children: [
                            Icon(Icons.block, size: 18, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Los 3 cupos de "$oficio" están ocupados. Vuelve a intentar cuando se libere uno.',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _abrirSolicitud(context, oficio),
                            icon: const Icon(Icons.star_outline, size: 16),
                            label: const Text('Solicitar Visibilidad Premium (\$10.000)'),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _formatearFecha(DateTime fecha) => '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
}
