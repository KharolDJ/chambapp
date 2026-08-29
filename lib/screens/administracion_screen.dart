import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reporte.dart';
import '../providers/app_provider.dart';

const _ladrillo = Color(0xFFB54834);
const _papel = Color(0xFFFAF7F0);
const _grafito = Color(0xFF26312D);

class AdministracionScreen extends StatelessWidget {
  const AdministracionScreen({super.key});

  String _tiempoTranscurrido(DateTime fecha) {
    final diff = DateTime.now().difference(fecha);
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }

  String _nombreDe(AppProvider provider, String usuarioId) {
    try {
      return provider.usuarios.firstWhere((u) => u.id == usuarioId).nombre;
    } catch (_) {
      return 'Usuario eliminado';
    }
  }

  String _descripcionDeReportado(AppProvider provider, Reporte r) {
    if (r.tipo == 'usuario') return _nombreDe(provider, r.contraId);
    try {
      final peticion = provider.peticiones.firstWhere((p) => p.id == r.contraId);
      return '"${peticion.descripcion}"';
    } catch (_) {
      return 'Publicación eliminada';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final reportes = [...provider.reportes]..sort((a, b) => b.fecha.compareTo(a.fecha));

    return Scaffold(
      backgroundColor: _papel,
      appBar: AppBar(
        title: const Text('Administración — Reportes'),
        backgroundColor: _papel,
        foregroundColor: _grafito,
        elevation: 0,
      ),
      body: reportes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'No hay reportes registrados en este dispositivo todavía.\n\n'
                  'Nota: hasta que conectemos Firebase, cada celular solo ve los '
                  'reportes hechos desde ese mismo celular.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reportes.length,
              itemBuilder: (context, i) {
                final r = reportes[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _ladrillo.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              r.tipo == 'usuario' ? 'USUARIO' : 'PUBLICACIÓN',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _ladrillo),
                            ),
                          ),
                          const Spacer(),
                          Text(_tiempoTranscurrido(r.fecha), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Motivo: ${r.motivo}',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: _grafito),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Contra: ${_descripcionDeReportado(provider, r)}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                      Text(
                        'Reportado por: ${_nombreDe(provider, r.deUsuarioId)}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                      if (r.comentario != null && r.comentario!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(r.comentario!, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}
