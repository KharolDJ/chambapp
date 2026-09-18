import 'dart:convert';

import 'package:http/http.dart' as http;

import 'paypal_config.dart';

/// Resultado de crear una orden: el id (necesario para capturarla luego)
/// y la URL de aprobación a la que se debe llevar al usuario.
class OrdenPaypal {
  final String id;
  final String urlAprobacion;
  OrdenPaypal({required this.id, required this.urlAprobacion});
}

/// Integración directa con la API REST de PayPal (Orders API v2) en modo
/// sandbox, sin backend propio — ver la nota de seguridad en
/// [PayPalConfig] sobre por qué el Secret vive en la app solo porque esto
/// es un prototipo de tesis con dinero de mentiras.
class PaypalService {
  static Future<String> _obtenerToken() async {
    final credenciales = base64Encode(
      utf8.encode('${PayPalConfig.clientId}:${PayPalConfig.secret}'),
    );
    final respuesta = await http.post(
      Uri.parse('${PayPalConfig.baseUrl}/v1/oauth2/token'),
      headers: {
        'Authorization': 'Basic $credenciales',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'grant_type': 'client_credentials'},
    );
    if (respuesta.statusCode != 200) {
      throw Exception('No se pudo autenticar con PayPal (sandbox).');
    }
    return jsonDecode(respuesta.body)['access_token'] as String;
  }

  /// Crea una orden de pago por [montoUsd] (ej. "2.50") y devuelve su id
  /// más el link de aprobación de PayPal para abrir en el WebView.
  static Future<OrdenPaypal> crearOrden({
    required String montoUsd,
    required String descripcion,
  }) async {
    final token = await _obtenerToken();
    final respuesta = await http.post(
      Uri.parse('${PayPalConfig.baseUrl}/v2/checkout/orders'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'intent': 'CAPTURE',
        'purchase_units': [
          {
            'description': descripcion,
            'amount': {'currency_code': 'USD', 'value': montoUsd},
          },
        ],
        'application_context': {
          'return_url': PayPalConfig.returnUrl,
          'cancel_url': PayPalConfig.cancelUrl,
          'user_action': 'PAY_NOW',
        },
      }),
    );
    if (respuesta.statusCode != 201) {
      throw Exception('No se pudo crear la orden de PayPal.');
    }
    final data = jsonDecode(respuesta.body) as Map<String, dynamic>;
    final links = (data['links'] as List).cast<Map<String, dynamic>>();
    final aprobacion = links.firstWhere((l) => l['rel'] == 'approve');
    return OrdenPaypal(
      id: data['id'] as String,
      urlAprobacion: aprobacion['href'] as String,
    );
  }

  /// Confirma el pago de la orden [ordenId] tras la aprobación del
  /// usuario en el checkout. Devuelve el estado final ("COMPLETED" si el
  /// pago se aprobó).
  static Future<String> capturarOrden(String ordenId) async {
    final token = await _obtenerToken();
    final respuesta = await http.post(
      Uri.parse(
        '${PayPalConfig.baseUrl}/v2/checkout/orders/$ordenId/capture',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (respuesta.statusCode != 201 && respuesta.statusCode != 200) {
      return 'ERROR';
    }
    final data = jsonDecode(respuesta.body) as Map<String, dynamic>;
    return data['status'] as String? ?? 'ERROR';
  }
}
