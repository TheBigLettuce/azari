// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "main.dart";

/// Entrypoint for the third Android's Activity.
/// Shows the image or video from ACTION_VIEW.
@pragma("vm:entry-point")
Future<void> mainQuickView() async {
  await initMain(true);

  final accentColor = await PlatformApi.current().accentColor();

  final uris = await const AndroidApiFunctions().getQuickViewUris();

  final files = (await GalleryHostApi().getUriPicturesDirectly(uris))
      .map((e) => AndroidUriFile.fromUriFile(e!))
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
          addScaffold: true,
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              const AndroidApiFunctions().closeActivity();
            },
            child: ImageView(
              cellCount: files.length,
              scrollUntill: (_) {},
              startingCell: 0,
              getCell: (i) => files[i].content(),
              onNearEnd: null,
            ),
          ),
        ),
      ),
    ),
  );
}
