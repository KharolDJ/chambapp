import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:provider/provider.dart';

import '../models/usuario.dart';
import '../providers/app_provider.dart';
import '../widgets/color_avatar.dart';
import '../widgets/foto_image.dart';
import '../widgets/peticion_card.dart';

/// Perfil de solo lectura de otro usuario (empleador o trabajador),
/// alcanzable desde la búsqueda de personas en el feed o desde el Podio de
/// Recomendados. A diferencia de PerfilScreen (que siempre muestra al
/// usuario logueado), esta pantalla no tiene acciones de dueño: sin editar,
/// sin cambiar de rol, y deliberadamente sin botón de contacto directo — el
/// número de celular sigue sin exponerse aquí. La única acción posible es
/// "Invitar a mi publicación" (solo si el que mira es empleador con alguna
/// publicación propia abierta) — manda una notificación con el enlace a la
/// publicación, pero NO agrega al trabajador a `interesados` ni abre
/// WhatsApp: el contacto real sigue pasando por el mismo flujo de
/// aplicar/seleccionar de siempre, solo que ahora el trabajador puede
/// enterarse de la publicación sin haberla visto por su cuenta.
class PerfilPublicoScreen extends StatefulWidget {
  final String usuarioId;
  const PerfilPublicoScreen({super.key, required this.usuarioId});

  @override
  State<PerfilPublicoScreen> createState() => _PerfilPublicoScreenState();
}

class _PerfilPublicoScreenState extends State<PerfilPublicoScreen> {
  Usuario? _usuarioRemoto;
  bool _buscandoEnFirestore = false;
  bool _noEncontrado = false;

  Usuario? _buscarLocal(AppProvider provider) {
    for (final u in provider.todosLosUsuarios) {
      if (u.id == widget.usuarioId) return u;
    }
    return null;
  }

  Future<void> _buscarEnFirestore() async {
    if (_buscandoEnFirestore) return;
    _buscandoEnFirestore = true;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.usuarioId)
          .get();
      if (!mounted) return;
      if (doc.exists) {
        setState(() => _usuarioRemoto = Usuario.fromJson(doc.data()!));
      } else {
        setState(() => _noEncontrado = true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _noEncontrado = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final usuario = _buscarLocal(provider) ?? _usuarioRemoto;

    if (usuario == null && !_noEncontrado) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _buscarEnFirestore());
    }

    return Scaffold(
      appBar: AppBar(title: Text(usuario?.nombre ?? 'Perfil')),
      body: usuario == null
          ? Center(
              child: _noEncontrado
                  ? Text(
                      'Este usuario ya no está disponible',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    )
                  : const CircularProgressIndicator(
                      color: AppColors.dorado,
                    ),
            )
          : _CuerpoPerfil(usuario: usuario, provider: provider),
    );
  }
}

class _CuerpoPerfil extends StatelessWidget {
  final Usuario usuario;
  final AppProvider provider;
  const _CuerpoPerfil({required this.usuario, required this.provider});

