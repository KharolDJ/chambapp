import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'wompi_config.dart';

/// Estado de una transacción de Wompi tal como la devuelve
/// `GET /v1/transactions/{id}`.
class TransaccionWompi {
  final String id;
  final String estado; // APPROVED, DECLINED, VOIDED, ERROR o PENDING
  final String referencia;
  final int montoCentavos;
  final String moneda;
  const TransaccionWompi({
    required this.id,
    required this.estado,
    required this.referencia,
    required this.montoCentavos,
    required this.moneda,
  });
}

/// Integración con el Web Checkout de Wompi en modo Sandbox, sin backend
/// propio — ver la nota de seguridad en [WompiConfig].
class WompiService {
  /// Referencia única por intento de pago (Wompi rechaza referencias
  /// repetidas), p. ej. `chambapp-urgente-1790700000000`.
  static String nuevaReferencia(String producto) =>
      'chambapp-$producto-${DateTime.now().millisecondsSinceEpoch}';

  /// Firma de integridad: SHA256(referencia + monto en centavos + moneda +
  /// secreto de integridad), en ese orden exacto.
  static String _firmaIntegridad(String referencia, int montoCentavos) {
    final cadena =
        '$referencia$montoCentavos${WompiConfig.moneda}${WompiConfig.secretoIntegridad}';
    return sha256.convert(utf8.encode(cadena)).toString();
  }

  /// URL del Web Checkout para cobrar [montoCentavos] (10.000 COP =
  /// 1000000) con la [referencia] dada.
  static Uri urlCheckout({
    required int montoCentavos,
    required String referencia,
  }) {
    return Uri.parse(WompiConfig.checkoutBase).replace(
      queryParameters: {
        'public-key': WompiConfig.llavePublica,
        'currency': WompiConfig.moneda,
        'amount-in-cents': '$montoCentavos',
        'reference': referencia,
        'signature:integrity': _firmaIntegridad(referencia, montoCentavos),
        'redirect-url': WompiConfig.urlRetorno,
      },
    );
  }

  /// Consulta la transacción [id]. El endpoint es público (no requiere
  /// llave), así que la llave privada nunca viaja en la app.
  static Future<TransaccionWompi> consultarTransaccion(String id) async {
    final respuesta = await http.get(
      Uri.parse('${WompiConfig.apiBase}/transactions/$id'),
    );
    if (respuesta.statusCode != 200) {
      throw Exception('No se pudo consultar la transacción de Wompi.');
    }
    final data =
        (jsonDecode(respuesta.body) as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
    return TransaccionWompi(
      id: data['id'] as String,
      estado: data['status'] as String? ?? 'ERROR',
      referencia: data['reference'] as String? ?? '',
      montoCentavos: (data['amount_in_cents'] as num?)?.toInt() ?? 0,
      moneda: data['currency'] as String? ?? '',
    );
  }

  /// Consulta la transacción hasta que deje de estar PENDING (Nequi y PSE
  /// pueden tardar unos segundos en resolverse), con un máximo de
  /// [intentos] consultas separadas por [espera].
  static Future<TransaccionWompi> esperarEstadoFinal(
    String id, {
    int intentos = 10,
    Duration espera = const Duration(seconds: 3),
  }) async {
    var transaccion = await consultarTransaccion(id);
    for (var i = 1; i < intentos && transaccion.estado == 'PENDING'; i++) {
      await Future<void>.delayed(espera);
      transaccion = await consultarTransaccion(id);
    }
    return transaccion;
  }
}
