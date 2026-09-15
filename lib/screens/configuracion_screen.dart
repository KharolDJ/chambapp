import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'privacidad_screen.dart';

const _acento = AppColors.azulCeleste;
const _ladrillo = Color(0xFFB54834);

class ConfiguracionScreen extends StatelessWidget {
  const ConfiguracionScreen({super.key});

  Future<void> _confirmarEliminarCuenta(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          '¿Seguro que quieres eliminar tu cuenta? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: _ladrillo)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    if (!context.mounted) return;
    final error = await context.read<AppProvider>().eliminarCuentaActual();
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    await context.read<AppProvider>().cerrarSesion();
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _TituloSeccion('Apariencia'),
          _TarjetaSeccion(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tema',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: tema.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Claro'),
                          icon: Icon(Icons.light_mode_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Oscuro'),
                          icon: Icon(Icons.dark_mode_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('Auto'),
                          icon: Icon(Icons.brightness_auto_outlined, size: 16),
                        ),
                      ],
                      selected: {provider.temaPreferido},
                      onSelectionChanged: (seleccion) => context
                          .read<AppProvider>()
                          .actualizarTema(seleccion.first),
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: _acento,
                        selectedForegroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _TituloSeccion('Preferencias de la app'),
          _TarjetaSeccion(
            children: [
              _FilaSwitch(
                iconoAsset: 'assets/icon/nav_avisos.png',
                titulo: 'Notificaciones de actividad',
                subtitulo:
                    'Avisa cuando cambia la etapa de una de tus aplicaciones',
                valor: provider.notificacionesActivas,
                onChanged: (v) =>
                    context.read<AppProvider>().actualizarNotificaciones(v),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'El radio de búsqueda ahora se ajusta directo desde el feed ("Cerca de ti").',
              style: TextStyle(
                fontSize: 12,
                color: tema.textTheme.bodySmall?.color,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _TituloSeccion('Cuenta'),
          _TarjetaSeccion(
            children: [
              _FilaAccion(
                iconoAsset: 'assets/icon/proteger.png',
                titulo: 'Política de privacidad',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacidadScreen()),
                ),
              ),
              _divisor(),
              _FilaAccion(
                iconoAsset: 'assets/icon/cerrar_sesion.png',
                titulo: 'Cerrar sesión',
                habilitado: provider.usuarioActual != null,
                onTap: () => _cerrarSesion(context),
              ),
              _divisor(),
              _FilaAccion(
                iconoAsset: 'assets/icon/borrar.png',
                titulo: 'Eliminar cuenta',
                tituloColor: _ladrillo,
                habilitado: provider.usuarioActual != null,
                onTap: () => _confirmarEliminarCuenta(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divisor() => Divider(height: 1, indent: 62);
}

class _TituloSeccion extends StatelessWidget {
  final String texto;
  const _TituloSeccion(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _TarjetaSeccion extends StatelessWidget {
  final List<Widget> children;
  const _TarjetaSeccion({required this.children});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tema.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tema.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: tema.brightness == Brightness.dark ? 0.2 : 0.04,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _FilaSwitch extends StatelessWidget {
  final String iconoAsset;
  final String titulo;
  final String subtitulo;
  final bool valor;
  final ValueChanged<bool> onChanged;

  const _FilaSwitch({
    required this.iconoAsset,
    required this.titulo,
    required this.subtitulo,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: tema.dividerColor.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Image.asset(iconoAsset, fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tema.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: TextStyle(
                    fontSize: 12,
                    color: tema.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: valor, onChanged: onChanged, activeThumbColor: _acento),
        ],
      ),
    );
  }
}

class _FilaAccion extends StatelessWidget {
  final String iconoAsset;
  final String titulo;
  final Color? tituloColor;
  final bool habilitado;
  final VoidCallback onTap;

  const _FilaAccion({
    required this.iconoAsset,
    required this.titulo,
    this.tituloColor,
    this.habilitado = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return InkWell(
      onTap: habilitado ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Opacity(
          opacity: habilitado ? 1 : 0.4,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tema.dividerColor.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(iconoAsset, fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tituloColor ?? tema.colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: tema.textTheme.bodySmall?.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
