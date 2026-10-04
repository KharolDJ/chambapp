import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/wompi_config.dart';
import '../services/wompi_service.dart';

/// Resultado que devuelve [PagoWompiScreen] al hacer pop. [estado] es el
/// status final de la transacción (`'APPROVED'` si el pago quedó aprobado);
/// [transaccionId] es el id real en Wompi, para guardarlo como comprobante
/// auditable en Firestore.
class ResultadoPagoWompi {
  final String estado;
  final String transaccionId;
  const ResultadoPagoWompi({required this.estado, required this.transaccionId});
}

/// Pantalla de pago con el Web Checkout de Wompi (Sandbox). Al terminar,
/// hace `Navigator.pop` con un [ResultadoPagoWompi] si Wompi devolvió una
/// transacción, o `null` si el usuario cerró la pantalla antes de pagar.
class PagoWompiScreen extends StatefulWidget {
  final int montoCentavos;

  /// Prefijo de la referencia, p. ej. `urgente` o `podio`.
  final String producto;

  const PagoWompiScreen({
    super.key,
    required this.montoCentavos,
    required this.producto,
  });

  @override
  State<PagoWompiScreen> createState() => _PagoWompiScreenState();
}

class _PagoWompiScreenState extends State<PagoWompiScreen> {
  late final WebViewController _controller;
  late final String _referencia;
  bool _cargando = true;
  bool _confirmando = false;

  @override
  void initState() {
    super.initState();
    _referencia = WompiService.nuevaReferencia(widget.producto);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _interceptarNavegacion,
          onPageFinished: (_) {
            if (mounted && _cargando) setState(() => _cargando = false);
          },
        ),
      )
      ..loadRequest(
        WompiService.urlCheckout(
          montoCentavos: widget.montoCentavos,
          referencia: _referencia,
        ),
      );
  }

  NavigationDecision _interceptarNavegacion(NavigationRequest request) {
    final url = request.url;
    if (url.startsWith(WompiConfig.urlRetorno)) {
      final id = Uri.parse(url).queryParameters['id'];
      if (id != null && id.isNotEmpty) {
        _confirmarPago(id);
      } else {
        Navigator.of(context).pop(null);
      }
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  Future<void> _confirmarPago(String transaccionId) async {
    if (_confirmando) return;
    setState(() => _confirmando = true);
    String estado;
    try {
      final transaccion = await WompiService.esperarEstadoFinal(transaccionId);
      // El redirect lo puede fabricar cualquiera: solo se da por bueno si
      // la transacción es la que abrimos, por el monto que cobramos.
      final coincide =
          transaccion.referencia == _referencia &&
          transaccion.montoCentavos == widget.montoCentavos &&
          transaccion.moneda == WompiConfig.moneda;
      estado = coincide ? transaccion.estado : 'NO_COINCIDE';
    } catch (_) {
      estado = 'ERROR';
    }
    if (!mounted) return;
    Navigator.of(
      context,
    ).pop(ResultadoPagoWompi(estado: estado, transaccionId: transaccionId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pago con Wompi (pruebas)')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_cargando || _confirmando)
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _confirmando
                          ? 'Confirmando pago...'
                          : 'Abriendo Wompi...',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
