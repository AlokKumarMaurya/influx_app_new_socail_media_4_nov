import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../utils/app_theme.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String initialUrl;
  final String title;

  const PaymentWebViewPage({
    super.key,
    required this.initialUrl,
    this.title = 'Payment Checkout',
  });

  static Future<bool?> open(BuildContext context, {required String initialUrl, String title = 'Payment Checkout'}) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (ctx) => PaymentWebViewPage(
          initialUrl: initialUrl,
          title: title,
        ),
      ),
    );
  }

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _progress = progress;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            _checkCallbackUrl(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _checkCallbackUrl(url);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Payment WebView error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_checkCallbackUrl(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  bool _checkCallbackUrl(String url) {
    final uri = Uri.parse(url);
    final path = uri.path.toLowerCase();

    if (path.contains('/payment/callback/') && path.contains('/success')) {
      if (mounted) Navigator.of(context).pop(true);
      return true;
    }
    if (path.contains('/payment/callback/') && path.contains('/cancel')) {
      if (mounted) Navigator.of(context).pop(false);
      return true;
    }
    if (path == '/wallet' || path == '/wallet/transactions') {
      if (mounted) Navigator.of(context).pop(true);
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: AppColors.textMain,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(widget.title, style: AppTextStyles.h4),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress / 100.0 : null,
                backgroundColor: Colors.transparent,
                color: AppColors.primary,
                minHeight: 3,
              ),
            ),
        ],
      ),
    );
  }
}
