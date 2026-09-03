import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'main_nav_screen.dart';
import 'role_selector_screen.dart';

/// Pantalla de entrada animada — se muestra justo después del splash nativo
/// del sistema operativo (mismo color de fondo, #0A656D, para que la
/// transición entre ambos sea sin salto de color) y navega automáticamente
/// al feed o al selector de rol una vez termina la animación.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _duracionAnimacion = Duration(milliseconds: 900);
  static const _duracionTotal = Duration(milliseconds: 1700);

  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // Arranca en el siguiente frame para que el estado inicial (invisible,
    // escala reducida) se pinte primero, y así AnimatedOpacity/AnimatedScale
    // tengan un punto de partida real desde el cual animar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _visible = true);
    });
    Future.delayed(_duracionTotal, _irASiguientePantalla);
  }

  void _irASiguientePantalla() {
    if (!mounted) return;
    final provider = context.read<AppProvider>();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => provider.rolActual == null ? const RoleSelectorScreen() : const MainNavScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A656D),
      body: Center(
        child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: _duracionAnimacion,
          curve: Curves.easeOut,
          child: AnimatedScale(
            scale: _visible ? 1 : 0.6,
            duration: _duracionAnimacion,
            curve: Curves.easeOutBack,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/icon/icon_foreground.png', width: 110, height: 110),
                const SizedBox(height: 18),
                Text(
                  'chambapp',
                  style: GoogleFonts.sora(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
