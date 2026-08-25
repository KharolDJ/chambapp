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
    _idsNoLeidasAlAbrir = provider.misNotificaciones.where((n) => !n.leida).map((n) => n.id).toSet();
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
    Navigator.push(context, MaterialPageRoute(builder: (_) => DetallePeticionScreen(peticion: peticion!)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final lista = provider.misNotificaciones;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: const Color(0xFFFAF7F0),
        foregroundColor: const Color(0xFF26312D),
        elevation: 0,
      ),
      body: lista.isEmpty
          ? Center(
              child: Text('No tienes notificaciones todavía', style: TextStyle(color: Colors.grey.shade600)),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (eraNoLeida)
                          const Padding(
                            padding: EdgeInsets.only(top: 4, right: 8),
                            child: CircleAvatar(radius: 4, backgroundColor: Color(0xFF0F6E56)),
                          )
                        else
                          const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.mensaje, style: const TextStyle(fontSize: 14, color: Color(0xFF26312D))),
                              const SizedBox(height: 4),
                              Text(
                                _tiempoTranscurrido(n.fecha),
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Eliminar notificación',
                          onPressed: () => context.read<AppProvider>().eliminarNotificacion(n.id),
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
