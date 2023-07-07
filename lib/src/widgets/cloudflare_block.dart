import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:cookie_jar/cookie_jar.dart' as dio;

class CloudflareBlock extends StatefulWidget {
  final CloudflareBlockInterface interface;
  const CloudflareBlock({super.key, required this.interface});

  @override
  State<CloudflareBlock> createState() => _CloudflareBlockState();
}

class _CloudflareBlockState extends State<CloudflareBlock> {
  final ChromeSafariBrowser browser = MyChromeSafariBrowser();

  @override
  void initState() {
    super.initState();
    browser.addMenuItem(ChromeSafariBrowserMenuItem(id: 1, label: "label"));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 14),
          child: Text(
            "403: Likely Cloudflare", // TODO: change
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        FilledButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) {
                  return AndroidWebview(intf: widget.interface);
                },
              ));
            },
            child: const Text("Solve captcha")) // TODO: change
      ],
    ));
  }
}

class MyChromeSafariBrowser extends ChromeSafariBrowser {
  @override
  void onOpened() {
    print("ChromeSafari browser opened");
  }

  @override
  void onCompletedInitialLoad(bool? didLoadSuccessfully) {
    print("ChromeSafari browser initial load completed");
  }

  @override
  void onClosed() {
    print("ChromeSafari browser closed");
  }
}

class AndroidWebview extends StatefulWidget {
  final CloudflareBlockInterface intf;
  const AndroidWebview({super.key, required this.intf});

  @override
  State<AndroidWebview> createState() => _AndroidWebviewState();
}

class _AndroidWebviewState extends State<AndroidWebview> {
  InAppWebViewController? controller;

  @override
  void initState() {
    // ..platform as AndroidWebViewController
    // ..setUserAgent(kTorUserAgent)
    // ..loadRequest(
    //   Uri.https("duckduckgo.com"),
    // );

    CookieManager.instance().deleteAllCookies();

    super.initState();
  }

  String _userAgent() {
    var version = Platform.version;
    // Only include major and minor version numbers.
    int index = version.indexOf('.', version.indexOf('.') + 1);
    version = version.substring(0, index);
    return "Dart/$version (dart:io)";
  }

  @override
  void dispose() {
    //controller.
    super.dispose();
  }

  dio.Cookie _toDioCookie(Cookie c) {
    return dio.Cookie(
      c.name,
      c.value,
    )
      ..domain = c.domain
      ..httpOnly = c.isHttpOnly ?? true
      ..secure = c.isSecure ?? true
      ..path = c.path ?? "/"
      ..expires = c.expiresDate != null
          ? DateTime.fromMillisecondsSinceEpoch(c.expiresDate!)
          : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
              onPressed: () async {
                var cookies = await CookieManager.instance().getCookies(
                    url: WebUri.uri(Uri.https(widget.intf.api.domain)));

                var cfClearance = cookies
                    .indexWhere((element) => element.name == "cf_clearance");

                if (cfClearance != -1) {
                  widget.intf.api.setCookies([
                    _toDioCookie(cookies[cfClearance]),
                  ]);
                }
              },
              icon: Icon(Icons.check)),
          title: Text("Solve captcha")),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri.uri(Uri.https(widget.intf.api.domain)),
        ),
        onWebViewCreated: (c) {
          controller = c;
        },
        initialSettings: InAppWebViewSettings(
          //useShouldInterceptRequest: true,
          userAgent: _userAgent(),
          safeBrowsingEnabled: false,
        ),
      ),
    );
  }
}
