import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/peticion.dart';
import '../models/usuario.dart';
import '../providers/app_provider.dart';
import 'reportar_screen.dart';

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

  Future<void> _contactarPorWhatsApp(
    BuildContext context,
    Usuario usuario,
  ) async {
    await context.read<AppProvider>().seleccionarTrabajador(
      widget.peticion.id,
      usuario.id,
    );
    if (!context.mounted) return;

    final numero = usuario.celular.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/57$numero');

    final abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!abierto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir WhatsApp en este dispositivo'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final actualizada = provider.peticiones.firstWhere(
      (p) => p.id == widget.peticion.id,
      orElse: () => widget.peticion,
    );

    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Interesados')),
      body: actualizada.interesados.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 56,
                    color: tema.dividerColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nadie ha marcado interés todavía',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: tema.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Te avisaremos apenas alguien aplique',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: actualizada.interesados.length,
              itemBuilder: (context, i) {
                final usuario = actualizada.interesados[i];
                final seleccionado =
                    actualizada.trabajadorSeleccionadoId == usuario.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tema.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: seleccionado
                          ? AppColors.azulCeleste
                          : tema.dividerColor,
                      width: seleccionado ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: seleccionado
                            ? AppColors.azulCeleste.withValues(alpha: 0.14)
                            : Colors.black.withValues(
                                alpha: tema.brightness == Brightness.dark
                                    ? 0.2
                                    : 0.04,
                              ),
                        blurRadius: seleccionado ? 12 : 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              usuario.nombre,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: tema.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReportarScreen(
                                  tipo: 'usuario',
                                  contraId: usuario.id,
                                ),
                              ),
                            ),
                            child: Icon(
                              Icons.flag_outlined,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                      if (usuario.oficios.isNotEmpty)
                        Text(
                          usuario.oficios.join(', '),
                          style: TextStyle(
                            fontSize: 12,
                            color: tema.textTheme.bodySmall?.color,
                          ),
                        ),
                      const SizedBox(height: 6),
                      if (usuario.numeroCalificaciones > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: AppColors.doradoCalificacion,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${usuario.calificacionPromedio.toStringAsFixed(1)} (${usuario.numeroCalificaciones})',
                              style: TextStyle(
                                fontSize: 12,
                                color: tema.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
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
                                size: 12,
                                color: AppColors.azulCeleste,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Nuevo en la plataforma',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.azulCeleste,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _contactarPorWhatsApp(context, usuario),
                          icon: const Icon(Icons.chat, size: 18),
                          label: Text(
                            seleccionado
                                ? 'Contactar de nuevo por WhatsApp'
                                : 'Seleccionar y contactar por WhatsApp',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.azulCeleste,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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
