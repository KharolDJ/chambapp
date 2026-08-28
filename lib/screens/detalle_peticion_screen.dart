import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/peticion.dart';
import '../providers/app_provider.dart';
import 'login_screen.dart';
import 'reportar_screen.dart';

class DetallePeticionScreen extends StatelessWidget {
  final Peticion peticion;
  final double? distanciaKm;

  const DetallePeticionScreen({super.key, required this.peticion, this.distanciaKm});

  String _tiempoTranscurrido() {
    final diff = DateTime.now().difference(peticion.creadaEn);
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }

  String? _textoDistancia() {
    if (distanciaKm == null) return null;
    if (distanciaKm! < 1) return 'cerca de ti';
    return 'a ~${distanciaKm!.toStringAsFixed(1)} km';
  }

  Future<void> _tocarAplicar(BuildContext context) async {
    final provider = context.read<AppProvider>();

    if (provider.usuarioActual == null) {
      final autenticado = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (autenticado != true) return;
      if (!context.mounted) return;
    }

    final providerActualizado = context.read<AppProvider>();
    final yaEstaba = peticion.interesados.any((u) => u.id == providerActualizado.usuarioActual!.id);
    providerActualizado.marcarInteres(peticion.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          yaEstaba
              ? 'Quitaste tu interés en esta petición'
              : 'Marcaste interés — si el empleador te selecciona, te va a escribir por WhatsApp',
        ),
        backgroundColor: yaEstaba ? Colors.grey.shade700 : const Color(0xFF0F6E56),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final esTrabajador = provider.rolActual == RolUsuario.trabajador;
    final yaAplico = provider.usuarioActual != null &&
        peticion.interesados.any((u) => u.id == provider.usuarioActual!.id);
    final fuiSeleccionado =
        provider.usuarioActual != null && peticion.trabajadorSeleccionadoId == provider.usuarioActual!.id;
    final distanciaTexto = _textoDistancia();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        title: const Text('Detalle de la petición'),
        backgroundColor: const Color(0xFFFAF7F0),
        foregroundColor: const Color(0xFF26312D),
        elevation: 0,
        actions: [
          if (provider.usuarioActual != null)
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              tooltip: 'Reportar publicación',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReportarScreen(tipo: 'peticion', contraId: peticion.id)),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFFAEEDA),
                    child: Text(
                      peticion.autorNombre[0],
                      style: const TextStyle(color: Color(0xFFAD7A16), fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(peticion.autorNombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        Text(
                          [peticion.barrio, ?distanciaTexto, _tiempoTranscurrido()].join(' · '),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (peticion.urgente) ...[
                    _Etiqueta(texto: 'Urgente', color: const Color(0xFFB54834)),
                    const SizedBox(width: 6),
                  ],
                  _Etiqueta(texto: peticion.categoria, color: const Color(0xFF0F6E56)),
                ],
              ),
              const SizedBox(height: 16),
              if (peticion.fotoUrl != null)
                Container(
                  height: 180,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: Image.file(
                    File(peticion.fotoUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 40),
                  ),
                ),
              Text(
                peticion.descripcion,
                style: const TextStyle(fontSize: 15, height: 1.4, color: Color(0xFF26312D)),
              ),
              const SizedBox(height: 32),
              if (esTrabajador)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: fuiSeleccionado ? null : () => _tocarAplicar(context),
                    icon: Icon(
                      fuiSeleccionado
                          ? Icons.verified
                          : (yaAplico ? Icons.check_circle : Icons.send_outlined),
                    ),
                    label: Text(
                      fuiSeleccionado
                          ? '¡Fuiste seleccionado para este trabajo!'
                          : (yaAplico ? 'Ya aplicaste — toca para quitar tu interés' : 'Aplicar'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: fuiSeleccionado
                          ? const Color(0xFF0F6E56)
                          : (yaAplico ? Colors.grey.shade300 : const Color(0xFF0F6E56)),
                      foregroundColor: yaAplico && !fuiSeleccionado ? const Color(0xFF26312D) : Colors.white,
                      disabledBackgroundColor: const Color(0xFF0F6E56),
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;
  final Color color;
  const _Etiqueta({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(texto, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
