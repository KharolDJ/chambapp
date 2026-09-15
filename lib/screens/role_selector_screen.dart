import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'main_nav_screen.dart';

const _acento = AppColors.azulCeleste;
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
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _acento,
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
                    const SizedBox(height: 4),
                    Text(
                      'Elige tu perfil para empezar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: tema.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _HeroRolCard(
                      iconoAsset: 'assets/icon/taladro_de_mano.png',
                      titulo: 'Ofrezco un servicio',
                      subtitulo: 'Explora peticiones cerca de ti',
                      color: _acento,
                      colorClaro: const Color(0xFFE3F2EC),
                      onTap: () =>
                          _seleccionarRol(context, RolUsuario.trabajador),
                    ),
                    const SizedBox(height: 16),
                    _HeroRolCard(
                      iconoAsset: 'assets/icon/bloc_de_dibujo.png',
                      titulo: 'Busco un servicio',
                      subtitulo: 'Publica lo que necesitas',
                      color: _dorado,
                      colorClaro: const Color(0xFFFAEEDA),
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

class _HeroRolCard extends StatefulWidget {
  final String iconoAsset;
  final String titulo;
  final String subtitulo;
  final Color color;
  final Color colorClaro;
  final VoidCallback onTap;

  const _HeroRolCard({
    required this.iconoAsset,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.colorClaro,
    required this.onTap,
  });

  @override
  State<_HeroRolCard> createState() => _HeroRolCardState();
}

class _HeroRolCardState extends State<_HeroRolCard> {
  bool _hover = false;
  bool _presionado = false;

  bool get _activo => _hover || _presionado;

  void _actualizarHover(bool valor) {
    if (_hover != valor) setState(() => _hover = valor);
  }

  void _actualizarPresionado(bool valor) {
    if (_presionado != valor) setState(() => _presionado = valor);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      onHover: _actualizarHover,
      onTapDown: (_) => _actualizarPresionado(true),
      onTapCancel: () => _actualizarPresionado(false),
      onTapUp: (_) => _actualizarPresionado(false),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedScale(
        scale: _activo ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _activo ? widget.colorClaro : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.color.withValues(alpha: _activo ? 0.6 : 0.35),
            ),
            boxShadow: _activo
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: widget.colorClaro,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(widget.iconoAsset, fit: BoxFit.contain),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.titulo,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitulo,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, size: 20, color: widget.color),
            ],
          ),
        ),
      ),
    );
  }
}
