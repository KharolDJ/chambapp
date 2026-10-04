// Llaves de Wompi Sandbox (modo de pruebas) — sacadas de
// comercios.wompi.co > Desarrolladores, con el ambiente en "Sandbox".
//
// El secreto de integridad queda embebido en la app a propósito: es de
// SANDBOX (dinero ficticio, sin riesgo real) y evita montar un backend solo
// para la tesis — Cloud Functions exigiría el plan Blaze de Firebase. En
// producción esto NO se haría así: la firma de integridad se calcularía en un
// servidor, que además recibiría el webhook de Wompi. La llave privada no se
// usa: consultar una transacción por id es público en la API de Wompi.
class WompiConfig {
  static const llavePublica = 'pub_test_jYyKVAcG9ns7v2S348SRTyAo3q8MUhp0';
  static const secretoIntegridad = 'test_integrity_RUg5DSTJ9pf224jnORqMjWYiMWigQnkc';

  // API de Sandbox. Para producción sería https://production.wompi.co/v1.
  static const apiBase = 'https://sandbox.wompi.co/v1';

  // Web Checkout: el mismo dominio sirve Sandbox y producción; el ambiente
  // lo decide la llave pública (pub_test_ vs pub_prod_).
  static const checkoutBase = 'https://checkout.wompi.co/p/';

  // URL "de mentiras" — el WebView intercepta la navegación en cuanto
  // detecta que empieza con esta y la cancela (ver PagoWompiScreen). Wompi
  // le agrega ?id=<id de la transacción>.
  static const urlRetorno = 'https://chambapp.app/pago-wompi';

  static const moneda = 'COP';
}
