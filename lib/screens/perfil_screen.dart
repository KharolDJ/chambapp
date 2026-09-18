import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../widgets/color_avatar.dart';
import 'administracion_screen.dart';
import 'configuracion_screen.dart';
import 'editar_perfil_screen.dart';
import 'login_screen.dart';
import 'mis_calificaciones_screen.dart';
import 'premium_trabajador_screen.dart';
import 'role_selector_screen.dart';
import 'verificacion_identidad_screen.dart';

Widget _iconoMenu(String nombre) => SizedBox(
  width: 24,
  height: 24,
  child: Image.asset('assets/icon/$nombre.png', fit: BoxFit.contain),
);

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
    final colorAvatar = usuario != null ? colorAvatarPara(usuario.id) : null;
    final verificacionEnRevision =
        usuario != null &&
        !usuario.perfilVerificado &&
        (provider.miVerificacionIdentidad?.solicitada ?? false) &&
        !(provider.miVerificacionIdentidad?.aprobada ?? false);

    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (usuario != null && !provider.correoVerificado)
              const _AvisoCorreoSinVerificar(),
            CircleAvatar(
              radius: 45,
              backgroundColor: colorAvatar?.fondo ?? const Color(0xFFE1F5EE),
              backgroundImage: usuario?.fotoPath != null
                  ? FileImage(File(usuario!.fotoPath!))
                  : null,
              child: usuario?.fotoPath != null
                  ? null
                  : (usuario != null
                        ? Text(
                            usuario.nombre[0].toUpperCase(),
                            style: TextStyle(
                              color: colorAvatar!.texto,
                              fontWeight: FontWeight.bold,
                              fontSize: 34,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 50,
                            color: AppColors.azulCeleste,
                          )),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    usuario?.nombre ?? 'Aún no te has registrado',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (usuario?.perfilVerificado ?? false) ...[
                  const SizedBox(width: 4),
                  Image.asset(
                    'assets/icon/verificado.png',
                    width: 18,
                    height: 18,
                  ),
                ] else if (verificacionEnRevision) ...[
                  const SizedBox(width: 4),
                  Image.asset(
                    'assets/icon/reloj_arena.png',
                    width: 16,
                    height: 16,
                  ),
                ],
              ],
            ),
            Text(
              provider.rolActual == RolUsuario.empleador
                  ? 'Empleador'
                  : 'Trabajador',
              style: TextStyle(color: tema.textTheme.bodySmall?.color),
            ),
            if (usuario != null) ...[
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
              if (usuario.perfilVerificado)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icon/verificado.png',
                        width: 14,
                        height: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Perfil verificado',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.azulCeleste,
                        ),
                      ),
                    ],
                  ),
                )
              else if (verificacionEnRevision)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icon/reloj_arena.png',
                        width: 13,
                        height: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Solicitud de verificación en revisión',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFAD7A16),
                        ),
                      ),
                    ],
                  ),
                )
              else if (usuario.cedula != null &&
                  usuario.cedula!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        size: 13,
                        color: tema.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Documento registrado',
                        style: TextStyle(
                          fontSize: 11,
                          color: tema.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              if (usuario.barrio != null && usuario.barrio!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icon/marcador_posicion.png',
                        width: 13,
                        height: 13,
                      ),
                      const SizedBox(width: 4),
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
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Oficios: ${usuario.oficios.join(', ')}',
                    style: TextStyle(
                      fontSize: 13,
                      color: tema.textTheme.bodySmall?.color,
                    ),
                  ),
                ),
            ] else ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                icon: const Icon(Icons.login),
                label: const Text('Iniciar sesión o registrarme'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azulCeleste,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(),
            ListTile(
              leading: _iconoMenu('estrella'),
              title: const Text('Mis calificaciones'),
              enabled: usuario != null,
              onTap: usuario == null
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MisCalificacionesScreen(),
                      ),
                    ),
            ),
            ListTile(
              leading: _iconoMenu('lapiz'),
              title: const Text('Editar perfil'),
              enabled: usuario != null,
              onTap: usuario == null
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditarPerfilScreen(),
                      ),
                    ),
            ),
            if (provider.rolActual == RolUsuario.trabajador && usuario != null)
              ListTile(
                leading: usuario.perfilVerificado
                    ? Image.asset(
                        'assets/icon/verificado.png',
                        width: 24,
                        height: 24,
                      )
                    : verificacionEnRevision
                    ? Image.asset(
                        'assets/icon/reloj_arena.png',
                        width: 24,
                        height: 24,
                      )
                    : const Icon(Icons.verified_outlined),
                title: const Text('Perfil verificado'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VerificacionIdentidadScreen(),
                  ),
                ),
              ),
            if (provider.rolActual == RolUsuario.trabajador &&
                usuario != null &&
                usuario.oficios.isNotEmpty)
              ListTile(
                leading: Image.asset(
                  'assets/icon/podio.png',
                  width: 24,
                  height: 24,
                ),
                title: const Text('Visibilidad Premium'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PremiumTrabajadorScreen(),
                  ),
                ),
              ),
            ListTile(
              leading: _iconoMenu('intercambiar'),
              title: const Text('Cambiar de modo (Empleador/Trabajador)'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RoleSelectorScreen()),
              ),
            ),
            ListTile(
              leading: _iconoMenu('configuracion'),
              title: const Text('Configuración'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConfiguracionScreen()),
              ),
            ),
            if (provider.esAdmin) ...[
              const SizedBox(height: 8),
              const Divider(),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'HERRAMIENTAS DEL EQUIPO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('Administración (reportes)'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdministracionScreen(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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