  Future<void> _invitar(
    BuildContext context,
    AppProvider provider,
    Usuario trabajador,
  ) async {
    final publicaciones = provider.misPublicacionesInvitables;
    String? peticionId;
    if (publicaciones.length == 1) {
      peticionId = publicaciones.first.id;
    } else {
      peticionId = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '¿A cuál publicación quieres invitar?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 8),
                ...publicaciones.map(
                  (p) => ListTile(
                    title: Text(
                      p.descripcion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(p.categoria),
                    onTap: () => Navigator.pop(context, p.id),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (peticionId == null || !context.mounted) return;

    final error = await provider.invitarTrabajador(
      peticionId: peticionId,
      trabajador: trabajador,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Invitación enviada a ${trabajador.nombre}'),
        backgroundColor: error == null ? AppColors.dorado : null,
      ),
    );
  }

  ImageProvider? _fotoSiExiste() => proveedorFoto(usuario.fotoPath);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final foto = _fotoSiExiste();
    final colorAvatar = colorAvatarPara(usuario.id);
    final calificaciones = provider.calificaciones
        .where((c) => c.paraUsuarioId == usuario.id)
        .toList()
        .reversed
        .toList();
    final publicaciones =
        provider.peticiones
            .where((p) => p.autorId == usuario.id && !p.archivada)
            .toList()
          ..sort((a, b) => b.creadaEn.compareTo(a.creadaEn));
    final publicacionesActivas = publicaciones
        .where((p) => !p.cerrada)
        .toList();
    final publicacionesFinalizadas = publicaciones
        .where((p) => p.cerrada)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
          decoration: BoxDecoration(
            color: tema.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tema.dividerColor),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tema.cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: tema.brightness == Brightness.dark ? 0.3 : 0.08,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: colorAvatar.fondo,
                  backgroundImage: foto,
                  child: foto == null
                      ? Text(
                          usuario.nombre[0].toUpperCase(),
                          style: TextStyle(
                            color: colorAvatar.texto,
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                usuario.nombre,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (usuario.bio != null && usuario.bio!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  usuario.bio!.trim(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    fontStyle: FontStyle.italic,
                    color: tema.colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (usuario.numeroCalificaciones > 0)
                    _EtiquetaInfo(
                      icono: Icons.star,
                      texto:
                          '${usuario.calificacionPromedio.toStringAsFixed(1)} (${usuario.numeroCalificaciones})',
                      color: AppColors.doradoCalificacion,
                    )
                  else
                    _EtiquetaInfo(
                      icono: Icons.auto_awesome,
                      texto: 'Nuevo en la plataforma',
                      // Mismo celeste que en "Mi perfil" (#0284C7).
                      color: AppColors.celesteCategoria,
                    ),
                  if (usuario.perfilVerificado)
                    _EtiquetaInfo(
                      iconoAsset: 'assets/icon/verificado.png',
                      texto: 'Perfil verificado',
                    ),
                  if (usuario.barrio != null &&
                      usuario.barrio!.trim().isNotEmpty)
                    _EtiquetaInfo(
                      iconoAsset: 'assets/icon/marcador_posicion.png',
                      texto: '${usuario.barrio}, Bucaramanga',
                    ),
                  for (final oficio in usuario.oficios)
                    _EtiquetaInfo(texto: oficio),
                ],
              ),
              if (provider.usuarioActual != null &&
                  provider.usuarioActual!.id != usuario.id &&
                  provider.rolActual == RolUsuario.empleador &&
                  provider.misPublicacionesInvitables.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _invitar(context, provider, usuario),
                      icon: const Icon(Icons.send_outlined, size: 18),
                      label: const Text('Invitar a mi publicación'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.dorado,
                        side: const BorderSide(color: AppColors.dorado),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (publicaciones.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'Publicaciones',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: tema.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (publicacionesActivas.isNotEmpty) ...[
            Text(
              'ACTIVAS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            ...publicacionesActivas.map((p) => PeticionCard(peticion: p)),
          ],
          if (publicacionesFinalizadas.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.only(
                top: publicacionesActivas.isNotEmpty ? 8 : 0,
              ),
              child: Text(
                'FINALIZADAS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...publicacionesFinalizadas.map((p) => PeticionCard(peticion: p)),
          ],
        ],
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),
        Text(
          'Calificaciones recibidas',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: tema.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        if (calificaciones.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Todavía nadie ha calificado a esta persona',
              style: TextStyle(color: tema.textTheme.bodySmall?.color),
            ),
          )
        else
          ...calificaciones.map((c) {
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
                      alpha: tema.brightness == Brightness.dark ? 0.2 : 0.04,
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
                      (i) => Icon(
                        i < c.estrellas ? Icons.star : Icons.star_border,
                        size: 18,
                        color: AppColors.doradoCalificacion,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '— $nombreAutor',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tema.colorScheme.onSurface,
                    ),
                  ),
                  if (c.comentario != null &&
                      c.comentario!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(c.comentario!, style: const TextStyle(fontSize: 13)),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }
}

// Diseño plano, igual que los chips de "Mi perfil": sin pastilla de fondo
// ni tinte dorado — solo ícono y texto en gris neutro.
class _EtiquetaInfo extends StatelessWidget {
  final String? iconoAsset;
  final IconData? icono;
  final String texto;
  // Sin color explícito todas las etiquetas (ubicación, oficios...) usan el
  // mismo gris neutro que "Mi perfil", resuelto contra el tema.
  final Color? color;
  const _EtiquetaInfo({
    this.iconoAsset,
    this.icono,
    required this.texto,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final color = this.color ??
        (oscuro ? const Color(0xFFA3A3A3) : const Color(0xFF6B6B6B));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconoAsset != null) ...[
            Image.asset(iconoAsset!, width: 12, height: 12),
            const SizedBox(width: 4),
          ] else if (icono != null) ...[
            Icon(icono, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
