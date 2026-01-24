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

class _WebViewScreenState extends State<WebViewScreen> with AutomaticKeepAliveClientMixin {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _canGoBack = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36')
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _isLoading = true;
            _errorMessage = null;
          }),
          onPageFinished: (_) async {
            final canGoBack = await _controller.canGoBack();
            setState(() {
              _isLoading = false;
              _canGoBack = canGoBack;
            });
          },
          onWebResourceError: (error) {
            debugPrint('❌ WebView Error: ${error.errorCode} - ${error.description}');
            
            // If the page finished loading, ignore subsequent errors (like background socket timeouts)
            // protecting the user's view of the content.
            if (!_isLoading) return;

            // Ignore "cancelled" or non-main-frame errors
            if (error.errorCode == -999) return;
            if (error.isForMainFrame == false) return;
            
            setState(() {
              _isLoading = false;
              _errorMessage = error.description;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _reload() {
    _controller.reload();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PopScope(
      canPop: !_canGoBack,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _controller.goBack();
      },
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),

          // Loader overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                 child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Error View with Retry
          if (_errorMessage != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.amber, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Oops! $_errorMessage',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _reload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),


          // Error View with Retry
          if (_errorMessage != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.amber, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Oops! $_errorMessage',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _reload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),

          // Floating Back Button (only when can go back)
          if (_canGoBack)
            Positioned(
              bottom: 20,
              left: 20,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.black.withOpacity(0.7),
                foregroundColor: Colors.white,
                elevation: 4,
                child: const Icon(Icons.arrow_back),
                onPressed: () async {
                  await _controller.goBack();
                },
              ),
            ),
        ],
      ),
    );
  }
}
