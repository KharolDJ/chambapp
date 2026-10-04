import 'package:flutter/material.dart';

import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'main_nav_screen.dart';

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

    final tema = Theme.of(context);

    return Scaffold(
      appBar: yaTieneCuenta
          ? AppBar(title: const Text('Cambiar de modo'))
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Lottie.asset(
                      'assets/lottie/loader_cat.json',
                      height: 230,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Chambapp',
                      textAlign: TextAlign.center,
                      style: (tema.textTheme.headlineSmall ?? const TextStyle())
                          .copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: tema.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 32),
                    if (yaTieneCuenta) ...[
                      Center(
                        child: Text(
                          'Modo actual: ${provider.rolActual == RolUsuario.empleador ? 'Empleador' : 'Trabajador'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: tema.textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Text(
                      '¿Qué necesitas hoy?',
                      textAlign: TextAlign.center,
                      style: (tema.textTheme.titleLarge ?? const TextStyle())
                          .copyWith(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: tema.colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 28),
                    _BotonRol(
                      titulo: 'Buscar chamba',
                      relleno: true,
                      onTap: () =>
                          _seleccionarRol(context, RolUsuario.trabajador),
                    ),
                    const SizedBox(height: 14),
                    _BotonRol(
                      titulo: 'Busco un servicio',
                      relleno: false,
                      onTap: () =>
                          _seleccionarRol(context, RolUsuario.empleador),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BotonRol extends StatelessWidget {
  final String titulo;
  final bool relleno;
  final VoidCallback onTap;

  const _BotonRol({
    required this.titulo,
    required this.relleno,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final negro = esquema.onSurface;
    final blanco = esquema.surface;

    final estilo = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(54)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      side: WidgetStatePropertyAll(BorderSide(color: negro, width: 1.4)),
      backgroundColor: WidgetStatePropertyAll(relleno ? negro : blanco),
      foregroundColor: WidgetStatePropertyAll(relleno ? blanco : negro),
      overlayColor: WidgetStatePropertyAll(
        (relleno ? blanco : negro).withValues(alpha: 0.08),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      ),
      elevation: const WidgetStatePropertyAll(0),
    );

    return OutlinedButton(onPressed: onTap, style: estilo, child: Text(titulo));
  }
}
