// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CloudflareBlock extends StatefulWidget {
  final CloudflareBlockInterface interface;
  const CloudflareBlock({super.key, required this.interface});

  @override
  State<CloudflareBlock> createState() => _CloudflareBlockState();
}

class _CloudflareBlockState extends State<CloudflareBlock> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 14),
          child: Text(
            AppLocalizations.of(context)!.cloudflareBlock,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        FilledButton(
            onPressed: !Platform.isAndroid
                ? null
                : () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) {
                        return const Placeholder();
                      },
                    ));
                  },
            child: Text(AppLocalizations.of(context)!.solveCaptcha))
      ],
    ));
  }
}

// class AndroidWebview extends StatefulWidget {
//   final CloudflareBlockInterface intf;
//   const AndroidWebview({super.key, required this.intf});

//   @override
//   State<AndroidWebview> createState() => _AndroidWebviewState();
// }

// class _AndroidWebviewState extends State<AndroidWebview> {
//   InAppWebViewController? controller;

//   @override
//   void initState() {
//     CookieManager.instance().deleteAllCookies();

//     super.initState();
//   }

//   String _userAgent() {
//     final version = Platform.version;
//     final index = version.indexOf('.', version.indexOf('.') + 1);
//     return "Dart/${version.substring(0, index)} (dart:io)";
//   }

//   @override
//   void dispose() {
//     //controller.
//     super.dispose();
//   }

//   dio.Cookie _toDioCookie(Cookie c) {
//     return dio.Cookie(
//       c.name,
//       c.value,
//     )
//       ..domain = c.domain
//       ..httpOnly = c.isHttpOnly ?? true
//       ..secure = c.isSecure ?? true
//       ..path = c.path ?? "/"
//       ..expires = c.expiresDate != null
//           ? DateTime.fromMillisecondsSinceEpoch(c.expiresDate!)
//           : null;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//           leading: IconButton(
//               onPressed: () async {
//                 var cookies = await CookieManager.instance().getCookies(
//                     url: WebUri.uri(Uri.https(widget.intf.api.booru.url)));

//                 var cfClearance = cookies
//                     .indexWhere((element) => element.name == "cf_clearance");

//                 if (cfClearance != -1) {
//                   widget.intf.api.setCookies([
//                     _toDioCookie(cookies[cfClearance]),
//                   ]);
//                 }
//               },
//               icon: const Icon(Icons.check)),
//           title: Text(AppLocalizations.of(context)!.solveCaptcha)),
//       body: InAppWebView(
//         initialUrlRequest: URLRequest(
//           url: WebUri.uri(Uri.https(widget.intf.api.booru.url)),
//         ),
//         onWebViewCreated: (c) {
//           controller = c;
//         },
//         initialSettings: InAppWebViewSettings(
//           //useShouldInterceptRequest: true,
//           userAgent: _userAgent(),
//           safeBrowsingEnabled: false,
//         ),
//       ),
//     );
//   }
// }
