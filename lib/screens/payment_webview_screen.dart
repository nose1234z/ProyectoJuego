import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:webview_flutter_android/webview_flutter_android.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String checkoutUrl;
  final String packageId;
  final int gems;

  const PaymentWebViewScreen({
    super.key,
    required this.checkoutUrl,
    required this.packageId,
    required this.gems,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('Página cargando: $url');
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            print('Página cargada: $url');
            setState(() {
              _isLoading = false;
            });

            // Detectar URLs de retorno
            _checkPaymentResult(url);
          },
          onWebResourceError: (WebResourceError error) {
            print('Error en WebView: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Navegación solicitada: ${request.url}');

            // Interceptar esquemas personalizados
            if (request.url.startsWith('mercadopago://') ||
                request.url.startsWith('iadefender://')) {
              print('Esquema personalizado detectado');
              _checkPaymentResult(request.url);
              return NavigationDecision.prevent;
            }

            // Permitir navegaciones normales
            return NavigationDecision.navigate;
          },
        ),
      );

    // Configuraciones específicas de Android
    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (_controller.platform as AndroidWebViewController)
        ..setMediaPlaybackRequiresUserGesture(false)
        ..setGeolocationPermissionsPromptCallbacks(
          onShowPrompt: (request) async {
            return GeolocationPermissionsResponse(allow: true, retain: true);
          },
        );
    }

    _controller.loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _checkPaymentResult(String url) {
    // Verificar si es una URL de retorno de Mercado Pago
    if (url.contains('iadefender://payment/')) {
      String? status;

      if (url.contains('success')) {
        status = 'success';
      } else if (url.contains('pending')) {
        status = 'pending';
      } else if (url.contains('failure')) {
        status = 'failure';
      }

      if (status != null) {
        // Cerrar la pantalla y retornar el resultado
        Navigator.of(context).pop(<String, dynamic>{
          'status': status,
          'packageId': widget.packageId,
          'gems': widget.gems,
        });
      }
    }

    // También verificar si regresó a la página de confirmación de Mercado Pago
    if (url.contains('mercadopago.com') &&
        (url.contains('congratulations') || url.contains('approved'))) {
      // Pago aprobado
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop(<String, dynamic>{
            'status': 'success',
            'packageId': widget.packageId,
            'gems': widget.gems,
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar Pago'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop(<String, dynamic>{'status': 'cancelled'});
          },
        ),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Cargando formulario de pago...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
