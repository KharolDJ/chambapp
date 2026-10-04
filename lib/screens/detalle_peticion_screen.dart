import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:provider/provider.dart';

import '../models/peticion.dart';
import '../providers/app_provider.dart';
import '../widgets/color_avatar.dart';
import '../widgets/foto_image.dart';
import 'login_screen.dart';
import 'perfil_publico_screen.dart';
import 'reportar_screen.dart';

class DetallePeticionScreen extends StatelessWidget {
  final Peticion peticion;
  final double? distanciaKm;

  const DetallePeticionScreen({
    super.key,
    required this.peticion,
    this.distanciaKm,
  });

  String _tiempoTranscurrido() {
    final diff = DateTime.now().difference(peticion.creadaEn);
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }

  // Esta pantalla es un StatelessWidget que recibe la petición congelada al
  // momento de navegar a ella — sin esto, marcar/quitar interés (o
  // cualquier otro cambio en vivo) nunca se reflejaba aquí hasta salir y
  // volver a entrar, porque `peticion` seguía siendo ese snapshot viejo
  // aunque el provider ya tuviera el dato actualizado.
  Peticion _peticionViva(AppProvider provider) => provider.peticiones
      .firstWhere((p) => p.id == peticion.id, orElse: () => peticion);

  String? _textoDistancia() {
    if (distanciaKm == null) return null;
    if (distanciaKm! < 1) return 'cerca de ti';
    return 'a ~${distanciaKm!.toStringAsFixed(1)} km';
  }

