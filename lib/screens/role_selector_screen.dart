import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'main_nav_screen.dart';

class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({super.key});

  void _seleccionarRol(BuildContext context, RolUsuario rol) {
    context.read<AppProvider>().seleccionarRol(rol);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: const Color(0xFF0F6E56), borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.handyman_outlined, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Chambapp', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF26312D))),
              const SizedBox(height: 6),
              Text('Servicios de tu barrio, gente de confianza', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              const SizedBox(height: 48),
              Text('¿Qué necesitas hoy?', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
              const SizedBox(height: 16),
              _RolCard(
                icono: Icons.build_outlined,
                titulo: 'Ofrezco un servicio',
                subtitulo: 'Explora peticiones cerca de ti',
                color: const Color(0xFF0F6E56),
                colorFondo: const Color(0xFFE1F5EE),
                onTap: () => _seleccionarRol(context, RolUsuario.trabajador),
              ),
              const SizedBox(height: 14),
              _RolCard(
                icono: Icons.search_outlined,
                titulo: 'Busco un servicio',
                subtitulo: 'Publica lo que necesitas',
                color: const Color(0xFFAD7A16),
                colorFondo: const Color(0xFFFAEEDA),
                onTap: () => _seleccionarRol(context, RolUsuario.empleador),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RolCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color color;
  final Color colorFondo;
  final VoidCallback onTap;

  const _RolCard({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.colorFondo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: colorFondo, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(icono, size: 30, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
                  const SizedBox(height: 2),
                  Text(subtitulo, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}