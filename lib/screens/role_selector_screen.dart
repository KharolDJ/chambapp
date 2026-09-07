import 'package:flutter/material.dart';
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
              SizedBox(height: yaTieneCuenta ? 12 : 32),
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_petroleo, Color(0xFF0B5344)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: _petroleo.withValues(alpha: 0.32), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Image.asset('assets/icon/icon_foreground.png'),
                ),
              ),
              const SizedBox(height: 18),
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
              const SizedBox(height: 8),
              const Text(
                'Servicios de tu barrio, gente de confianza',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _subtitulo),
              ),
              const Spacer(flex: 3),
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
                icono: Icons.build_outlined,
                titulo: 'Ofrezco un servicio',
                subtitulo: 'Explora peticiones cerca de ti',
                color: _petroleo,
                colorFondo: const Color(0xFFE3F2EC),
                onTap: () => _seleccionarRol(context, RolUsuario.trabajador),
              ),
              const SizedBox(height: 16),
              _HeroRolCard(
                icono: Icons.search_outlined,
                titulo: 'Busco un servicio',
                subtitulo: 'Publica lo que necesitas',
                color: _dorado,
                colorFondo: const Color(0xFFFAEEDA),
                onTap: () => _seleccionarRol(context, RolUsuario.empleador),
              ),
              const Spacer(flex: 4),
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
  final Color colorFondo;
  final VoidCallback onTap;

  const _HeroRolCard({
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
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 22, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.22), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Icon(icono, size: 28, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitulo, style: const TextStyle(fontSize: 13, color: _subtitulo)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, size: 22, color: color.withValues(alpha: 0.55)),
          ],
        ),
      ),
    );
  }
}
