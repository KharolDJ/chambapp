import 'package:flutter/material.dart';
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

  final _pantallas = const [FeedScreen(), ActividadScreen(), NotificacionesScreen(), PerfilScreen()];

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
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PublicarScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final esEmpleador = provider.rolActual == RolUsuario.empleador;
    final hayNotificacionesSinLeer = provider.notificacionesSinLeerCount > 0;

    return Scaffold(
      body: _pantallas[_indice],
      floatingActionButton: esEmpleador
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF0F6E56),
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
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _botonNav(Icons.home_outlined, 'Inicio', 0),
                          _botonNav(Icons.list_alt_outlined, 'Actividad', 1),
                        ],
                      ),
                    ),
                    const SizedBox(width: 56),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _botonNav(Icons.notifications_outlined, 'Avisos', 2, mostrarPunto: hayNotificacionesSinLeer),
                          _botonNav(Icons.person_outline, 'Perfil', 3),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _botonNav(Icons.home_outlined, 'Inicio', 0),
                    _botonNav(Icons.list_alt_outlined, 'Actividad', 1),
                    _botonNav(Icons.notifications_outlined, 'Avisos', 2, mostrarPunto: hayNotificacionesSinLeer),
                    _botonNav(Icons.person_outline, 'Perfil', 3),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _botonNav(IconData icono, String texto, int indice, {bool mostrarPunto = false}) {
    final activo = _indice == indice;
    final color = activo ? const Color(0xFF0F6E56) : Colors.grey;
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
                Icon(icono, color: color, size: 24),
                if (mostrarPunto)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Color(0xFFB54834), shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            Text(texto, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
