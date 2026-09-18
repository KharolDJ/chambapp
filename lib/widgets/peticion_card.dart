import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:provider/provider.dart';

import '../models/peticion.dart';
import '../models/usuario.dart';
import '../providers/app_provider.dart';
import '../screens/detalle_peticion_screen.dart';
import 'brillo_dorado.dart';
import 'color_avatar.dart';

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
  const AccionPeticion({
    this.icono,
    this.iconoAsset,
    required this.texto,
    this.onTap,
    this.color,
  }) : assert(
         icono != null || iconoAsset != null,
         'Debe proveer icono o iconoAsset',
       );
}

class PeticionCard extends StatelessWidget {
  final Peticion peticion;
  final double? distanciaKm;
  final List<AccionPeticion>? acciones;

  const PeticionCard({
    super.key,
    required this.peticion,
    this.distanciaKm,
    this.acciones,
  });

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
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final yaMeInteresa =
        provider.usuarioActual != null &&
        peticion.interesados.any((u) => u.id == provider.usuarioActual!.id);
    final esTrabajador = provider.rolActual == RolUsuario.trabajador;
    final distanciaTexto = _textoDistancia();

    Widget? estado;
    if (!esTrabajador) {
      estado = Text(
        '${peticion.interesados.length} interesados',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: tema.textTheme.bodySmall?.color),
      );
    } else if (yaMeInteresa) {
      final colorAplicaste = peticion.premiumAprobada
          ? (esOscuro ? const Color(0xFFE0B84A) : const Color(0xFFAD7A16))
          : (esOscuro ? AppColors.azulCelesteOscuro : AppColors.azulCeleste);
      estado = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 16, color: colorAplicaste),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Aplicaste',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: colorAplicaste),
            ),
          ),
        ],
      );
    }

    final colorAvatar = colorAvatarPara(peticion.autorId);
    // Búsqueda null-safe (no firstWhere): el autor puede no estar todavía en
    // el snapshot local de todosLosUsuarios si su cuenta es muy reciente.
    final autoresCoincidentes = provider.todosLosUsuarios.where(
      (u) => u.id == peticion.autorId,
    );
    final Usuario? autor = autoresCoincidentes.isEmpty
        ? null
        : autoresCoincidentes.first;

    // El fondo dorado (fondoDoradoDeslizante) SIEMPRE es crema pálido en
    // claro o bronce casi negro en oscuro — nunca el fondo normal de la
    // tarjeta — así que el texto sobre él necesita su propia pareja de
    // colores por tema, distinta a la del resto de la tarjeta.
    final colorTitulo = tema.colorScheme.onSurface;
    final colorSubtitulo = tema.textTheme.bodySmall?.color ?? Colors.grey;
    final colorTituloPremium = esOscuro
        ? const Color(0xFFF5E6BE)
        : const Color(0xFF3A2A12);
    final colorSubtituloPremium = esOscuro
        ? const Color(0xFFC9A968)
        : const Color(0xFF7A5B2E);
    final colorTituloActivo = peticion.premiumAprobada
        ? colorTituloPremium
        : colorTitulo;
    final colorSubtituloActivo = peticion.premiumAprobada
        ? colorSubtituloPremium
        : colorSubtitulo;

    Widget construirTarjeta(double? t) => InkWell(
      borderRadius: BorderRadius.circular(peticion.premiumAprobada ? 14 : 16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetallePeticionScreen(
            peticion: peticion,
            distanciaKm: distanciaKm,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: peticion.premiumAprobada ? null : tema.cardColor,
          gradient: peticion.premiumAprobada
              ? fondoDoradoDeslizante(t, esOscuro: esOscuro)
              : null,
          borderRadius: BorderRadius.circular(
            peticion.premiumAprobada ? 14 : 16,
          ),
          border: peticion.premiumAprobada
              ? null
              : Border.all(color: tema.dividerColor),
          boxShadow: peticion.premiumAprobada
              ? sombraDorada(esOscuro: esOscuro)
              : [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: esOscuro ? 0.24 : 0.04,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (peticion.premiumAprobada || peticion.urgente)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      if (peticion.premiumAprobada) ...[
                        Text(
                          'Oferta destacada',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: esOscuro
                                ? const Color(0xFFE0B84A)
                                : const Color(0xFFAD7A16),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                      if (peticion.premiumAprobada && peticion.urgente)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      if (peticion.urgente)
                        const Text(
                          'Se precisa urgentemente',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
                            letterSpacing: 0.3,
                          ),
                        ),
                    ],
                  ),
                ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: colorAvatar.fondo,
                    child: Text(
                      peticion.autorNombre[0].toUpperCase(),
                      style: TextStyle(
                        color: colorAvatar.texto,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                peticion.autorNombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: colorTituloActivo,
                                ),
                              ),
                            ),
                            if (autor != null &&
                                autor.numeroCalificaciones > 0) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.star,
                                size: 13,
                                color: AppColors.doradoCalificacion,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                autor.calificacionPromedio.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  // Solo el número cambia con el tema — el
                                  // ícono de la estrella se queda dorado
                                  // siempre. En oscuro, dorado sobre la
                                  // tarjeta oscura pierde contraste; en
                                  // claro se deja el mismo dorado de
                                  // siempre.
                                  color: esOscuro
                                      ? Colors.white
                                      : AppColors.doradoCalificacion,
                                ),
                              ),
                            ],
                            if (autor?.perfilVerificado ?? false) ...[
                              const SizedBox(width: 4),
                              Image.asset(
                                'assets/icon/verificado.png',
                                width: 14,
                                height: 14,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [
                            peticion.barrio,
                            ?distanciaTexto,
                            _tiempoTranscurrido(),
                          ].join(' · '),
                          style: TextStyle(
                            fontSize: 13,
                            color: colorSubtituloActivo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (peticion.fotoUrl != null)
                Container(
                  height: 100,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: esOscuro
                        ? const Color(0xFF23262B)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.file(
                    File(peticion.fotoUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.image_outlined,
                      color: Colors.grey.shade400,
                      size: 32,
                    ),
                  ),
                ),
              Text(
                peticion.descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.5,
                  height: 1.3,
                  color: colorTituloActivo,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: _Etiqueta(
                            texto: peticion.categoria,
                            color: esOscuro
                                ? AppColors.azulCelesteOscuro
                                : AppColors.azulCeleste,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ?estado,
                ],
              ),
              if (acciones != null && acciones!.isNotEmpty) ...[
                const SizedBox(height: 12),
                if (peticion.premiumAprobada)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                    decoration: BoxDecoration(
                      color: esOscuro
                          ? Colors.black.withValues(alpha: 0.25)
                          : const Color(0xFFFFF6D8).withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFE0A93B).withValues(alpha: 0.35),
                      ),
                    ),
                    child: _barraAcciones(acciones!, colorTituloPremium),
                  )
                else ...[
                  Divider(height: 1, color: tema.dividerColor),
                  const SizedBox(height: 10),
                  _barraAcciones(acciones!, colorTitulo),
                ],
              ],
            ],
          ),
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: peticion.premiumAprobada
          ? BrilloDoradoAnimado(
              borderRadius: BorderRadius.circular(16),
              builder: (context, t) => construirTarjeta(t),
            )
          : construirTarjeta(null),
    );
  }

  /// Fila única y homogénea para los botones de acción inferiores: cada
  /// botón ocupa una fracción igual del ancho disponible (`Expanded`) en
  /// vez de un `Wrap`, así nunca se apilan en una segunda línea ni rompen
  /// la retícula de la tarjeta en pantallas angostas — el texto largo se
  /// trunca con elipsis dentro de su propio botón en lugar de forzar un
  /// salto de línea para toda la barra.
  Widget _barraAcciones(List<AccionPeticion> acciones, Color colorPorDefecto) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var i = 0; i < acciones.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(child: _botonAccion(acciones[i], colorPorDefecto)),
        ],
      ],
    );
  }

  Widget _iconoDeAccion(AccionPeticion accion, Color color) {
    if (accion.iconoAsset != null) {
      return SizedBox(
        width: 16,
        height: 16,
        child: Image.asset(accion.iconoAsset!, fit: BoxFit.contain),
      );
    }
    return Icon(accion.icono, size: 16, color: color);
  }

  Widget _botonAccion(AccionPeticion accion, Color colorPorDefecto) {
    final color = accion.color ?? colorPorDefecto;
    final esInsignia = accion.onTap == null;
    final contenido = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _iconoDeAccion(accion, color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            accion.texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
    final caja = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: esInsignia ? color.withValues(alpha: 0.1) : null,
        border: esInsignia
            ? null
            : Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: contenido,
    );
    if (esInsignia) return caja;
    return InkWell(
      onTap: accion.onTap,
      borderRadius: BorderRadius.circular(8),
      child: caja,
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;
  final Color color;
  const _Etiqueta({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
    );
  }
}
