import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'register_screen.dart';

const _acento = AppColors.azulCeleste;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
      Navigator.of(context).pop(true);
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
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _acento,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _acento.withValues(alpha: 0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Image.asset('assets/icon/icon_foreground.png'),
                  ),
                ),
                const SizedBox(height: 24),
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
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: _acento, width: 1.5),
                    ),
                    errorBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFB54834)),
                    ),
                    focusedErrorBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFFB54834),
                        width: 1.5,
                      ),
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
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
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
                    backgroundColor: _acento,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _enviando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Continuar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
          ),
        ),
      ),
    );
  }
}
