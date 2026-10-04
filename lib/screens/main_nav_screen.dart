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

// Fondo de la barra de navegación: un gris propio, distinto tanto del fondo
// de página como del negro puro del tema oscuro, para que la barra se lea
// como su propia superficie ("un grisito más oscuro y elegante").
const _fondoBarraClaro = Color(0xFFE3E3E3);
const _fondoBarraOscuro = Color(0xFF232323);

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
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

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
              // Botón de acción principal → negro/blanco, no el dorado de
              // acento (igual que el resto de los botones de acción).
              backgroundColor: esOscuro ? Colors.white : AppColors.negroProfundo,
              onPressed: () => _abrirPublicar(context),
              child: Icon(
                Icons.add,
                color: esOscuro ? AppColors.negroProfundo : Colors.white,
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: esOscuro ? _fondoBarraOscuro : _fondoBarraClaro,
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
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    // Activo en negro (o blanco en oscuro) para resaltar nítido sobre la
    // barra gris — ya no en dorado, que queda como acento de detalle en
    // otras partes de la app, no en la navegación principal.
    final color = activo
        ? (esOscuro ? Colors.white : AppColors.negroProfundo)
        : (esOscuro ? const Color(0xFF8A8A8A) : Colors.grey.shade600);
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
                  // Los íconos nuevos son de un solo trazo (negro sólido),
                  // así que se tiñen del mismo color que la etiqueta de
                  // texto — antes eran PNG multicolor y no se podían teñir.
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                    child: Image.asset(iconoAsset, width: 24, height: 24),
                  ),
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
