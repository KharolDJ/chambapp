import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../widgets/color_avatar.dart';

const _acento = AppColors.azulCeleste;

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _celularController;
  late final TextEditingController _cedulaController;
  late final TextEditingController _barrioController;
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

  // Mismos assets ya usados como categoría en el feed/registro — un solo
  // ícono representa el mismo oficio en toda la app.
  static const Map<String, String> _iconosCategoria = {
    'Plomería': 'assets/icon/plomeria.png',
    'Electricidad': 'assets/icon/electricidad.png',
    'Cocina': 'assets/icon/cocina.png',
    'Carpintería': 'assets/icon/carpinteria.png',
    'Jardinería': 'assets/icon/jardineria.png',
    'Limpieza del hogar': 'assets/icon/limpieza.png',
    'Pintura': 'assets/icon/pintura.png',
    'Albañilería': 'assets/icon/albanileria.png',
    'Cerrajería': 'assets/icon/cerrajeria.png',
    'Acarreos': 'assets/icon/acarreos.png',
  };

  @override
  void initState() {
    super.initState();
    final usuario = context.read<AppProvider>().usuarioActual!;
    _nombreController = TextEditingController(text: usuario.nombre);
    _celularController = TextEditingController(text: usuario.celular);
    _cedulaController = TextEditingController(text: usuario.cedula ?? '');
    _barrioController = TextEditingController(text: usuario.barrio ?? '');
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

    final archivo = await ImagePicker().pickImage(
      source: origen,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (archivo == null) return;
    setState(() => _fotoPath = archivo.path);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _celularController.dispose();
    _cedulaController.dispose();
    _barrioController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final esTrabajador =
        context.read<AppProvider>().rolActual == RolUsuario.trabajador;
    if (esTrabajador && _oficiosSeleccionados.isEmpty) {
      setState(() => _mostrarErrorOficios = true);
      return;
    }
    context.read<AppProvider>().actualizarPerfil(
      nombre: _nombreController.text.trim(),
      celular: _celularController.text.trim(),
      oficios: _oficiosSeleccionados,
      fotoPath: _fotoPath,
      cedula: _cedulaController.text.trim(),
      barrio: _barrioController.text.trim(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perfil actualizado'),
        backgroundColor: _acento,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final esTrabajador = provider.rolActual == RolUsuario.trabajador;
    final correo = provider.usuarioActual?.correo ?? '';
    final colorAvatar = colorAvatarPara(provider.usuarioActual!.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
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
                          backgroundColor: colorAvatar.fondo,
                          backgroundImage: _fotoPath != null
                              ? FileImage(File(_fotoPath!))
                              : null,
                          child: _fotoPath == null
                              ? Text(
                                  _nombreController.text.trim().isNotEmpty
                                      ? _nombreController.text
                                            .trim()[0]
                                            .toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: colorAvatar.texto,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 40,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _acento,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nombreController,
                  decoration: _decoracion(
                    'Nombre completo',
                    'assets/icon/nav_perfil.png',
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Ingresa tu nombre'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: correo,
                  enabled: false,
                  decoration: _decoracion(
                    'Correo electrónico',
                    'assets/icon/correo.png',
                    helper: 'Por ahora no se puede cambiar aquí',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _celularController,
                  keyboardType: TextInputType.phone,
                  decoration: _decoracion(
                    'Número de celular',
                    'assets/icon/telefono.png',
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _barrioController,
                  decoration: _decoracion(
                    'Barrio / zona (opcional)',
                    'assets/icon/marcador_posicion.png',
                    helper:
                        'Ayuda a mostrar trabajos y trabajadores cerca de ti',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cedulaController,
                  keyboardType: TextInputType.number,
                  decoration: _decoracion(
                    'Documento de identidad (opcional)',
                    'assets/icon/documento_identidad.png',
                    helper: 'Ayuda a generar más confianza en tu perfil',
                  ),
                ),
                if (esTrabajador) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Servicios que ofreces (puedes elegir varios)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _servicios.map((servicio) {
                      final seleccionado = _oficiosSeleccionados.contains(
                        servicio,
                      );
                      return FilterChip(
                        avatar: SizedBox(
                          width: 18,
                          height: 18,
                          child: Image.asset(
                            _iconosCategoria[servicio]!,
                            fit: BoxFit.contain,
                          ),
                        ),
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
                        selectedColor: _acento.withValues(alpha: 0.18),
                        checkmarkColor: _acento,
                        labelStyle: TextStyle(
                          color: seleccionado
                              ? _acento
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        side: BorderSide(
                          color: seleccionado
                              ? _acento
                              : Theme.of(context).dividerColor,
                        ),
                        backgroundColor: Theme.of(context).cardColor,
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
                    backgroundColor: _acento,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Guardar cambios',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoracion(
    String label,
    String? iconoAsset, {
    IconData? icono,
    String? helper,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      prefixIcon: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: SizedBox(
          width: 18,
          height: 18,
          child: iconoAsset != null
              ? Image.asset(iconoAsset, fit: BoxFit.contain)
              : Icon(icono, size: 18, color: Colors.grey.shade600),
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      disabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: _acento, width: 1.5),
      ),
    );
  }
}
