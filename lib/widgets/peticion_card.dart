import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:provider/provider.dart';

import '../models/peticion.dart';
import '../models/usuario.dart';
import '../providers/app_provider.dart';
import '../screens/detalle_peticion_screen.dart';
import 'brillo_dorado.dart';
import 'color_avatar.dart';
import 'foto_image.dart';

/// Una acción del panel inferior de [PeticionCard]. Con [onTap] nulo se
/// muestra como una insignia de estado (ej. "Ya calificaste") en vez de un
/// botón — evita depender de un widget externo (como el Chip que usaba
/// antes actividad_screen.dart) para ese caso. El ícono es opcional: sin
/// [icono] ni [iconoAsset] el botón muestra solo el texto.
class AccionPeticion {
  final IconData? icono;
  final String? iconoAsset;
  final String texto;
  final VoidCallback? onTap;
  final Color? color;
  final EstiloAccion estilo;
  const AccionPeticion({
    this.icono,
    this.iconoAsset,
    required this.texto,
    this.onTap,
    this.color,
    this.estilo = EstiloAccion.contorno,
  });

  bool get tieneIcono => icono != null || iconoAsset != null;
}

/// Apariencia de un botón de [AccionPeticion]:
/// - [contorno]: borde fino del color de la acción (el diseño original).
/// - [solido]: fondo negro y texto blanco (invertido en tema oscuro), como
///   los demás botones principales de la app.
/// - [solidoPremium]: la misma base negra, pero con texto y borde dorados
///   para que "Premium" se distinga sin salirse de la línea en negro.
enum EstiloAccion { contorno, solido, solidoPremium }

class PeticionCard extends StatelessWidget {
  final Peticion peticion;
  final double? distanciaKm;
  final List<AccionPeticion>? acciones;
  final Widget? piePersonalizado;
  // Insignia de estado (ej. "Ya calificaste") anclada a la esquina
  // superior derecha de la tarjeta — a diferencia de [acciones] o
  // [piePersonalizado], no compite por espacio con el contenido central ni
  // se ve como un botón más en la fila de acciones.
  final Widget? insigniaEsquina;

