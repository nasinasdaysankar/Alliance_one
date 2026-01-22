import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'theme.dart';

class WebViewScreen extends StatefulWidget {
  final String url;

  const WebViewScreen({
    super.key,
    required this.url,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _isLoading = true;
            _errorMessage = null;
          }),
          onPageFinished: (_) => setState(() {
            _isLoading = false;
          }),
          onWebResourceError: (error) => setState(() {
            _isLoading = false;
            _errorMessage = error.description;
          }),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),

        // Loader overlay (top-right, subtle)
        if (_isLoading)
          const Positioned(
            top: 8,
            right: 8,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),

        if (_errorMessage != null)
          Center(
            child: Text(
              'Error loading page',
              style: const TextStyle(color: Colors.white),
            ),
          ),
      ],
    );
  }
}
