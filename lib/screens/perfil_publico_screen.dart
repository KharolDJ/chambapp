import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:provider/provider.dart';

import '../models/usuario.dart';
import '../providers/app_provider.dart';
import '../widgets/color_avatar.dart';
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
                      color: AppColors.azulCeleste,
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
        backgroundColor: error == null ? AppColors.azulCeleste : null,
      ),
    );
  }

  ImageProvider? _fotoSiExiste() {
    final ruta = usuario.fotoPath;
    if (ruta == null) return null;
    final archivo = File(ruta);
    if (!archivo.existsSync()) return null;
    return FileImage(archivo);
  }

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
      padding: const EdgeInsets.all(24),
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: colorAvatar.fondo,
              backgroundImage: foto,
              child: foto == null
                  ? Text(
                      usuario.nombre[0].toUpperCase(),
                      style: TextStyle(
                        color: colorAvatar.texto,
                        fontWeight: FontWeight.bold,
                        fontSize: 34,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 14),
            Text(
              usuario.nombre,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (usuario.perfilVerificado)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icon/verificado.png',
                      width: 14,
                      height: 14,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Perfil verificado',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.azulCeleste,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            if (usuario.numeroCalificaciones > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star,
                    size: 16,
                    color: AppColors.doradoCalificacion,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${usuario.calificacionPromedio.toStringAsFixed(1)} (${usuario.numeroCalificaciones} calificaciones)',
                    style: TextStyle(
                      fontSize: 13,
                      color: tema.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
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
                      size: 14,
                      color: AppColors.azulCeleste,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Nuevo en la plataforma',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.azulCeleste,
                      ),
                    ),
                  ],
                ),
              ),
            if (usuario.barrio != null && usuario.barrio!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icon/marcador_posicion.png',
                      width: 14,
                      height: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${usuario.barrio}, Bucaramanga',
                      style: TextStyle(
                        fontSize: 12,
                        color: tema.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            if (usuario.oficios.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Oficios: ${usuario.oficios.join(', ')}',
                  style: TextStyle(
                    fontSize: 13,
                    color: tema.textTheme.bodySmall?.color,
                  ),
                ),
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
                      foregroundColor: AppColors.azulCeleste,
                      side: const BorderSide(color: AppColors.azulCeleste),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
          ],
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.azulCeleste,
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
