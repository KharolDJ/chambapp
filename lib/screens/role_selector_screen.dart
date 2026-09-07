import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'main_nav_screen.dart';

const _fondo = Color(0xFFF9F9FB);
const _tituloOscuro = Color(0xFF1A1A1A);
const _subtitulo = Color(0xFF666666);
const _petroleo = Color(0xFF0F6E56);
const _dorado = Color(0xFFAD7A16);

class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({super.key});

  void _seleccionarRol(BuildContext context, RolUsuario rol) {
    context.read<AppProvider>().seleccionarRol(rol);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final yaTieneCuenta = provider.usuarioActual != null;

    return Scaffold(
      backgroundColor: _fondo,
      appBar: yaTieneCuenta
          ? AppBar(
              title: const Text('Cambiar de modo'),
              backgroundColor: _fondo,
              elevation: 0,
              foregroundColor: _tituloOscuro,
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: yaTieneCuenta ? 12 : 24),
              Lottie.asset(
                'assets/lottie/loader_cat.json',
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              Text(
                'Chambapp',
                textAlign: TextAlign.center,
                style: (Theme.of(context).textTheme.headlineSmall ?? const TextStyle()).copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _tituloOscuro,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(flex: 4),
              if (yaTieneCuenta) ...[
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _petroleo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Modo actual: ${provider.rolActual == RolUsuario.empleador ? 'Empleador' : 'Trabajador'}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _petroleo),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                '¿Qué necesitas hoy?',
                textAlign: TextAlign.center,
                style: (Theme.of(context).textTheme.titleLarge ?? const TextStyle()).copyWith(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: _tituloOscuro,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Elige tu perfil para empezar',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _subtitulo),
              ),
              const SizedBox(height: 24),
              _HeroRolCard(
                icono: Icons.engineering_rounded,
                titulo: 'Ofrezco un servicio',
                subtitulo: 'Explora peticiones cerca de ti',
                color: _petroleo,
                colorClaro: const Color(0xFFE3F2EC),
                onTap: () => _seleccionarRol(context, RolUsuario.trabajador),
              ),
              const SizedBox(height: 16),
              _HeroRolCard(
                icono: Icons.search_rounded,
                titulo: 'Busco un servicio',
                subtitulo: 'Publica lo que necesitas',
                color: _dorado,
                colorClaro: const Color(0xFFFAEEDA),
                onTap: () => _seleccionarRol(context, RolUsuario.empleador),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroRolCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color color;
  final Color colorClaro;
  final VoidCallback onTap;

  const _HeroRolCard({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.colorClaro,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colorClaro,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, size: 24, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _tituloOscuro),
                  ),
                  const SizedBox(height: 3),
                  Text(subtitulo, style: const TextStyle(fontSize: 13, color: _subtitulo)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, size: 20, color: color),
          ],
        ),
      ),
    );
  }
}
