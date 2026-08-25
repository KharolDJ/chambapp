import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'register_screen.dart';

const _petroleo = Color(0xFF0F6E56);
const _mostazaTexto = Color(0xFFAD7A16);
const _papel = Color(0xFFFAF7F0);
const _grafito = Color(0xFF26312D);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  String? _errorCorreo;

  @override
  void dispose() {
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    if (!_formKey.currentState!.validate()) return;

    final correo = _correoController.text.trim();
    final provider = context.read<AppProvider>();
    final encontrado = provider.buscarPorCorreo(correo);

    if (encontrado != null) {
      provider.iniciarSesion(encontrado);
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _errorCorreo = 'No encontramos una cuenta con ese correo');
  }

  Future<void> _irARegistro() async {
    final registrado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterScreen(correoInicial: _correoController.text.trim()),
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
      backgroundColor: _papel,
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
        backgroundColor: _papel,
        foregroundColor: _grafito,
        elevation: 0,
      ),
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
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: _petroleo, borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.person_outline, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Ingresa con el correo que usaste antes',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {
                    if (_errorCorreo != null) setState(() => _errorCorreo = null);
                  },
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    errorText: _errorCorreo,
                    prefixIcon: const Icon(Icons.email_outlined, color: _mostazaTexto),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (value) {
                    final texto = value?.trim() ?? '';
                    final valido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto);
                    if (!valido) return 'Ingresa un correo válido';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _continuar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _petroleo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Continuar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                if (_errorCorreo != null) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: _irARegistro,
                      icon: const Icon(Icons.person_add_outlined, color: _petroleo),
                      label: const Text('Registrarme con este correo', style: TextStyle(color: _petroleo)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
