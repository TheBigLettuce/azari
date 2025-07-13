// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/init_main/build_theme.dart";
import "package:azari/src/init_main/restart_widget.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/services/impl/obj/post_impl.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/booru/booru_restored_page.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:flutter/material.dart";

class AppMaterial extends StatefulWidget {
  const AppMaterial({super.key});

  @override
  State<AppMaterial> createState() => _AppMaterialState();
}

class _AppMaterialState extends State<AppMaterial> {
  final navigatorKey = GlobalKey<NavigatorState>();

  final selectionEvents = SelectionActions();

  @override
  void dispose() {
    selectionEvents.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const AppApi().accentColor;

    final d = buildTheme(Brightness.dark, accentColor);
    final l = buildTheme(Brightness.light, accentColor);

    return AlertServiceUI(
      navigatorKey: navigatorKey,
      child: selectionEvents.inject(
        TimeTickerStatistics(
          child: MaterialApp(
            navigatorKey: navigatorKey,
            color: accentColor,
            themeAnimationCurve: Easing.standard,
            themeAnimationDuration: const Duration(milliseconds: 300),
            darkTheme: d,
            theme: l,
            home: const Home(),
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) => "Azari",
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      ),
    );
  }
}

mixin WebLinksImplMixin<W extends StatefulWidget> on State<W> {
  late final StreamSubscription<String>? _webLinksEvents;

  @override
  void initState() {
    super.initState();

    _webLinksEvents = GalleryApi.safe()?.events.webLinks?.listen(
      onWebLinkEvent,
    );
  }

  @override
  void dispose() {
    _webLinksEvents?.cancel();

    super.dispose();
  }

  void onWebLinkEvent(String link) {
    final uri = Uri.parse(link);

    final booru = Booru.matchUrl(uri.host);
    if (booru == null) {
      return;
    }

    final postLink = uri.asBooruPostLink();
    if (postLink != null) {
      openPostAsync(context, booru: postLink.booru, postId: postLink.id);
      return;
    }

    final searchLink = uri.asBooruSearchLink();
    if (searchLink != null) {
      BooruRestoredPage.open(
        context,
        booru: searchLink.booru,
        tags: searchLink.tags,
      );
      return;
    }
  }
}
