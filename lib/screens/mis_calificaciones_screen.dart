import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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
        : provider.calificaciones
              .where((c) => c.paraUsuarioId == usuario.id)
              .toList()
              .reversed
              .toList();

    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis calificaciones')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: (usuario != null && usuario.numeroCalificaciones > 0)
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppColors.doradoCalificacion,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${usuario.calificacionPromedio.toStringAsFixed(1)} promedio · ${usuario.numeroCalificaciones} calificaciones',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: tema.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2EC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: AppColors.azulCeleste,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Nuevo en la plataforma',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.azulCeleste,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          Expanded(
            child: calificaciones.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_border_rounded,
                          size: 56,
                          color: tema.dividerColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Todavía nadie te ha calificado',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: tema.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: calificaciones.length,
                    itemBuilder: (context, i) {
                      final c = calificaciones[i];
                      String nombreAutor;
                      try {
                        nombreAutor = provider.todosLosUsuarios
                            .firstWhere((u) => u.id == c.deUsuarioId)
                            .nombre;
                      } catch (_) {
                        nombreAutor = 'Usuario eliminado';
                      }
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
                              children: List.generate(
                                5,
                                (i2) => Icon(
                                  i2 < c.estrellas
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 18,
                                  color: AppColors.doradoCalificacion,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '— $nombreAutor',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.azulCeleste,
                              ),
                            ),
                            if (c.comentario != null &&
                                c.comentario!.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                c.comentario!,
                                style: const TextStyle(fontSize: 13),
                              ),
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
