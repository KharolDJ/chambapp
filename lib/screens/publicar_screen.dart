import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/peticion.dart';
import '../providers/app_provider.dart';

const _acento = AppColors.azulCeleste;
const _calidoClaro = Color(0xFFF5F5F7);
const _calidoOscuro = Color(0xFF20242B);

List<BoxShadow> _sombraSuave({
  double blur = 24,
  double y = 10,
  double alpha = 0.06,
}) => [
  BoxShadow(
    color: Colors.black.withValues(alpha: alpha),
    blurRadius: blur,
    offset: Offset(0, y),
  ),
];

class PublicarScreen extends StatefulWidget {
  const PublicarScreen({super.key});

  @override
  State<PublicarScreen> createState() => _PublicarScreenState();
}

class _PublicarScreenState extends State<PublicarScreen> {
  static const _descripcionMinima = 20;

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

  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _barrioController = TextEditingController();
  String _categoria = 'Plomería';
  bool _urgente = false;
  String? _fotoPath;
  bool _publicando = false;

  double? _lat;
  double? _lng;
  bool _obteniendoUbicacion = true;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _barrioController.dispose();
    super.dispose();
  }

  Future<void> _obtenerUbicacion() async {
    try {
      final servicioActivo = await Geolocator.isLocationServiceEnabled();
      if (!servicioActivo) {
        setState(() => _obteniendoUbicacion = false);
        return;
      }
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        setState(() => _obteniendoUbicacion = false);
        return;
      }
      final posicion = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _lat = posicion.latitude;
        _lng = posicion.longitude;
        _obteniendoUbicacion = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _obteniendoUbicacion = false);
    }
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

  Future<void> _publicar() async {
    if (!_formKey.currentState!.validate()) return;

    final usuarioActual = context.read<AppProvider>().usuarioActual;
    if (usuarioActual == null) return;

    setState(() => _publicando = true);
    await context.read<AppProvider>().publicarPeticion(
      Peticion(
        id: FirebaseFirestore.instance.collection('peticiones').doc().id,
        autorId: usuarioActual.id,
        autorNombre: usuarioActual.nombre,
        barrio: _barrioController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        categoria: _categoria,
        urgente: _urgente,
        creadaEn: DateTime.now(),
        fotoUrl: _fotoPath,
        lat: _lat,
        lng: _lng,
      ),
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  InputDecoration _decoracionCampo({
    required String label,
    String? helper,
    String? counter,
  }) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      helperText: helper,
      counterText: counter,
      filled: true,
      fillColor: esOscuro ? _calidoOscuro : _calidoClaro,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final campoFill = esOscuro ? _calidoOscuro : _calidoClaro;

    return Scaffold(
      appBar: AppBar(title: const Text('Publicar petición')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _acento.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.post_add_rounded,
                      color: _acento,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cuéntanos qué necesitas',
                          style:
                              (tema.textTheme.titleLarge ?? const TextStyle())
                                  .copyWith(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: tema.colorScheme.onSurface,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Entre más claro seas, más rápido te van a contactar',
                          style: TextStyle(
                            fontSize: 13,
                            color: tema.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: tema.cardColor,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: _sombraSuave(alpha: esOscuro ? 0.3 : 0.06),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: _elegirFoto,
                      child: Container(
                        height: 116,
                        width: double.infinity,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: campoFill,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: _fotoPath == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 26,
                                    height: 26,
                                    child: Image.asset(
                                      'assets/icon/camara.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Agregar foto (opcional)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: tema.textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ],
                              )
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    File(_fotoPath!),
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _fotoPath = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 4,
                      onChanged: (_) => setState(() {}),
                      decoration: _decoracionCampo(
                        label: '¿Qué necesitas?',
                        helper: 'Entre más detalles, más rápido te contactan',
                        counter:
                            '${_descripcionController.text.trim().length}/$_descripcionMinima mínimo',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Escribe qué necesitas';
                        }
                        if (v.trim().length < _descripcionMinima) {
                          return 'Agrega más detalles (mínimo $_descripcionMinima caracteres)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _barrioController,
                      decoration: _decoracionCampo(label: 'Barrio'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Escribe tu barrio'
                          : null,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Categoría',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: tema.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _iconosCategoria.entries.map((entry) {
                        final activo = entry.key == _categoria;
                        return InkWell(
                          onTap: () => setState(() => _categoria = entry.key),
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: activo ? _acento : campoFill,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: activo
                                  ? [
                                      BoxShadow(
                                        color: _acento.withValues(alpha: 0.28),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Image.asset(
                                    entry.value,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: activo
                                        ? Colors.white
                                        : tema.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: campoFill,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SwitchListTile(
                        value: _urgente,
                        onChanged: (v) => setState(() => _urgente = v),
                        title: const Text('Marcar como urgente'),
                        activeThumbColor: const Color(0xFFB54834),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Icon(
                          _obteniendoUbicacion
                              ? Icons.location_searching
                              : (_lat != null
                                    ? Icons.location_on
                                    : Icons.location_off),
                          size: 14,
                          color: tema.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _obteniendoUbicacion
                                ? 'Obteniendo tu ubicación...'
                                : (_lat != null
                                      ? 'Ubicación detectada — se usará para ordenar tu publicación por cercanía'
                                      : 'Sin ubicación disponible — activa el GPS para que te encuentren más rápido'),
                            style: TextStyle(
                              fontSize: 11,
                              color: tema.textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _publicando ? null : _publicar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _acento,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 4,
                  shadowColor: _acento.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _publicando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Publicar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
