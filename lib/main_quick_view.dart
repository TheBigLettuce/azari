// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "main.dart";

/// Entrypoint for the third Android's Activity.
/// Shows the image or video from ACTION_VIEW.
@pragma("vm:entry-point")
Future<void> mainQuickView() async {
  final notificationStream =
      StreamController<NotificationRouteEvent>.broadcast();

  await initMain(true, notificationStream);

  final accentColor = await PlatformApi().accentColor;

  final uris = await const MethodChannel(
    "com.github.thebiglettuce.azari.activity_context",
  ).invokeListMethod<String>("getQuickViewUris").then((e) => e!);

  final files = (await platform.GalleryHostApi().getUriPicturesDirectly(uris))
      .map(
        (e) => AndroidUriFile(
          width: e.width,
          height: e.height,
          uri: e.uri,
          name: e.name,
          lastModified: e.lastModified,
          size: e.size,
        ),
      )
      .toList();

  runApp(
    DatabaseConnectionNotifier.current(
      MaterialApp(
        title: "Azari",
        themeAnimationCurve: Easing.standard,
        themeAnimationDuration: const Duration(milliseconds: 300),
        darkTheme: buildTheme(Brightness.dark, accentColor),
        theme: buildTheme(Brightness.light, accentColor),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WrapGridPage(
          addScaffoldAndBar: true,
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              PlatformApi().closeApp();
            },
            child: ImageView.simple(
              cellCount: files.length,
              getContent: (i) => files[i].content(),
            ),
          ),
        ),
      ),
    ),
  );
}
