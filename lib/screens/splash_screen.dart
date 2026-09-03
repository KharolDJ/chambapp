import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'main_nav_screen.dart';
import 'role_selector_screen.dart';

/// Pantalla de entrada: tarjeta redondeada con el isotipo sobre fondo
/// petróleo, con un detalle sutil en mostaza. Sin splash nativo del sistema
/// (se quitó aparte) — esta es la primera pantalla que ve el usuario.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _petroleo = Color(0xFF0F6E56);
  static const _mostaza = Color(0xFFD9A441);
  static const _papel = Color(0xFFFAF7F0);

  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _visible = true);
    });
    Future.delayed(const Duration(milliseconds: 2000), _irASiguientePantalla);
  }

  void _irASiguientePantalla() {
    if (!mounted) return;
    final provider = context.read<AppProvider>();
    final siguiente = provider.rolActual == null ? const RoleSelectorScreen() : const MainNavScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, _) => FadeTransition(opacity: animation, child: siguiente),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _petroleo,
      body: Center(
        child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 148,
                height: 148,
                padding: const EdgeInsets.all(34),
                decoration: BoxDecoration(
                  color: _papel,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: _mostaza, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Image.asset('assets/icon/mark_petroleo.png'),
              ),
              const SizedBox(height: 22),
              Text(
                'chambapp',
                style: GoogleFonts.sora(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
