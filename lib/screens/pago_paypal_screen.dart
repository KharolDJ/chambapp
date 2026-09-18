import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/paypal_config.dart';
import '../services/paypal_service.dart';

/// Resultado que devuelve [PagoPaypalScreen] al hacer pop. [estado] es el
/// status que devuelve PayPal al capturar la orden (`'COMPLETED'` si el
/// pago quedó aprobado); [ordenId] es el id real de esa orden, para poder
/// guardarlo como comprobante auditable en Firestore.
class ResultadoPagoPaypal {
  final String estado;
  final String ordenId;
  const ResultadoPagoPaypal({required this.estado, required this.ordenId});
}

/// Pantalla de pago con PayPal Sandbox. Al terminar, hace `Navigator.pop`
/// con un [ResultadoPagoPaypal] si se llegó a intentar capturar el pago,
/// o `null` si el usuario canceló o cerró la pantalla antes de pagar.
class PagoPaypalScreen extends StatefulWidget {
  final String montoUsd;
  final String descripcion;

  const PagoPaypalScreen({
    super.key,
    required this.montoUsd,
    required this.descripcion,
  });

  @override
  State<PagoPaypalScreen> createState() => _PagoPaypalScreenState();
}

class _PagoPaypalScreenState extends State<PagoPaypalScreen> {
  late final WebViewController _controller;
  bool _cargandoOrden = true;
  bool _confirmando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    try {
      final orden = await PaypalService.crearOrden(
        montoUsd: widget.montoUsd,
        descripcion: widget.descripcion,
      );
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(onNavigationRequest: _interceptarNavegacion),
        )
        ..loadRequest(Uri.parse(orden.urlAprobacion));
      if (!mounted) return;
      setState(() => _cargandoOrden = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargandoOrden = false;
        _error = 'No se pudo iniciar el pago. Revisa tu conexión e intenta de nuevo.';
      });
    }
  }

  NavigationDecision _interceptarNavegacion(NavigationRequest request) {
    final url = request.url;
    if (url.startsWith(PayPalConfig.returnUrl)) {
      final token = Uri.parse(url).queryParameters['token'];
      if (token != null) _confirmarPago(token);
      return NavigationDecision.prevent;
    }
    if (url.startsWith(PayPalConfig.cancelUrl)) {
      Navigator.of(context).pop(null);
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  Future<void> _confirmarPago(String ordenId) async {
    setState(() => _confirmando = true);
    String estado;
    try {
      estado = await PaypalService.capturarOrden(ordenId);
    } catch (_) {
      estado = 'ERROR';
    }
    if (!mounted) return;
    Navigator.of(
      context,
    ).pop(ResultadoPagoPaypal(estado: estado, ordenId: ordenId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pago con PayPal (sandbox)')),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : Stack(
              children: [
                if (!_cargandoOrden) WebViewWidget(controller: _controller),
                if (_cargandoOrden || _confirmando)
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
                                : 'Abriendo PayPal...',
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
