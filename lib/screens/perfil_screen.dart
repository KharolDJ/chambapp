import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:provider/provider.dart';

import '../models/usuario.dart';
import '../providers/app_provider.dart';
import '../widgets/cabecera_oscura.dart';
import '../widgets/color_avatar.dart';
import '../widgets/foto_image.dart';
import '../widgets/login_form.dart';
import 'administracion_screen.dart';
import 'configuracion_screen.dart';
import 'editar_perfil_screen.dart';
import 'mis_calificaciones_screen.dart';
import 'premium_trabajador_screen.dart';
import 'role_selector_screen.dart';
import 'verificacion_identidad_screen.dart';

// Tono neutral para chips de estado que no deben leerse como "de marca"
// (rol, documento registrado) — a diferencia de los chips de atributo
// (barrio, oficios), que van en negro, para distinguir "quién
// es" de "qué hace/dónde está". Antes #64748B, un gris con matiz azulado
// (slate) — ahora un gris neutro sin ese sesgo.
const _grisNeutro = Color(0xFF6B6B6B);
// Versión clara del mismo gris para tema oscuro (el #6B6B6B casi no se lee
// sobre fondo casi negro).
const _grisNeutroOscuro = Color(0xFFA3A3A3);

// Excepción explícita y puntual al negro/dorado: "Nuevo en la plataforma"
// pidió expresamente un azul elegante propio, no el gris de estado ni el
// dorado de marca — es la única insignia que usa este tono en toda la app.
const _azulNuevo = Color(0xFF0284C7);

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  @override
  void initState() {
    super.initState();
    // Se consulta aquí (no solo al abrir VerificacionIdentidadScreen) para
    // que el reloj de arena de "en revisión" aparezca en Mi perfil aunque la
    // persona nunca haya entrado a esa pantalla en esta sesión.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<AppProvider>();
      if (provider.usuarioActual != null &&
          !provider.usuarioActual!.perfilVerificado) {
        provider.cargarMiVerificacionIdentidad();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final usuario = provider.usuarioActual;

    // Invitado (sin sesión): la pestaña "Perfil" ES la pantalla de acceso —
    // se muestra el formulario de login de una vez, nada de texto
    // promocional ni de un botón que lleve a otra pantalla.
    if (usuario == null) {
      return Scaffold(
        appBar: cabeceraOscura('Mi perfil'),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: LoginForm(),
          ),
        ),
      );
    }

    final colorAvatar = colorAvatarPara(usuario.id);
    final verificacionEnRevision =
        !usuario.perfilVerificado &&
        (provider.miVerificacionIdentidad?.solicitada ?? false) &&
        !(provider.miVerificacionIdentidad?.aprobada ?? false);

    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Scaffold(
      appBar: cabeceraOscura('Mi perfil'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!provider.correoVerificado) const _AvisoCorreoSinVerificar(),
            _TarjetaEncabezado(
              usuario: usuario,
              rolActual: provider.rolActual,
              colorAvatar: colorAvatar,
              verificacionEnRevision: verificacionEnRevision,
              esOscuro: esOscuro,
            ),
            if (usuario.bio != null && usuario.bio!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              _TarjetaSobreMi(bio: usuario.bio!.trim()),
            ],
            const SizedBox(height: 20),
            const _EtiquetaSeccion('CUENTA'),
            _TarjetaMenu(
              items: [
                _ItemMenu(
                  titulo: 'Mis calificaciones',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MisCalificacionesScreen(),
                    ),
                  ),
                ),
                _ItemMenu(
                  titulo: 'Editar perfil',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditarPerfilScreen(),
                    ),
                  ),
                ),
                _ItemMenu(
                  titulo: 'Perfil verificado',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VerificacionIdentidadScreen(),
                    ),
                  ),
                ),
              ],
            ),
            if (provider.rolActual == RolUsuario.trabajador &&
                usuario.oficios.isNotEmpty) ...[
              const SizedBox(height: 16),
              const _EtiquetaSeccion('COMO TRABAJADOR'),
              _TarjetaMenu(
                items: [
                  _ItemMenu(
                    titulo: 'Visibilidad Premium',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PremiumTrabajadorScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const _EtiquetaSeccion('GENERAL'),
            _TarjetaMenu(
              items: [
                _ItemMenu(
                  titulo: 'Cambiar de modo (Empleador/Trabajador)',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RoleSelectorScreen(),
                    ),
                  ),
                ),
                _ItemMenu(
                  titulo: 'Configuración',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConfiguracionScreen(),
                    ),
                  ),
                ),
              ],
            ),
            if (provider.esAdmin) ...[
              const SizedBox(height: 16),
              const _EtiquetaSeccion('HERRAMIENTAS DEL EQUIPO'),
              _TarjetaMenu(
                items: [
                  _ItemMenu(
                    titulo: 'Administración (reportes)',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdministracionScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EtiquetaSeccion extends StatelessWidget {
  final String texto;
  const _EtiquetaSeccion(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}

class _TarjetaEncabezado extends StatelessWidget {
  final Usuario usuario;
  final RolUsuario? rolActual;
  final ColorAvatar? colorAvatar;
  final bool verificacionEnRevision;
  final bool esOscuro;

  const _TarjetaEncabezado({
    required this.usuario,
    required this.rolActual,
    required this.colorAvatar,
    required this.verificacionEnRevision,
    required this.esOscuro,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final provider = context.watch<AppProvider>();

    // Diseño plano: nada de caja de fondo ni sombras — solo una línea
    // sutil abajo que separa este bloque del menú de cuenta, igual de
    // discreta que la que ya usan las tarjetas de menú.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tema.dividerColor)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: tema.dividerColor, width: 1.5),
            ),
            child: CircleAvatar(
              radius: 42,
              backgroundColor: colorAvatar?.fondo ?? const Color(0xFFE1F5EE),
              backgroundImage: proveedorFoto(usuario.fotoPath),
              child: usuario.fotoPath != null
                  ? null
                  : Text(
                      usuario.nombre[0].toUpperCase(),
                      style: TextStyle(
                        color: colorAvatar!.texto,
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  usuario.nombre,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (usuario.perfilVerificado) ...[
                const SizedBox(width: 4),
                Image.asset(
                  'assets/icon/verificado.png',
                  width: 18,
                  height: 18,
                ),
              ] else if (verificacionEnRevision) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.hourglass_empty,
                  size: 16,
                  // Antes negroProfundo fijo — invisible en modo oscuro
                  // sobre fondo casi negro. onSurface ya es blanco/negro
                  // según el tema.
                  color: tema.colorScheme.onSurface,
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 10,
            children: [
              _Chip(
                texto: rolActual == RolUsuario.empleador
                    ? 'Empleador'
                    : 'Trabajador',
              ),
              if (usuario.numeroCalificaciones > 0)
                _Chip(
                  icono: Icons.star,
                  texto:
                      '${usuario.calificacionPromedio.toStringAsFixed(1)} (${usuario.numeroCalificaciones})',
                  color: AppColors.doradoCalificacion,
                )
              else
                _Chip(
                  icono: Icons.auto_awesome,
                  texto: 'Nuevo en la plataforma',
                  color: _azulNuevo,
                ),
              if (usuario.perfilVerificado)
                _Chip(
                  iconoAsset: 'assets/icon/verificado.png',
                  texto: 'Perfil verificado',
                )
              else if (verificacionEnRevision)
                _Chip(
                  icono: Icons.hourglass_empty,
                  texto: 'Verificación en revisión',
                )
              else if (usuario.cedula != null &&
                  usuario.cedula!.trim().isNotEmpty)
                _Chip(
                  icono: Icons.badge_outlined,
                  texto: 'Documento registrado',
                ),
              if (provider.esAdmin)
                _Chip(
                  icono: Icons.admin_panel_settings_outlined,
                  texto: 'Administrador',
                ),
              if (usuario.barrio != null && usuario.barrio!.trim().isNotEmpty)
                _Chip(
                  iconoAsset: 'assets/icon/marcador_posicion.png',
                  texto: '${usuario.barrio}, Bucaramanga',
                ),
              for (final oficio in usuario.oficios) _Chip(texto: oficio),
            ],
          ),
        ],
      ),
    );
  }
}

// Diseño plano: sin caja ni fondo de color — solo ícono y texto, para que
// esta fila de atributos se lea liviana en vez de una fila de pastillas.
// La mayoría de los íconos son Material outlined (trazo fino, se pueden
// teñir con [color]); ubicación y verificado son los dos PNG a color que
// se pidió reintegrar tal cual — no se tiñen, se muestran con su arte
// original.
class _Chip extends StatelessWidget {
  final IconData? icono;
  final String? iconoAsset;
  final String texto;
  // Sin color explícito todas las etiquetas (rol, ubicación, oficios...)
  // usan el mismo gris neutro, resuelto contra el tema para modo oscuro.
  final Color? color;
  const _Chip({this.icono, this.iconoAsset, required this.texto, this.color});

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final color = this.color ?? (oscuro ? _grisNeutroOscuro : _grisNeutro);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (iconoAsset != null) ...[
          Image.asset(iconoAsset!, width: 14, height: 14),
          const SizedBox(width: 4),
        ] else if (icono != null) ...[
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 4),
        ],
        Text(
          texto,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// Deliberadamente sin ícono, etiqueta ni tarjeta con borde — un bloque de
// texto simple se siente como una descripción de la persona, no como un
// campo de formulario rotulado.
class _TarjetaSobreMi extends StatelessWidget {
  final String bio;
  const _TarjetaSobreMi({required this.bio});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        bio,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          height: 1.45,
          fontStyle: FontStyle.italic,
          color: tema.colorScheme.onSurface.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _ItemMenu {
  final String titulo;
  final VoidCallback onTap;
  const _ItemMenu({required this.titulo, required this.onTap});
}

// Diseño plano: sin caja, sin fondo ni borde alrededor del grupo — solo
// líneas finas entre cada opción, apoyado en la etiqueta de sección de
// arriba ("CUENTA", "GENERAL"...) para agrupar visualmente.
class _TarjetaMenu extends StatelessWidget {
  final List<_ItemMenu> items;
  const _TarjetaMenu({required this.items});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) Divider(height: 1, color: tema.dividerColor),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(items[i].titulo),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: items[i].onTap,
          ),
        ],
      ],
    );
  }
}

