import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/peticion.dart';
import '../providers/app_provider.dart';
import '../services/cloudinary_service.dart';
import '../widgets/foto_image.dart';
import 'login_screen.dart';

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

  // Oficios donde "urgente" suele ser literal (tubería rota, sin luz,
  // puerta trabada) — cuando la categoría elegida es una de estas, se
  // resalta el aviso de que la etiqueta Urgente se puede comprar después.
  static const _categoriasEmergencia = {
    'Plomería',
    'Electricidad',
    'Cerrajería',
  };

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
  String? _fotoPath;
  bool _subiendoFoto = false;
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
    setState(() => _subiendoFoto = true);
    try {
      final url = await CloudinaryService.subirFoto(File(archivo.path));
      if (!mounted) return;
      setState(() {
        _fotoPath = url;
        _subiendoFoto = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _subiendoFoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo subir la foto. Intenta de nuevo.'),
        ),
      );
    }
  }

  Future<void> _publicar() async {
    if (!_formKey.currentState!.validate()) return;

    var usuarioActual = context.read<AppProvider>().usuarioActual;
    if (usuarioActual == null) {
      // No debería pasar (el FAB que abre esta pantalla ya exige sesión),
      // pero si por algún otro camino se llega aquí sin usuario, mandamos a
      // login en vez de dejar el botón "Publicar" sin hacer nada.
      final autenticado = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (!mounted || autenticado != true) return;
      usuarioActual = context.read<AppProvider>().usuarioActual;
      if (usuarioActual == null) return;
    }

    setState(() => _publicando = true);
    await context.read<AppProvider>().publicarPeticion(
      Peticion(
        id: FirebaseFirestore.instance.collection('peticiones').doc().id,
        autorId: usuarioActual.id,
        autorNombre: usuarioActual.nombre,
        barrio: _barrioController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        categoria: _categoria,
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
              Text(
                'Cuéntanos qué necesitas',
                style: (tema.textTheme.titleLarge ?? const TextStyle())
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
                        child: _subiendoFoto
                            ? const Center(child: CircularProgressIndicator())
                            : _fotoPath == null
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
                                  imagenFoto(_fotoPath!, fit: BoxFit.cover),
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
                              // Blanco al seleccionar (no el dorado de
                              // antes) — misma línea limpia que los
                              // filtros de "Cerca de ti".
                              color: activo ? Colors.white : campoFill,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: activo
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.15,
                                        ),
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
                                        ? AppColors.negroProfundo
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
                    // "Urgente" es un beneficio pago de Visibilidad Premium
                    // (propuesta F-DC-124: "Urgentes y Podio"), así que aquí
                    // solo se informa dónde activarlo, no se regala.
                    Builder(
                      builder: (context) {
                        final emergencia =
                            _categoriasEmergencia.contains(_categoria);
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: campoFill,
                            borderRadius: BorderRadius.circular(16),
                            border: emergencia
                                ? Border.all(
                                    color: const Color(0xFFB54834)
                                        .withValues(alpha: 0.4),
                                  )
                                : null,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.bolt,
                                size: 18,
                                color: Color(0xFFB54834),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  emergencia
                                      ? '$_categoria suele ser una emergencia. Después de publicar puedes activar la etiqueta "Urgente" (\$10.000) desde Actividad → Premium.'
                                      : '¿Es urgente? Después de publicar puedes activar la etiqueta "Urgente" (\$10.000) desde Actividad → Premium.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.35,
                                    color: emergencia
                                        ? const Color(0xFFB54834)
                                        : tema.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
                  backgroundColor: esOscuro
                      ? Colors.white
                      : AppColors.negroProfundo,
                  foregroundColor: esOscuro
                      ? AppColors.negroProfundo
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _publicando
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: esOscuro
                              ? AppColors.negroProfundo
                              : Colors.white,
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
