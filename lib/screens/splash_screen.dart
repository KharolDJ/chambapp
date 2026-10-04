import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../theme/app_colors.dart';

/// Pantalla de carga de marca, mostrada una sola vez al arranque en frío de
/// la app (ver [main.dart]). Reproduce la animación del gato una vez y
/// avisa mediante [onFinished] para que quien la use decida a qué pantalla
/// pasar — esta pantalla no navega por su cuenta, así el flujo reactivo de
/// `home:` en main.dart (rol nulo -> selector, si no -> feed) sigue siendo
/// la única fuente de verdad para adónde ir, incluido el logout.
class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _terminado = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    // Salvavidas: si el Lottie no carga (asset corrupto, etc.) la app no se
    // queda atascada en el splash para siempre.
    Future.delayed(const Duration(seconds: 5), _terminar);
  }

  void _terminar() {
    if (_terminado || !mounted) return;
    _terminado = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 220,
              child: Lottie.asset(
                'assets/lottie/cat_movement.json',
                controller: _controller,
                fit: BoxFit.contain,
                onLoaded: (composicion) {
                  _controller
                    ..duration = composicion.duration
                    ..forward();
                  Future.delayed(composicion.duration, _terminar);
                },
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 48,
              height: 3,
              decoration: BoxDecoration(
                // Negro de marca; en modo oscuro, blanco para que se vea.
                color: tema.brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.negroProfundo,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Chambapp',
              style: (tema.textTheme.headlineSmall ?? const TextStyle())
                  .copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: tema.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Más fácil, más rápido, más chamba.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontStyle: FontStyle.italic,
                color: tema.textTheme.bodySmall?.color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
