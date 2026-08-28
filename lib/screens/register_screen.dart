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

enum _TipoPaso { nombre, correo, oficios, datosFinales }

class RegisterScreen extends StatefulWidget {
  final String? correoInicial;

  const RegisterScreen({super.key, this.correoInicial});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nombreController = TextEditingController();
  late final TextEditingController _correoController;
  final _celularController = TextEditingController();
  final _cedulaController = TextEditingController();

  final List<String> _oficiosSeleccionados = [];
  String? _fotoPath;

  int _paso = 0;
  late final bool _esTrabajador;

  String? _errorNombre;
  String? _errorCorreo;
  bool _mostrarErrorOficios = false;
  String? _errorCelular;

  final List<String> _servicios = [
    'Plomería',
    'Electricidad',
    'Cocina',
    'Carpintería',
    'Jardinería',
    'Limpieza del hogar',
    'Pintura',
    'Albañilería',
    'Cerrajería',
    'Acarreos',
  ];

  List<_TipoPaso> get _pasos => _esTrabajador
      ? [_TipoPaso.nombre, _TipoPaso.correo, _TipoPaso.oficios, _TipoPaso.datosFinales]
      : [_TipoPaso.nombre, _TipoPaso.correo, _TipoPaso.datosFinales];

  @override
  void initState() {
    super.initState();
    _esTrabajador = context.read<AppProvider>().rolActual == RolUsuario.trabajador;
    _correoController = TextEditingController(text: widget.correoInicial ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _celularController.dispose();
    _cedulaController.dispose();
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

  void _atras() {
    if (_paso > 0) {
      setState(() => _paso -= 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _siguiente() {
    final tipo = _pasos[_paso];

    if (tipo == _TipoPaso.nombre) {
      if (_nombreController.text.trim().isEmpty) {
        setState(() => _errorNombre = 'Ingresa tu nombre');
        return;
      }
      setState(() {
        _errorNombre = null;
        _paso += 1;
      });
      return;
    }

    if (tipo == _TipoPaso.correo) {
      final texto = _correoController.text.trim();
      final valido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto);
      if (!valido) {
        setState(() => _errorCorreo = 'Ingresa un correo válido');
        return;
      }
      setState(() {
        _errorCorreo = null;
        _paso += 1;
      });
      return;
    }

    if (tipo == _TipoPaso.oficios) {
      if (_oficiosSeleccionados.isEmpty) {
        setState(() => _mostrarErrorOficios = true);
        return;
      }
      setState(() {
        _mostrarErrorOficios = false;
        _paso += 1;
      });
      return;
    }

    // datosFinales: paso final, envía el formulario.
    final texto = _celularController.text.trim();
    if (!RegExp(r'^\d{7,15}$').hasMatch(texto)) {
      setState(() => _errorCelular = 'Ingresa solo números (7 a 15 dígitos)');
      return;
    }

    final provider = context.read<AppProvider>();
    final usuario = Usuario(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: _nombreController.text.trim(),
      correo: _correoController.text.trim(),
      celular: texto,
      oficios: _esTrabajador ? _oficiosSeleccionados : null,
      fotoPath: _fotoPath,
      cedula: _cedulaController.text.trim().isEmpty ? null : _cedulaController.text.trim(),
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
    final pasos = _pasos;
    final tipo = pasos[_paso];
    final esUltimoPaso = _paso == pasos.length - 1;

    return Scaffold(
      backgroundColor: _papel,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _atras),
        title: const Text('Crear tu cuenta'),
        backgroundColor: _papel,
        foregroundColor: _grafito,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_paso + 1) / pasos.length,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE1F5EE),
                  color: _petroleo,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Paso ${_paso + 1} de ${pasos.length}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(tipo),
                      child: _construirPaso(tipo),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _siguiente,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _petroleo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  esUltimoPaso ? 'Registrarme' : 'Continuar',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (_paso == 0) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _irALogin,
                    child: const Text('¿Ya tienes cuenta? Inicia sesión', style: TextStyle(color: _mostazaTexto)),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirPaso(_TipoPaso tipo) {
    switch (tipo) {
      case _TipoPaso.nombre:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '¿Cómo te llamas?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _grafito),
            ),
            const SizedBox(height: 8),
            Text('Cuéntanos tu nombre completo para tu perfil.', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            TextField(
              controller: _nombreController,
              autofocus: true,
              decoration: _decoracion('Nombre completo', Icons.badge_outlined, error: _errorNombre),
              onChanged: (_) {
                if (_errorNombre != null) setState(() => _errorNombre = null);
              },
            ),
          ],
        );

      case _TipoPaso.correo:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '¿Cuál es tu correo?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _grafito),
            ),
            const SizedBox(height: 8),
            Text('Lo usaremos para verificar tu cuenta.', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            TextField(
              controller: _correoController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: _decoracion('Correo electrónico', Icons.email_outlined, error: _errorCorreo),
              onChanged: (_) {
                if (_errorCorreo != null) setState(() => _errorCorreo = null);
              },
            ),
          ],
        );

      case _TipoPaso.oficios:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '¿En qué trabajas?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _grafito),
            ),
            const SizedBox(height: 8),
            Text('Elige uno o varios oficios que sepas hacer.', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 20),
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
        );

      case _TipoPaso.datosFinales:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ya casi terminamos',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _grafito),
            ),
            const SizedBox(height: 8),
            Text('Tu celular y una foto de perfil (opcional).', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _elegirFoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: const Color(0xFFE1F5EE),
                      backgroundImage: _fotoPath != null ? FileImage(File(_fotoPath!)) : null,
                      child: _fotoPath == null ? const Icon(Icons.person, size: 60, color: _petroleo) : null,
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
            const SizedBox(height: 24),
            TextField(
              controller: _celularController,
              keyboardType: TextInputType.phone,
              decoration: _decoracion(
                'Número de celular',
                Icons.phone_outlined,
                helper: 'Solo se usa para contactarte por WhatsApp, nunca se muestra públicamente',
                error: _errorCelular,
              ),
              onChanged: (_) {
                if (_errorCelular != null) setState(() => _errorCelular = null);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cedulaController,
              keyboardType: TextInputType.number,
              decoration: _decoracion(
                'Documento de identidad (opcional)',
                Icons.badge_outlined,
                helper: 'Ayuda a generar más confianza en tu perfil',
              ),
            ),
          ],
        );
    }
  }

  InputDecoration _decoracion(String label, IconData icono, {String? helper, String? error}) {
    return InputDecoration(
      labelText: label,
      helperText: error == null ? helper : null,
      errorText: error,
      prefixIcon: Icon(icono, color: _mostazaTexto),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}