  Future<void> _tocarAplicar(BuildContext context) async {
    final provider = context.read<AppProvider>();

    if (provider.usuarioActual == null) {
      final autenticado = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (autenticado != true) return;
      if (!context.mounted) return;
    }

    final providerActualizado = context.read<AppProvider>();
    if (!providerActualizado.correoVerificado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verifica tu correo antes de aplicar — revisa tu perfil',
          ),
        ),
      );
      return;
    }
    final peticion = _peticionViva(providerActualizado);
    final yaEstaba = peticion.interesados.any(
      (u) => u.id == providerActualizado.usuarioActual!.id,
    );
    providerActualizado.marcarInteres(peticion.id);
    if (!context.mounted) return;
    // Un solo estilo sólido para los dos mensajes — antes uno era gris y
    // el otro dorado, ahora ambos negro con texto blanco.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          yaEstaba ? 'Quitaste tu interés en esta petición' : 'Marcaste interés — si el empleador te selecciona, te va a escribir por WhatsApp',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.negroProfundo,
      ),
    );
  }

  Future<void> _tocarNombreAutor(BuildContext context) async {
    if (context.read<AppProvider>().usuarioActual == null) {
      final autenticado = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (autenticado != true) return;
      if (!context.mounted) return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PerfilPublicoScreen(usuarioId: peticion.autorId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    // Sombra intencional del campo `peticion` con la versión en vivo — de
    // aquí para abajo, cada `peticion.algo` ya lee el dato actualizado del
    // provider en vez del snapshot congelado del constructor.
    final peticion = _peticionViva(provider);
    final esTrabajador = provider.rolActual == RolUsuario.trabajador;
    final yaAplico =
        provider.usuarioActual != null &&
        peticion.interesados.any((u) => u.id == provider.usuarioActual!.id);
    final fuiSeleccionado =
        provider.usuarioActual != null &&
        peticion.trabajadorSeleccionadoId == provider.usuarioActual!.id;
    final distanciaTexto = _textoDistancia();
    final colorAvatar = colorAvatarPara(peticion.autorId);
    // Búsqueda null-safe (no firstWhere): igual que en peticion_card.dart,
    // el autor puede no estar todavía en el snapshot local si su cuenta es
    // muy reciente, o si nadie ha iniciado sesión (todosLosUsuarios solo se
    // sincroniza con sesión activa).
    final autoresCoincidentes = provider.todosLosUsuarios.where(
      (u) => u.id == peticion.autorId,
    );
    final autor = autoresCoincidentes.isEmpty
        ? null
        : autoresCoincidentes.first;

    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de la petición'),
        actions: [
          if (provider.usuarioActual != null)
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              tooltip: 'Reportar publicación',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ReportarScreen(tipo: 'peticion', contraId: peticion.id),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _tocarNombreAutor(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: colorAvatar.fondo,
                        backgroundImage: proveedorFoto(autor?.fotoPath),
                        child: autor?.fotoPath != null
                            ? null
                            : Text(
                                peticion.autorNombre[0].toUpperCase(),
                                style: TextStyle(
                                  color: colorAvatar.texto,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.celesteCategoria
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Ver perfil',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.celesteCategoria,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right,
                                        size: 14,
                                        color: AppColors.celesteCategoria,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              [
                                peticion.barrio,
                                ?distanciaTexto,
                                _tiempoTranscurrido(),
                              ].join(' · '),
                              style: TextStyle(
                                fontSize: 12,
                                color: tema.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (peticion.esUrgente) ...[
                    _Etiqueta(
                      texto: 'Urgente',
                      color: esOscuro
                          ? const Color(0xFFE0B84A)
                          : const Color(0xFFAD7A16),
                    ),
                    const SizedBox(width: 6),
                  ],
                  _Etiqueta(
                    texto: peticion.categoria,
                    color: esOscuro
                        ? AppColors.celesteCategoriaOscuro
                        : AppColors.celesteCategoria,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (peticion.fotoUrl != null)
                Container(
                  height: 180,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: esOscuro
                        ? const Color(0xFF23262B)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: imagenFoto(
                    peticion.fotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.image_outlined,
                      color: Colors.grey.shade400,
                      size: 40,
                    ),
                  ),
                ),
              Text(
                peticion.descripcion,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: tema.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 32),
              if (esTrabajador)
                _BotonInteres(
                  fuiSeleccionado: fuiSeleccionado,
                  yaAplico: yaAplico,
                  onTap: () => _tocarAplicar(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón de aplicar/quitar interés, con el corazón animándose al tocar.
/// `fuiSeleccionado` es un estado terminal (ya no se puede deshacer) así
/// que se queda como botón sólido negro/blanco deshabilitado; entre
/// "Aplicar" y "Ya aplicaste" sí hay ida y vuelta, por eso viven en un
/// solo widget con estado propio: así el corazón puede animarse en vez de
/// saltar de un diseño a otro.
class _BotonInteres extends StatefulWidget {
  final bool fuiSeleccionado;
  final bool yaAplico;
  final VoidCallback onTap;
  const _BotonInteres({
    required this.fuiSeleccionado,
    required this.yaAplico,
    required this.onTap,
  });

  @override
  State<_BotonInteres> createState() => _BotonInteresState();
}

class _BotonInteresState extends State<_BotonInteres>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: widget.yaAplico ? 1 : 0,
  );

  @override
  void didUpdateWidget(covariant _BotonInteres oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.yaAplico == oldWidget.yaAplico) return;
    if (widget.yaAplico) {
      _controller.forward();
    } else {
      // Al quitar el interés vuelve directo al botón negro de "Aplicar" —
      // no se pidió una animación de "vaciado", solo que el cambio sea
      // instantáneo y reactivo.
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tocar() {
    // Feedback optimista: el corazón empieza a llenarse apenas se toca,
    // sin esperar el viaje de ida y vuelta a Firestore que hace onTap.
    if (!widget.yaAplico) _controller.forward();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    if (widget.fuiSeleccionado) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.verified),
          label: const Text('¡Fuiste seleccionado para este trabajo!'),
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: esOscuro
                ? Colors.white
                : AppColors.negroProfundo,
            disabledForegroundColor: esOscuro
                ? AppColors.negroProfundo
                : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    final colorBotonNegro = esOscuro ? Colors.white : AppColors.negroProfundo;
    final colorTextoNegro = esOscuro ? AppColors.negroProfundo : Colors.white;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        // El botón conserva siempre su fondo negro y texto blanco
        // (invertidos en tema oscuro); lo único que cambia al aplicar es
        // el corazón, que pasa de contorno a relleno con un pequeño "pop"
        // de escala (sube hasta 1.3x a mitad de la animación y vuelve).
        final escalaCorazon = 1 + 0.3 * (t < 0.5 ? t * 2 : (1 - t) * 2);
        return Material(
          color: colorBotonNegro,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _tocar,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: escalaCorazon,
                    child: Icon(
                      t > 0.05 ? Icons.favorite : Icons.favorite_border,
                      color: colorTextoNegro,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      t > 0.5 ? 'Ya aplicaste' : 'Aplicar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorTextoNegro,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
