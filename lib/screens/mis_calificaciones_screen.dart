import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class MisCalificacionesScreen extends StatelessWidget {
  const MisCalificacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final usuario = provider.usuarioActual;
    final calificaciones = usuario == null
        ? const []
        : provider.calificaciones.where((c) => c.paraUsuarioId == usuario.id).toList().reversed.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        title: const Text('Mis calificaciones'),
        backgroundColor: const Color(0xFFFAF7F0),
        foregroundColor: const Color(0xFF26312D),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: (usuario != null && usuario.numeroCalificaciones > 0)
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Color(0xFFAD7A16), size: 22),
                      const SizedBox(width: 6),
                      Text(
                        '${usuario.calificacionPromedio.toStringAsFixed(1)} promedio · ${usuario.numeroCalificaciones} calificaciones',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF26312D)),
                      ),
                    ],
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration:
                        BoxDecoration(color: const Color(0xFFFAEEDA), borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 16, color: Color(0xFFAD7A16)),
                        SizedBox(width: 6),
                        Text(
                          'Nuevo en la plataforma',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFAD7A16)),
                        ),
                      ],
                    ),
                  ),
          ),
          Expanded(
            child: calificaciones.isEmpty
                ? Center(
                    child: Text(
                      'Todavía nadie te ha calificado',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: calificaciones.length,
                    itemBuilder: (context, i) {
                      final c = calificaciones[i];
                      String nombreAutor;
                      try {
                        nombreAutor = provider.usuarios.firstWhere((u) => u.id == c.deUsuarioId).nombre;
                      } catch (_) {
                        nombreAutor = 'Usuario eliminado';
                      }
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
                              children: List.generate(
                                5,
                                (i2) => Icon(
                                  i2 < c.estrellas ? Icons.star : Icons.star_border,
                                  size: 18,
                                  color: const Color(0xFFAD7A16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '— $nombreAutor',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F6E56)),
                            ),
                            if (c.comentario != null && c.comentario!.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(c.comentario!, style: const TextStyle(fontSize: 13)),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
