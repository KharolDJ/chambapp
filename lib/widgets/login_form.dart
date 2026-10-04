import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../screens/register_screen.dart';

// Celeste en vez de dorado — se pidió explícitamente para el enlace
// "¿No tienes cuenta? Regístrate" y de paso unifica los bordes de campo
// enfocados con el mismo acento. Un solo valor fijo (no una pareja
// claro/oscuro) porque este celeste ya tiene buen contraste sobre blanco
// Y sobre negro profundo (~4.1 y ~4.8), a diferencia del dorado que sí
// necesitaba una variante más clara para el tema oscuro.
const _acento = AppColors.celesteCategoria;

/// Formulario de inicio de sesión reutilizable: campos de correo y
/// contraseña, botón "Continuar" y el enlace a registro.
///
/// Se usa tal cual en `LoginScreen` (dentro de su propio Scaffold con
/// AppBar) y también incrustado directamente en la pestaña "Perfil" para
/// quien entra sin sesión — ahí no hay nada que "cerrar" al terminar, así
/// que [onExito] queda sin pasar y el `Provider` se encarga de refrescar
/// la pantalla sola cuando `usuarioActual` deja de ser null.
class LoginForm extends StatefulWidget {
  /// Se llama tras iniciar sesión (o registrarse) con éxito. En
  /// `LoginScreen` hace `Navigator.pop(true)`; incrustado en un lugar que
  /// no es una ruta empujada (como la pestaña Perfil) se deja en null.
  final VoidCallback? onExito;

  const LoginForm({super.key, this.onExito});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorCorreo;
  bool _enviando = false;

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _enviando = true;
      _errorCorreo = null;
    });

    final provider = context.read<AppProvider>();
    final error = await provider.iniciarSesionConFirebase(
      correo: _correoController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _enviando = false);

    if (error == null) {
      widget.onExito?.call();
      return;
    }

    setState(() => _errorCorreo = error);
  }

  Widget _iconoCampo(String asset) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SizedBox(
        width: 18,
        height: 18,
        child: Image.asset(asset, fit: BoxFit.contain),
      ),
    );
  }

  Future<void> _irARegistro() async {
    final registrado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RegisterScreen(correoInicial: _correoController.text.trim()),
      ),
    );
    if (registrado == true) {
      if (!mounted) return;
      widget.onExito?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Image.asset(
              'assets/icon/icon_foreground.png',
              width: 148,
              height: 148,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ingresa con el correo que usaste antes',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _correoController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) {
              if (_errorCorreo != null) {
                setState(() => _errorCorreo = null);
              }
            },
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              errorText: _errorCorreo,
              prefixIcon: _iconoCampo('assets/icon/correo.png'),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _acento, width: 1.5),
              ),
              errorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFB54834)),
              ),
              focusedErrorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFB54834), width: 1.5),
              ),
            ),
            validator: (value) {
              final texto = value?.trim() ?? '';
              final valido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                  .hasMatch(texto);
              if (!valido) return 'Ingresa un correo válido';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: _iconoCampo('assets/icon/contrasena.png'),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _acento, width: 1.5),
              ),
            ),
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'Ingresa tu contraseña (mínimo 6 caracteres)';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _enviando ? null : _continuar,
            style: ElevatedButton.styleFrom(
              backgroundColor: esOscuro
                  ? Colors.white
                  : AppColors.negroProfundo,
              foregroundColor: esOscuro
                  ? AppColors.negroProfundo
                  : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _enviando
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: esOscuro ? AppColors.negroProfundo : Colors.white,
                    ),
                  )
                : const Text(
                    'Continuar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _irARegistro,
              icon: const Icon(Icons.person_add_outlined, color: _acento),
              label: const Text(
                '¿No tienes cuenta? Regístrate',
                style: TextStyle(color: _acento),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