  const PeticionCard({
    super.key,
    required this.peticion,
    this.distanciaKm,
    this.acciones,
    this.piePersonalizado,
    this.insigniaEsquina,
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
      // Mismo criterio que el resto de los estados: premium/destacado se
      // queda dorado, las ofertas normales pasan a celeste (antes también
      // caían en dorado, sin distinción real con las premium).
      final colorAplicaste = peticion.premiumAprobada
          ? (esOscuro ? const Color(0xFFE0B84A) : const Color(0xFFAD7A16))
          : (esOscuro
                ? AppColors.celesteCategoriaOscuro
                : AppColors.celesteCategoria);
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

    // En claro, la ficha urgente usa base blanca (baseBlanca) con el brillo
    // y el anillo dorados como únicos acentos, así que el texto va en el
    // mismo negro/gris de una tarjeta normal. En oscuro la base sigue siendo
    // bronce casi negro, que necesita su propia pareja de colores cálidos.
    final colorTitulo = tema.colorScheme.onSurface;
    final colorSubtitulo = tema.textTheme.bodySmall?.color ?? Colors.grey;
    final colorTituloPremium = esOscuro
        ? const Color(0xFFF5E6BE)
        : colorTitulo;
    final colorSubtituloPremium = esOscuro
        ? const Color(0xFFC9A968)
        : colorSubtitulo;
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
              ? fondoDoradoDeslizante(t, esOscuro: esOscuro, baseBlanca: true)
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
              // Una sola etiqueta para el único producto pago ("Urgente"),
              // en el mismo dorado del diseño premium de la tarjeta.
              if (peticion.esUrgente)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Se precisa urgentemente',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: esOscuro
                          ? const Color(0xFFE0B84A)
                          : const Color(0xFFAD7A16),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: colorAvatar.fondo,
                    backgroundImage: proveedorFoto(autor?.fotoPath),
                    child: autor?.fotoPath != null
                        ? null
                        : Text(
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
                  child: imagenFoto(
                    peticion.fotoUrl!,
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
                                ? AppColors.celesteCategoriaOscuro
                                : AppColors.celesteCategoria,
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
                    child: _barraAcciones(
                      acciones!,
                      colorTituloPremium,
                      esOscuro,
                    ),
                  )
                else ...[
                  Divider(height: 1, color: tema.dividerColor),
                  const SizedBox(height: 10),
                  _barraAcciones(acciones!, colorTitulo, esOscuro),
                ],
              ],
              if (piePersonalizado != null) ...[
                const SizedBox(height: 12),
                Divider(height: 1, color: tema.dividerColor),
                const SizedBox(height: 10),
                piePersonalizado!,
              ],
            ],
          ),
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          peticion.premiumAprobada
              ? BrilloDoradoAnimado(
                  borderRadius: BorderRadius.circular(16),
                  builder: (context, t) => construirTarjeta(t),
                )
              : construirTarjeta(null),
          if (insigniaEsquina != null)
            Positioned(top: 14, right: 14, child: insigniaEsquina!),
        ],
      ),
    );
  }

  /// Fila única y homogénea para los botones de acción inferiores: cada
  /// botón ocupa una fracción igual del ancho disponible (`Expanded`) en
  /// vez de un `Wrap`, así nunca se apilan en una segunda línea ni rompen
  /// la retícula de la tarjeta en pantallas angostas — el texto largo se
  /// trunca con elipsis dentro de su propio botón en lugar de forzar un
  /// salto de línea para toda la barra.
  Widget _barraAcciones(
    List<AccionPeticion> acciones,
    Color colorPorDefecto,
    bool esOscuro,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var i = 0; i < acciones.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _botonAccion(acciones[i], colorPorDefecto, esOscuro),
          ),
        ],
      ],
    );
  }

  Widget _iconoDeAccion(AccionPeticion accion, Color color) {
    if (accion.iconoAsset != null) {
      // Los PNG de acción son de un solo trazo (negro o dorado sólido) —
      // se tiñen del mismo color que el texto para que sigan el tema
      // claro/oscuro en vez de quedar fijos en su color original (un
      // ícono negro fijo sería invisible sobre una tarjeta en modo oscuro).
      return SizedBox(
        width: 16,
        height: 16,
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          child: Image.asset(accion.iconoAsset!, fit: BoxFit.contain),
        ),
      );
    }
    return Icon(accion.icono, size: 16, color: color);
  }

  Widget _botonAccion(
    AccionPeticion accion,
    Color colorPorDefecto,
    bool esOscuro,
  ) {
    if (accion.estilo != EstiloAccion.contorno) {
      return _botonSolido(accion, esOscuro);
    }
    final color = accion.color ?? colorPorDefecto;
    final esInsignia = accion.onTap == null;
    final contenido = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (accion.tieneIcono) ...[
          _iconoDeAccion(accion, color),
          const SizedBox(width: 5),
        ],
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

  Widget _botonSolido(AccionPeticion accion, bool esOscuro) {
    final esPremium = accion.estilo == EstiloAccion.solidoPremium;
    final fondo = esOscuro ? Colors.white : AppColors.negroProfundo;
    final Color colorTexto;
    if (esPremium) {
      // Dorado brillante sobre negro (#E0B84A se veía apagado/ocre) /
      // dorado de marca sobre blanco: los dos pares con buen contraste
      // para texto pequeño en negrita.
      colorTexto = esOscuro ? AppColors.dorado : const Color(0xFFF7C948);
    } else {
      colorTexto = esOscuro ? AppColors.negroProfundo : Colors.white;
    }
    return Material(
      color: fondo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: esPremium
            ? BorderSide(color: colorTexto.withValues(alpha: 0.7))
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: accion.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (accion.tieneIcono) ...[
                _iconoDeAccion(accion, colorTexto),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  accion.texto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colorTexto,
                  ),
                ),
              ),
            ],
          ),
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
    // Antes era texto suelto de 10px sin fondo — se leía chico y perdido
    // junto al resto de la tarjeta. Ahora es una píldora como el resto de
    // las etiquetas de categoría de la app.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
