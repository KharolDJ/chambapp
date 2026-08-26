import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/usuario.dart';
import '../providers/app_provider.dart';
import 'login_screen.dart';

const _petroleo = Color(0xFF0F6E56);
const _mostazaTexto = Color(0xFFAD7A16);
const _papel = Color(0xFFFAF7F0);
const _grafito = Color(0xFF26312D);

class RegisterScreen extends StatefulWidget {
  final String? correoInicial;

  const RegisterScreen({super.key, this.correoInicial});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  late final TextEditingController _correoController;
  final _celularController = TextEditingController();

  final List<String> _oficiosSeleccionados = [];
  String? _fotoPath;

  final List<String> _servicios = [
    'Plomería',
    'Electricidad',
    'Cocina',
    'Carpintería',
    'Jardinería',
    'Limpieza del hogar',
    'Pintura',
  ];

  @override
  void initState() {
    super.initState();
    _correoController = TextEditingController(text: widget.correoInicial ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _celularController.dispose();
    super.dispose();
  }

  Future<void> _elegirFoto() async {
    final origen = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (origen == null) return;

    final archivo = await ImagePicker().pickImage(source: origen, maxWidth: 800, imageQuality: 80);
    if (archivo == null) return;
    setState(() => _fotoPath = archivo.path);
  }

  bool _mostrarErrorOficios = false;

  void _enviarFormulario() {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AppProvider>();
    final esTrabajador = provider.rolActual == RolUsuario.trabajador;

    if (esTrabajador && _oficiosSeleccionados.isEmpty) {
      setState(() => _mostrarErrorOficios = true);
      return;
    }

    final usuario = Usuario(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: _nombreController.text.trim(),
      correo: _correoController.text.trim(),
      celular: _celularController.text.trim(),
      oficios: esTrabajador ? _oficiosSeleccionados : null,
      fotoPath: _fotoPath,
    );

    provider.registrarUsuario(usuario);
    Navigator.of(context).pop(true);
  }

  Future<void> _irALogin() async {
    final autenticado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (autenticado == true) {
      if (!mounted) return;
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esTrabajador = context.watch<AppProvider>().rolActual == RolUsuario.trabajador;

    return Scaffold(
      backgroundColor: _papel,
      appBar: AppBar(
        title: const Text('Completa tu registro'),
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
                  child: GestureDetector(
                    onTap: _elegirFoto,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: const Color(0xFFE1F5EE),
                          backgroundImage: _fotoPath != null ? FileImage(File(_fotoPath!)) : null,
                          child: _fotoPath == null
                              ? const Icon(Icons.person, size: 60, color: _petroleo)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _petroleo,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'Datos personales',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _grafito),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _nombreController,
                  decoration: _decoracion('Nombre completo', Icons.badge_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decoracion(
                    'Correo electrónico',
                    Icons.email_outlined,
                    helper: 'Se usará para verificar tu cuenta',
                  ),
                  validator: (value) {
                    final texto = value?.trim() ?? '';
                    final valido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto);
                    if (!valido) return 'Ingresa un correo válido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _celularController,
                  keyboardType: TextInputType.phone,
                  decoration: _decoracion(
                    'Número de celular',
                    Icons.phone_outlined,
                    helper: 'Solo se usa para contactarte por WhatsApp, nunca se muestra públicamente',
                  ),
                  validator: (value) {
                    final texto = value?.trim() ?? '';
                    if (!RegExp(r'^\d{7,15}$').hasMatch(texto)) {
                      return 'Ingresa solo números (7 a 15 dígitos)';
                    }
                    return null;
                  },
                ),

                if (esTrabajador) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Servicios que ofreces (puedes elegir varios)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _grafito),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _servicios.map((servicio) {
                      final seleccionado = _oficiosSeleccionados.contains(servicio);
                      return FilterChip(
                        label: Text(servicio),
                        selected: seleccionado,
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _oficiosSeleccionados.add(servicio);
                            } else {
                              _oficiosSeleccionados.remove(servicio);
                            }
                            _mostrarErrorOficios = false;
                          });
                        },
                        selectedColor: _petroleo.withValues(alpha: 0.18),
                        checkmarkColor: _petroleo,
                        labelStyle: TextStyle(color: seleccionado ? _petroleo : _grafito),
                        side: BorderSide(color: seleccionado ? _petroleo : Colors.grey.shade300),
                        backgroundColor: Colors.white,
                      );
                    }).toList(),
                  ),
                  if (_mostrarErrorOficios)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Selecciona al menos un servicio',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _enviarFormulario,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _petroleo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Registrarme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _irALogin,
                    child: const Text('¿Ya tienes cuenta? Inicia sesión', style: TextStyle(color: _mostazaTexto)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoracion(String label, IconData icono, {String? helper}) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      prefixIcon: Icon(icono, color: _mostazaTexto),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}
