// Llaves de PayPal Sandbox (modo de pruebas) — sacadas de
// developer.paypal.com > Sandbox > Apps & Credentials.
//
// El Secret queda embebido en la app a propósito: es una llave de
// SANDBOX (dinero ficticio, sin riesgo real), y evita tener que montar un
// backend solo para la tesis. En producción esto NO se haría así — la
// creación/captura de la orden se movería a un servidor para no exponer
// el Secret real.
class PayPalConfig {
  static const clientId = 'BAAiZIrjoxMuVTxFGtsKOKJf5GOPV7MqA9dVT881Kq9yiE8z_GG_gecxYo79UzdEIs7n4pI_ChY2vB-5YU';
  static const secret = 'EDRpreuNqpLDJ8-bCrojKyCFWPO0uv9KbKqM4IQD8_sI1SeU8o--wQwxVz-ATWSOG1ouyLL4_tSjwqH0';

  // Sandbox de PayPal. Para producción sería https://api-m.paypal.com.
  static const baseUrl = 'https://api-m.sandbox.paypal.com';

  // URLs "de mentiras" — la app nunca deja que carguen de verdad: el
  // WebView intercepta la navegación en cuanto detecta que empieza con
  // una de estas y la cancela (ver PagoPaypalScreen).
  static const returnUrl = 'https://chambapp.app/pago-exitoso';
  static const cancelUrl = 'https://chambapp.app/pago-cancelado';
}
