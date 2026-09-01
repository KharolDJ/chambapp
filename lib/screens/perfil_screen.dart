import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'administracion_screen.dart';
import 'configuracion_screen.dart';
import 'editar_perfil_screen.dart';
import 'login_screen.dart';
import 'mis_calificaciones_screen.dart';
import 'premium_trabajador_screen.dart';
import 'role_selector_screen.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final usuario = provider.usuarioActual;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        title: const Text('Mi perfil'),
        backgroundColor: const Color(0xFFFAF7F0),
        foregroundColor: const Color(0xFF26312D),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: const Color(0xFFE1F5EE),
              backgroundImage: usuario?.fotoPath != null ? FileImage(File(usuario!.fotoPath!)) : null,
              child: usuario?.fotoPath == null
                  ? const Icon(Icons.person, size: 50, color: Color(0xFF0F6E56))
                  : null,
            ),
            const SizedBox(height: 14),
            Text(
              usuario?.nombre ?? 'Aún no te has registrado',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              provider.rolActual == RolUsuario.empleador ? 'Empleador' : 'Trabajador',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (usuario != null) ...[
              const SizedBox(height: 6),
              if (usuario.numeroCalificaciones > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, size: 16, color: Color(0xFFAD7A16)),
                    const SizedBox(width: 4),
                    Text(
                      '${usuario.calificacionPromedio.toStringAsFixed(1)} (${usuario.numeroCalificaciones} calificaciones)',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFFAEEDA), borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: Color(0xFFAD7A16)),
                      SizedBox(width: 4),
                      Text(
                        'Nuevo en la plataforma',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFAD7A16)),
                      ),
                    ],
                  ),
                ),
              if (usuario.cedula != null && usuario.cedula!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.badge_outlined, size: 13, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text('Documento registrado', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              if (usuario.oficios.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Oficios: ${usuario.oficios.join(', ')}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ),
            ] else ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                icon: const Icon(Icons.login),
                label: const Text('Iniciar sesión o registrarme'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F6E56),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Mis calificaciones'),
              enabled: usuario != null,
              onTap: usuario == null
                  ? null
                  : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MisCalificacionesScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar perfil'),
              enabled: usuario != null,
              onTap: usuario == null
                  ? null
                  : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditarPerfilScreen())),
            ),
            if (provider.rolActual == RolUsuario.trabajador && usuario != null && usuario.oficios.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('Visibilidad Premium'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumTrabajadorScreen())),
              ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Cambiar de modo (Empleador/Trabajador)'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoleSelectorScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configuración'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfiguracionScreen())),
            ),
            if (provider.esAdmin)
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('Administración (reportes)'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdministracionScreen())),
              ),
          ],
        ),
      ),
    );
  }
}
