import 'dart:io';

import 'package:flutter/material.dart';

/// [ruta] puede ser una URL de Cloudinary (fotos nuevas) o, por
/// compatibilidad con datos ya guardados antes de esta migración, una
/// ruta local de archivo — que solo existe en el dispositivo donde se
/// tomó la foto. Nunca se asume cuál de las dos es: si es local y ya no
/// existe (u ocurre en otro dispositivo), se degrada a `null` en vez de
/// lanzar una excepción (mismo principio que la lección de datos locales
/// obsoletos documentada para este proyecto).
ImageProvider? proveedorFoto(String? ruta) {
  if (ruta == null || ruta.isEmpty) return null;
  if (ruta.startsWith('http')) return NetworkImage(ruta);
  final archivo = File(ruta);
  if (!archivo.existsSync()) return null;
  return FileImage(archivo);
}

/// Igual que [proveedorFoto] pero como widget `Image`, para los lugares
/// que ya usaban `Image.file(...)` directamente en vez de un
/// `ImageProvider` (ej. la foto de una publicación).
Widget imagenFoto(
  String ruta, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  if (ruta.startsWith('http')) {
    return Image.network(
      ruta,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: errorBuilder,
    );
  }
  return Image.file(
    File(ruta),
    fit: fit,
    width: width,
    height: height,
    errorBuilder: errorBuilder,
  );
}
