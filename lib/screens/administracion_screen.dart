import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reporte.dart';
import '../providers/app_provider.dart';

const _ladrillo = Color(0xFFB54834);
const _papel = Color(0xFFF9F9FB);
const _grafito = Color(0xFF1A1A1A);

class AdministracionScreen extends StatefulWidget {
  const AdministracionScreen({super.key});

  @override
  State<AdministracionScreen> createState() => _AdministracionScreenState();
}

class _AdministracionScreenState extends State<AdministracionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppProvider>().cargarReportes();
    });
  }

  String _tiempoTranscurrido(DateTime fecha) {
    final diff = DateTime.now().difference(fecha);
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }

  Widget _nombreAsync(AppProvider provider, String prefijo, String usuarioId) {
    return FutureBuilder<String>(
      future: provider.nombreDeUsuario(usuarioId),
      builder: (context, snapshot) {
        final texto = snapshot.connectionState == ConnectionState.waiting
            ? 'Cargando...'
            : (snapshot.data ?? 'Usuario eliminado');
        return Text('$prefijo$texto', style: TextStyle(fontSize: 13, color: Color(0xFF666666)));
      },
    );
  }

  Widget _descripcionDeReportado(AppProvider provider, Reporte r) {
    if (r.tipo == 'usuario') return _nombreAsync(provider, 'Contra: ', r.contraId);
    String descripcion;
    try {
      final peticion = provider.peticiones.firstWhere((p) => p.id == r.contraId);
      descripcion = '"${peticion.descripcion}"';
    } catch (_) {
      descripcion = 'Publicación eliminada';
    }
    return Text('Contra: $descripcion', style: TextStyle(fontSize: 13, color: Color(0xFF666666)));
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'No hay reportes registrados todavía',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF666666)),
                    ),
                  ],
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
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
                    ],
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
                      _descripcionDeReportado(provider, r),
                      _nombreAsync(provider, 'Reportado por: ', r.deUsuarioId),
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
