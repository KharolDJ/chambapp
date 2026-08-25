import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'privacidad_screen.dart';

const _petroleo = Color(0xFF0F6E56);
const _ladrillo = Color(0xFFB54834);
const _papel = Color(0xFFFAF7F0);
const _grafito = Color(0xFF26312D);

class ConfiguracionScreen extends StatelessWidget {
  const ConfiguracionScreen({super.key});

  Future<void> _confirmarEliminarCuenta(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text('¿Seguro que quieres eliminar tu cuenta? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: _ladrillo)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    if (!context.mounted) return;
    context.read<AppProvider>().eliminarCuentaActual();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _cerrarSesion(BuildContext context) {
    context.read<AppProvider>().cerrarSesion();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: _papel,
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: _papel,
        foregroundColor: _grafito,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Preferencias de la app', style: TextStyle(fontWeight: FontWeight.bold, color: _grafito)),
          ),
          SwitchListTile(
            value: provider.notificacionesActivas,
            onChanged: (v) => context.read<AppProvider>().actualizarNotificaciones(v),
            title: const Text('Notificaciones de actividad'),
            subtitle: const Text('Avisa cuando cambia la etapa de una de tus aplicaciones'),
            activeThumbColor: _petroleo,
          ),
          ListTile(
            title: const Text('Radio de búsqueda del feed'),
            subtitle: Text('Mostrar peticiones hasta ${provider.radioBusquedaKm.toStringAsFixed(0)} km'),
            trailing: DropdownButton<double>(
              value: provider.radioBusquedaKm,
              items: const [1, 3, 5, 10, 20]
                  .map((km) => DropdownMenuItem(value: km.toDouble(), child: Text('$km km')))
                  .toList(),
              onChanged: (v) {
                if (v != null) context.read<AppProvider>().actualizarRadioBusqueda(v);
              },
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Cuenta', style: TextStyle(fontWeight: FontWeight.bold, color: _grafito)),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Política de privacidad'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacidadScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            enabled: provider.usuarioActual != null,
            onTap: provider.usuarioActual == null ? null : () => _cerrarSesion(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: _ladrillo),
            title: const Text('Eliminar cuenta', style: TextStyle(color: _ladrillo)),
            enabled: provider.usuarioActual != null,
            onTap: provider.usuarioActual == null ? null : () => _confirmarEliminarCuenta(context),
          ),
        ],
      ),
    );
  }
}
