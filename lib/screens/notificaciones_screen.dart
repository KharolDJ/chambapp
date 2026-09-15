import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/notificacion.dart';
import '../models/peticion.dart';
import '../providers/app_provider.dart';
import 'detalle_peticion_screen.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  Set<String> _idsNoLeidasAlAbrir = {};

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _idsNoLeidasAlAbrir = provider.misNotificaciones
        .where((n) => !n.leida)
        .map((n) => n.id)
        .toSet();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppProvider>().marcarTodasNotificacionesLeidas();
    });
  }

  String _tiempoTranscurrido(DateTime fecha) {
    final diff = DateTime.now().difference(fecha);
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }

  String _formatearFecha(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

  void _tocarNotificacion(BuildContext context, Notificacion n) {
    if (n.peticionId == null) return;
    final provider = context.read<AppProvider>();
    Peticion? peticion;
    try {
      peticion = provider.peticiones.firstWhere((p) => p.id == n.peticionId);
    } catch (_) {
      peticion = null;
    }
    if (peticion == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetallePeticionScreen(peticion: peticion!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final lista = provider.misNotificaciones;
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: lista.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: 0.35,
                    child: Image.asset(
                      'assets/icon/notificacion.png',
                      width: 56,
                      height: 56,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes notificaciones todavía',
                    style: TextStyle(color: tema.textTheme.bodySmall?.color),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lista.length,
              itemBuilder: (context, i) {
                final n = lista[i];
                final eraNoLeida = _idsNoLeidasAlAbrir.contains(n.id);
                return InkWell(
                  onTap: () => _tocarNotificacion(context, n),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (eraNoLeida)
                          Padding(
                            padding: const EdgeInsets.only(top: 5, right: 8),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFB54834),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.mensaje,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: tema.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_tiempoTranscurrido(n.fecha)} · ${_formatearFecha(n.fecha)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: tema.textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 18,
                            color: tema.textTheme.bodySmall?.color,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Eliminar notificación',
                          onPressed: () => context
                              .read<AppProvider>()
                              .eliminarNotificacion(n.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
