import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterConfig.loadEnvVariables();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  WebViewController? controller;
  String? prevUrl;

  void _naverLogin() async {
    if (controller != null) {
      return;
    }

    String serverURL = await FlutterConfig.get("SERVER_URL");
    Map<String, String> headers = {
      'x-app-version': '1.1.1',
      'x-os': 'android'
    };

    setState(() {
      controller = WebViewController()
        ..setBackgroundColor(Colors.white)
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..addJavaScriptChannel(
            'login_token',
            onMessageReceived: _continueLogin(serverURL)
        )
        ..addJavaScriptChannel(
            'register_required',
            onMessageReceived: _goToRegister(serverURL)
        )
        ..setNavigationDelegate(NavigationDelegate(
          onUrlChange: (urlChange) async {
            log('urlChange.url ${urlChange.url ?? 'null'}');
            log('prevUrl ${prevUrl ?? 'null'}');

            if (urlChange.url != null) {
              if (prevUrl == null || prevUrl != urlChange.url) {
                if (urlChange.url!.contains('$serverURL/auth/login/naver/callback')) {
                  controller
                    ?..runJavaScript('window.stop();')
                    ..loadRequest(
                      Uri.parse(urlChange.url!),
                      headers: headers
                    );
                }

                prevUrl = urlChange.url;
              }
            }
          }
        ))
        ..loadRequest(Uri.parse('$serverURL/auth/login/naver'));
    });
  }

  void Function(JavaScriptMessage) _continueLogin(String serverURL) {
    return (JavaScriptMessage message) {
      log('_continueLogin ${message.message}');

      setState(() {
        controller = null;
      });
    };
  }

  void Function(JavaScriptMessage) _goToRegister(String serverURL) {
    return (JavaScriptMessage message) {
      log('_goToRegistration ${message.message}');

      setState(() {
        controller = null;
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: controller == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextButton(
                        onPressed: _naverLogin,
                        child: const Text('Naver login'))
                  ],
                ),
              )
            : WebViewWidget(controller: controller!),
    );
  }
}
