import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'cloudinary_config.dart';

class CloudinaryService {
  /// Sube [archivo] a Cloudinary y devuelve la URL pública (https) de la
  /// foto ya alojada en la nube — lista para guardarse en Firestore en vez
  /// de la ruta local del archivo.
  static Future<String> subirFoto(File archivo) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', archivo.path));

    final respuesta = await request.send();
    final cuerpo = await respuesta.stream.bytesToString();
    if (respuesta.statusCode != 200) {
      throw Exception('No se pudo subir la foto (${respuesta.statusCode}).');
    }
    final data = jsonDecode(cuerpo) as Map<String, dynamic>;
    return data['secure_url'] as String;
  }
}
