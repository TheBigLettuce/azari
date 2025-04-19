// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "main.dart";

/// Entrypoint for the third Android's Activity.
/// Shows the image or video from ACTION_VIEW.
@pragma("vm:entry-point")
Future<void> mainQuickView() async {
  await initMain(AppInstanceType.quickView);

  final accentColor = const AppApi().accentColor;

  final uris = await const MethodChannel(
    "com.github.thebiglettuce.azari.activity_context",
  ).invokeListMethod<String>("getQuickViewUris").then((e) => e!);

  final files = (await platform.GalleryHostApi().getUriPicturesDirectly(uris))
      .map(
        (e) => File(
          width: e.width,
          height: e.height,
          originalUri: e.uri,
          name: e.name,
          lastModified: e.lastModified,
          size: e.size,
          id: -1,
          bucketId: "",
          isVideo: e.isVideo,
          isGif: e.isGif,
          isDuplicate: false,
          tags: const {},
          res: ParsedFilenameResult.simple(e.name),
        ),
      )
      .toList();

  final source = GenericListSource<File>(
    () => Future.value(files),
  );
  await source.clearRefresh();

  runApp(
    injectWidgetEvents(
      _GalleryDataHolder(
        source: source,
        child: (stateController) {
          return MaterialApp(
            title: "Azari",
            themeAnimationCurve: Easing.standard,
            themeAnimationDuration: const Duration(milliseconds: 300),
            darkTheme: buildTheme(Brightness.dark, accentColor),
            theme: buildTheme(Brightness.light, accentColor),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ScaffoldSelectionBar(
              addScaffoldAndBar: true,
              child: PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) =>
                    const AppApi().close(),
                child: ImageView(stateController: stateController),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _GalleryDataHolder extends StatefulWidget {
  const _GalleryDataHolder({
    // super.key,
    required this.source,
    required this.child,
  });

  final GenericListSource<File> source;

  final Widget Function(PlatformImageViewStateImpl impl) child;

  @override
  State<_GalleryDataHolder> createState() => __GalleryDataHolderState();
}

class __GalleryDataHolderState extends State<_GalleryDataHolder> {
  late final PlatformImageViewStateImpl impl;

  @override
  void initState() {
    super.initState();

    impl = PlatformImageViewStateImpl(
      source: widget.source,
      wrapNotifiers: (child) => child,
      onTagPressed: null,
      onTagLongPressed: null,
    );

    platform.GalleryVideoEvents.setUp(impl);
    platform.FlutterGalleryData.setUp(impl);
  }

  @override
  void dispose() {
    platform.FlutterGalleryData.setUp(null);
    platform.GalleryVideoEvents.setUp(null);

    impl.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child(impl);
  }
}
