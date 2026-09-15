import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reporte.dart';
import '../providers/app_provider.dart';

const _ladrillo = Color(0xFFB54834);

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
      // El botón de entrada ya está oculto para no-admins en PerfilScreen,
      // pero eso es solo una conveniencia de UI — esta pantalla debe
      // rechazar el acceso por sí misma (ej. si alguien llega aquí por otra
      // vía) en vez de depender únicamente de que el botón esté escondido.
      if (!context.read<AppProvider>().esAdmin) {
        Navigator.of(context).pop();
        return;
      }
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
        return Text(
          '$prefijo$texto',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        );
      },
    );
  }

  Widget _descripcionDeReportado(AppProvider provider, Reporte r) {
    if (r.tipo == 'usuario') {
      return _nombreAsync(provider, 'Contra: ', r.contraId);
    }
    String descripcion;
    try {
      final peticion = provider.peticiones.firstWhere(
        (p) => p.id == r.contraId,
      );
      descripcion = '"${peticion.descripcion}"';
    } catch (_) {
      descripcion = 'Publicación eliminada';
    }
    return Text(
      'Contra: $descripcion',
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).textTheme.bodySmall?.color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final reportes = [...provider.reportes]
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Administración — Reportes')),
      body: reportes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 56,
                      color: tema.dividerColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay reportes registrados todavía',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: tema.textTheme.bodySmall?.color,
                      ),
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
                    color: tema.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tema.dividerColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: tema.brightness == Brightness.dark
                              ? 0.2
                              : 0.04,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _ladrillo.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              r.tipo == 'usuario' ? 'USUARIO' : 'PUBLICACIÓN',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _ladrillo,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _tiempoTranscurrido(r.fecha),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Motivo: ${r.motivo}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: tema.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _descripcionDeReportado(provider, r),
                      _nombreAsync(provider, 'Reportado por: ', r.deUsuarioId),
                      if (r.comentario != null &&
                          r.comentario!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          r.comentario!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
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
}
