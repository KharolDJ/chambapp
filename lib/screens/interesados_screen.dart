import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/peticion.dart';
import '../models/usuario.dart';
import '../providers/app_provider.dart';

class InteresadosScreen extends StatefulWidget {
  final Peticion peticion;
  const InteresadosScreen({super.key, required this.peticion});

  @override
  State<InteresadosScreen> createState() => _InteresadosScreenState();
}

class _InteresadosScreenState extends State<InteresadosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppProvider>().marcarVistoPorEmpleador(widget.peticion.id);
    });
  }

  Future<void> _contactarPorWhatsApp(BuildContext context, Usuario usuario) async {
    context.read<AppProvider>().seleccionarTrabajador(widget.peticion.id, usuario.id);

    final numero = usuario.celular.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/57$numero');

    final abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!abierto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp en este dispositivo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final actualizada =
        provider.peticiones.firstWhere((p) => p.id == widget.peticion.id, orElse: () => widget.peticion);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        title: const Text('Interesados'),
        backgroundColor: const Color(0xFFFAF7F0),
        foregroundColor: const Color(0xFF26312D),
        elevation: 0,
      ),
      body: actualizada.interesados.isEmpty
          ? Center(
              child: Text('Nadie ha marcado interés todavía', style: TextStyle(color: Colors.grey.shade600)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: actualizada.interesados.length,
              itemBuilder: (context, i) {
                final usuario = actualizada.interesados[i];
                final seleccionado = actualizada.trabajadorSeleccionadoId == usuario.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: seleccionado ? const Color(0xFF0F6E56) : Colors.grey.shade200,
                      width: seleccionado ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(usuario.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      if (usuario.oficios.isNotEmpty)
                        Text(usuario.oficios.join(', '), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Color(0xFFAD7A16)),
                          const SizedBox(width: 4),
                          Text(
                            usuario.numeroCalificaciones > 0
                                ? '${usuario.calificacionPromedio.toStringAsFixed(1)} (${usuario.numeroCalificaciones})'
                                : 'Sin calificaciones aún',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _contactarPorWhatsApp(context, usuario),
                          icon: const Icon(Icons.chat, size: 18),
                          label: Text(seleccionado ? 'Contactar de nuevo por WhatsApp' : 'Seleccionar y contactar por WhatsApp'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F6E56),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
