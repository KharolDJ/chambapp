import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'feed_screen.dart';
import 'actividad_screen.dart';
import 'notificaciones_screen.dart';
import 'perfil_screen.dart';
import 'publicar_screen.dart';
import 'login_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _indice = 0;

  final _pantallas = const [
    FeedScreen(),
    ActividadScreen(),
    NotificacionesScreen(),
    PerfilScreen(),
  ];

  Future<void> _abrirPublicar(BuildContext context) async {
    final provider = context.read<AppProvider>();

    if (provider.usuarioActual == null) {
      final autenticado = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (autenticado != true) return;
    }

    if (!context.mounted) return;
    if (!context.read<AppProvider>().correoVerificado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verifica tu correo antes de publicar — revisa tu perfil',
          ),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PublicarScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final esEmpleador = provider.rolActual == RolUsuario.empleador;
    final hayNotificacionesSinLeer = provider.notificacionesSinLeerCount > 0;

    if (provider.categoriaParaVerEnFeed != null && _indice != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _indice = 0);
      });
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(index: _indice, children: _pantallas),
      floatingActionButton: esEmpleador
          ? FloatingActionButton(
              backgroundColor: AppColors.azulCeleste,
              onPressed: () => _abrirPublicar(context),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: esEmpleador ? const CircularNotchedRectangle() : null,
        notchMargin: 8,
        padding: EdgeInsets.zero,
        child: SafeArea(
          child: esEmpleador
              ? Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _botonNav(
                              'assets/icon/nav_inicio.png',
                              'Inicio',
                              0,
                            ),
                          ),
                          Expanded(
                            child: _botonNav(
                              'assets/icon/nav_actividad.png',
                              'Actividad',
                              1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 56),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _botonNav(
                              'assets/icon/nav_avisos.png',
                              'Avisos',
                              2,
                              mostrarPunto: hayNotificacionesSinLeer,
                            ),
                          ),
                          Expanded(
                            child: _botonNav(
                              'assets/icon/nav_perfil.png',
                              'Perfil',
                              3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _botonNav(
                        'assets/icon/nav_inicio.png',
                        'Inicio',
                        0,
                      ),
                    ),
                    Expanded(
                      child: _botonNav(
                        'assets/icon/nav_actividad.png',
                        'Actividad',
                        1,
                      ),
                    ),
                    Expanded(
                      child: _botonNav(
                        'assets/icon/nav_avisos.png',
                        'Avisos',
                        2,
                        mostrarPunto: hayNotificacionesSinLeer,
                      ),
                    ),
                    Expanded(
                      child: _botonNav(
                        'assets/icon/nav_perfil.png',
                        'Perfil',
                        3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _botonNav(
    String iconoAsset,
    String texto,
    int indice, {
    bool mostrarPunto = false,
  }) {
    final activo = _indice == indice;
    final color = activo ? AppColors.azulCeleste : Colors.grey;
    return InkWell(
      onTap: () => setState(() => _indice = indice),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedOpacity(
                  opacity: activo ? 1 : 0.45,
                  duration: const Duration(milliseconds: 150),
                  child: Image.asset(iconoAsset, width: 24, height: 24),
                ),
                if (mostrarPunto)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB54834),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
