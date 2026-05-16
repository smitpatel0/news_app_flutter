import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ArticalNews extends StatefulWidget {
  const ArticalNews({super.key, required this.newsUrl});
  final String newsUrl;

  @override
  State<ArticalNews> createState() => _ArticalNewsState();
}

class _ArticalNewsState extends State<ArticalNews> {
  late final WebViewController controller;
  bool _isLoadingPage = true;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoadingPage = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.newsUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('News'),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),

          if (_isLoadingPage)
            const Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.yellow,
              ),
            ),
        ],
      ),
    );
  }
}