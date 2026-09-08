import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/peticion.dart';
import '../providers/app_provider.dart';
import '../screens/detalle_peticion_screen.dart';

/// Una acción del panel inferior de [PeticionCard]. Con [onTap] nulo se
/// muestra como una insignia de estado (ej. "Ya calificaste") en vez de un
/// botón — evita depender de un widget externo (como el Chip que usaba
/// antes actividad_screen.dart) para ese caso.
class AccionPeticion {
  final IconData? icono;
  final String? iconoAsset;
  final String texto;
  final VoidCallback? onTap;
  final Color? color;
  const AccionPeticion({this.icono, this.iconoAsset, required this.texto, this.onTap, this.color})
      : assert(icono != null || iconoAsset != null, 'Debe proveer icono o iconoAsset');
}

class PeticionCard extends StatelessWidget {
  final Peticion peticion;
  final double? distanciaKm;
  final List<AccionPeticion>? acciones;

  const PeticionCard({super.key, required this.peticion, this.distanciaKm, this.acciones});

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

    Widget? estado;
    if (!esTrabajador) {
      estado = Text(
        '${peticion.interesados.length} interesados',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
      );
    } else if (yaMeInteresa) {
      estado = Row(
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
      );
    }

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
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, peticion.premiumAprobada ? 38 : 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFE3F2EC),
                        child: Text(
                          peticion.autorNombre[0],
                          style: const TextStyle(color: Color(0xFF0F6E56), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              peticion.autorNombre,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A1A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                peticion.barrio,
                                ?distanciaTexto,
                                _tiempoTranscurrido(),
                              ].join(' · '),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (peticion.fotoUrl != null)
                    Container(
                      height: 100,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
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
                    style: const TextStyle(fontSize: 14, height: 1.35, color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (peticion.urgente) _Etiqueta(texto: 'Urgente', color: const Color(0xFFB54834)),
                      if (peticion.urgente) const SizedBox(width: 6),
                      Flexible(child: _Etiqueta(texto: peticion.categoria, color: const Color(0xFF0F6E56))),
                      if (estado != null) const Spacer(),
                      if (estado != null) Flexible(child: estado),
                    ],
                  ),
                  if (acciones != null && acciones!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Divider(height: 1, color: Colors.grey.shade200),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: acciones!.map(_botonAccion).toList(),
                    ),
                  ],
                ],
              ),
            ),
            if (peticion.premiumAprobada)
              Positioned(
                top: 10,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F6E56),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: Image.asset('assets/icon/estrella.png', fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'DESTACADO',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _iconoDeAccion(AccionPeticion accion, Color color) {
    if (accion.iconoAsset != null) {
      return SizedBox(width: 20, height: 20, child: Image.asset(accion.iconoAsset!, fit: BoxFit.contain));
    }
    return Icon(accion.icono, size: 20, color: color);
  }

  Widget _botonAccion(AccionPeticion accion) {
    final color = accion.color ?? const Color(0xFF1A1A1A);
    if (accion.onTap == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _iconoDeAccion(accion, color),
            const SizedBox(width: 6),
            Text(accion.texto, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      );
    }
    return InkWell(
      onTap: accion.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _iconoDeAccion(accion, color),
            const SizedBox(width: 6),
            Text(accion.texto, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
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
