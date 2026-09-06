import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/peticion.dart';
import '../providers/app_provider.dart';
import '../screens/detalle_peticion_screen.dart';

class PeticionCard extends StatelessWidget {
  final Peticion peticion;
  final double? distanciaKm;

  const PeticionCard({super.key, required this.peticion, this.distanciaKm});

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final yaMeInteresa = provider.usuarioActual != null &&
        peticion.interesados.any((u) => u.id == provider.usuarioActual!.id);
    final esTrabajador = provider.rolActual == RolUsuario.trabajador;
    final distanciaTexto = _textoDistancia();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetallePeticionScreen(peticion: peticion, distanciaKm: distanciaKm),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: peticion.premiumAprobada ? const Color(0xFF0F6E56) : Colors.grey.shade200,
            width: peticion.premiumAprobada ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: peticion.premiumAprobada
                  ? const Color(0xFF0F6E56).withValues(alpha: 0.16)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: peticion.premiumAprobada ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (peticion.premiumAprobada)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F6E56),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'DESTACADO',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.4),
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFE3F2EC),
                  child: Text(
                    peticion.autorNombre[0],
                    style: const TextStyle(color: Color(0xFF0F6E56), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(peticion.autorNombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(
                        [
                          peticion.barrio,
                          ?distanciaTexto,
                          _tiempoTranscurrido(),
                        ].join(' · '),
                        style: TextStyle(fontSize: 11, color: Color(0xFF666666)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (peticion.fotoUrl != null)
              Container(
                height: 100,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                child: Image.file(
                  File(peticion.fotoUrl!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 32),
                ),
              ),
            Text(
              peticion.descripcion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (peticion.urgente) _Etiqueta(texto: 'Urgente', color: const Color(0xFFB54834)),
                if (peticion.urgente) const SizedBox(width: 6),
                Flexible(child: _Etiqueta(texto: peticion.categoria, color: const Color(0xFF0F6E56))),
                const Spacer(),
                Flexible(
                  child: esTrabajador
                      ? (yaMeInteresa
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, size: 16, color: Colors.teal.shade700),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Aplicaste',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: Colors.teal.shade700),
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Toca para ver más',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ))
                      : Text(
                          '${peticion.interesados.length} interesados',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                        ),
                ),
              ],
            ),
          ],
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
