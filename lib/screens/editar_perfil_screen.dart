import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

const _petroleo = Color(0xFF0F6E56);
const _mostazaTexto = Color(0xFFAD7A16);
const _papel = Color(0xFFFAF7F0);
const _grafito = Color(0xFF26312D);

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _celularController;
  final List<String> _oficiosSeleccionados = [];
  String? _fotoPath;
  bool _mostrarErrorOficios = false;

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

  @override
  void initState() {
    super.initState();
    final usuario = context.read<AppProvider>().usuarioActual!;
    _nombreController = TextEditingController(text: usuario.nombre);
    _celularController = TextEditingController(text: usuario.celular);
    _oficiosSeleccionados.addAll(usuario.oficios);
    _fotoPath = usuario.fotoPath;
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

  @override
  void dispose() {
    _nombreController.dispose();
    _celularController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final esTrabajador = context.read<AppProvider>().rolActual == RolUsuario.trabajador;
    if (esTrabajador && _oficiosSeleccionados.isEmpty) {
      setState(() => _mostrarErrorOficios = true);
      return;
    }
    context.read<AppProvider>().actualizarPerfil(
          nombre: _nombreController.text.trim(),
          celular: _celularController.text.trim(),
          oficios: _oficiosSeleccionados,
          fotoPath: _fotoPath,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado'), backgroundColor: _petroleo),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final esTrabajador = provider.rolActual == RolUsuario.trabajador;
    final correo = provider.usuarioActual?.correo ?? '';

    return Scaffold(
      backgroundColor: _papel,
      appBar: AppBar(
        title: const Text('Editar perfil'),
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
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nombreController,
                  decoration: _decoracion('Nombre completo', Icons.badge_outlined),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: correo,
                  enabled: false,
                  decoration: _decoracion(
                    'Correo electrónico',
                    Icons.email_outlined,
                    helper: 'Por ahora no se puede cambiar aquí',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _celularController,
                  keyboardType: TextInputType.phone,
                  decoration: _decoracion(
                    'Número de celular',
                    Icons.phone_outlined,
                    helper: 'Solo se usa para contactarte por WhatsApp',
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
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Servicios que ofreces (puedes elegir varios)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _grafito),
                    ),
                  ),
                  const SizedBox(height: 10),
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
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _petroleo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Guardar cambios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
