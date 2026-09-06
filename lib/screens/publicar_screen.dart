import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/peticion.dart';
import '../providers/app_provider.dart';

class PublicarScreen extends StatefulWidget {
  const PublicarScreen({super.key});

  @override
  State<PublicarScreen> createState() => _PublicarScreenState();
}

class _PublicarScreenState extends State<PublicarScreen> {
  static const _descripcionMinima = 20;

  static const Map<String, IconData> _iconosCategoria = {
    'Plomería': Icons.plumbing,
    'Electricidad': Icons.electrical_services,
    'Cocina': Icons.kitchen,
    'Carpintería': Icons.carpenter,
    'Jardinería': Icons.grass,
    'Limpieza del hogar': Icons.cleaning_services,
    'Pintura': Icons.format_paint,
    'Albañilería': Icons.construction,
    'Cerrajería': Icons.key,
    'Acarreos': Icons.local_shipping,
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
      if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
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

    final archivo = await ImagePicker().pickImage(source: origen, maxWidth: 800, imageQuality: 80);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        title: const Text('Publicar petición'),
        backgroundColor: const Color(0xFFFAF7F0),
        foregroundColor: const Color(0xFF26312D),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _elegirFoto,
                child: Container(
                  height: 110,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: _fotoPath == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade500),
                            const SizedBox(height: 6),
                            Text('Agregar foto (opcional)', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          ],
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(File(_fotoPath!), fit: BoxFit.cover),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () => setState(() => _fotoPath = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _descripcionController,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: '¿Qué necesitas?',
                  helperText: 'Entre más detalles, más rápido te contactan',
                  counterText: '${_descripcionController.text.trim().length}/$_descripcionMinima mínimo',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Escribe qué necesitas';
                  if (v.trim().length < _descripcionMinima) {
                    return 'Agrega más detalles (mínimo $_descripcionMinima caracteres)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _barrioController,
                decoration: InputDecoration(
                  labelText: 'Barrio',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe tu barrio' : null,
              ),
              const SizedBox(height: 18),
              Text('Categoría', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _iconosCategoria.entries.map((entry) {
                  final activo = entry.key == _categoria;
                  return InkWell(
                    onTap: () => setState(() => _categoria = entry.key),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: activo ? const Color(0xFF0F6E56) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: activo ? const Color(0xFF0F6E56) : Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(entry.value, size: 16, color: activo ? Colors.white : Colors.grey.shade700),
                          const SizedBox(width: 6),
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: activo ? Colors.white : const Color(0xFF26312D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _urgente,
                onChanged: (v) => setState(() => _urgente = v),
                title: const Text('Marcar como urgente'),
                activeThumbColor: const Color(0xFFB54834),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _obteniendoUbicacion
                        ? Icons.location_searching
                        : (_lat != null ? Icons.location_on : Icons.location_off),
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _obteniendoUbicacion
                        ? 'Obteniendo tu ubicación...'
                        : (_lat != null
                            ? 'Ubicación detectada — se usará para ordenar tu publicación por cercanía'
                            : 'Sin ubicación disponible — activa el GPS para que te encuentren más rápido'),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _publicando ? null : _publicar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F6E56),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _publicando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Publicar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