class _AvisoCorreoSinVerificar extends StatefulWidget {
  const _AvisoCorreoSinVerificar();

  @override
  State<_AvisoCorreoSinVerificar> createState() =>
      _AvisoCorreoSinVerificarState();
}

class _AvisoCorreoSinVerificarState extends State<_AvisoCorreoSinVerificar> {
  bool _reenviando = false;
  bool _verificando = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAEEDA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                color: Color(0xFFAD7A16),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Verifica tu correo para poder aplicar a publicaciones o publicar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFAD7A16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              TextButton(
                onPressed: _reenviando
                    ? null
                    : () async {
                        setState(() => _reenviando = true);
                        await context
                            .read<AppProvider>()
                            .reenviarCorreoVerificacion();
                        if (!context.mounted) return;
                        setState(() => _reenviando = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Correo de verificación reenviado'),
                          ),
                        );
                      },
                child: Text(_reenviando ? 'Enviando...' : 'Reenviar correo'),
              ),
              TextButton(
                onPressed: _verificando
                    ? null
                    : () async {
                        setState(() => _verificando = true);
                        await context
                            .read<AppProvider>()
                            .recargarVerificacionCorreo();
                        if (!context.mounted) return;
                        setState(() => _verificando = false);
                        if (context.read<AppProvider>().correoVerificado) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('¡Correo verificado!'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Todavía no aparece verificado — revisa tu bandeja de entrada',
                              ),
                            ),
                          );
                        }
                      },
                child: Text(
                  _verificando ? 'Revisando...' : 'Ya verifiqué mi correo',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
