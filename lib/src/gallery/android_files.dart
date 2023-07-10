import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/gallery/android_api/android_side.dart';
import 'package:gallery/src/gallery/android_api/interface_impl.dart';
import 'package:gallery/src/gallery/interface.dart';
import 'package:gallery/src/pages/senitel.dart';
import 'package:gallery/src/schemas/android_gallery_directory.dart';
import 'package:gallery/src/schemas/android_gallery_directory_file.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';

import '../schemas/settings.dart';
import '../widgets/search_filter_grid.dart';

class AndroidFiles extends StatefulWidget {
  final String dirName;
  final String bucketId;
  final AndroidGalleryFiles api;
  const AndroidFiles(
      {super.key,
      required this.api,
      required this.dirName,
      required this.bucketId});

  @override
  State<AndroidFiles> createState() => _AndroidFilesState();
}

class _AndroidFilesState extends State<AndroidFiles>
    with SearchFilterGrid<SystemGalleryDirectoryFile, void> {
  late StreamSubscription<Settings?> settingsWatcher;
  late final GridSkeletonStateFilter<SystemGalleryDirectoryFile, void> state =
      GridSkeletonStateFilter(
          filterFunc: (value) => isarFilterFunc(
              value, state.gridKey.currentState?.mutationInterface, filter),
          index: kGalleryDrawerIndex,
          onWillPop: () => Future.value(true));
  final stream = StreamController<int>(sync: true);
  bool isThumbsLoading = false;

  List<SystemGalleryDirectoryFile> _getElems(int offset, int limit, String s) {
    return widget.api.db.systemGalleryDirectoryFiles
        .filter()
        .nameContains(s, caseSensitive: false)
        .offset(offset)
        .limit(limit)
        .findAllSync();
  }

  late final filter = IsarFilter<SystemGalleryDirectoryFile, void>(
      widget.api.db, openAndroidGalleryInnerIsar(), _getElems);

  @override
  void initState() {
    super.initState();

    settingsWatcher = settingsIsar().settings.watchObject(0).listen((event) {
      state.settings = event!;

      setState(() {});
    });
    searchHook(state, widget.dirName, [
      IconButton(
          onPressed: () {
            var settings = settingsIsar().settings.getSync(0)!;
            settingsIsar().writeTxnSync(() => settingsIsar().settings.putSync(
                settings.copy(
                    gallerySettings: settings.gallerySettings.copy(
                        hideFileName: !(settings.gallerySettings.hideFileName ??
                            false)))));
          },
          icon: const Icon(Icons.subtitles))
    ]);
    widget.api.callback = (i, inRefresh) {
      if (!inRefresh) {
        state.gridKey.currentState?.mutationInterface?.setIsRefreshing(false);
      }

      stream.add(i);
    };
  }

  void _nextThumbnails(int i) {
    if (isThumbsLoading) {
      return;
    }

    isThumbsLoading = true;

    _thumbs(i);
  }

  void _thumbs(int from) async {
    try {
      final db = filter.isFiltering ? filter.to : widget.api.db;
      var thumbs = db.systemGalleryDirectoryFiles
          .where()
          .offset(from)
          .limit(from == 0 ? 20 : from + 20)
          .findAllSync()
          .map((e) => e.id)
          .toList();
      const MethodChannel channel = MethodChannel("lol.bruh19.azari.gallery");
      await channel.invokeMethod("loadThumbnails", thumbs);
      setState(() {});
    } catch (e, trace) {
      log("loading thumbs",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
    }
    isThumbsLoading = false;
  }

  @override
  void dispose() {
    widget.api.close();
    stream.close();
    settingsWatcher.cancel();
    disposeSearch();
    state.dispose();
    super.dispose();
  }

  void _refresh() async {
    try {
      stream.add(0);
      state.gridKey.currentState?.mutationInterface?.setIsRefreshing(true);
      final db = widget.api.db;
      db.writeTxnSync(() => db.systemGalleryDirectoryFiles.clearSync());

      const MethodChannel channel = MethodChannel("lol.bruh19.azari.gallery");
      channel.invokeMethod("refreshFiles", widget.bucketId);
    } catch (e, trace) {
      log("android gallery",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
    }
  }

  @override
  Widget build(BuildContext context) {
    var insets = MediaQuery.viewPaddingOf(context);

    return makeGridSkeleton<SystemGalleryDirectoryFile, void>(
        context,
        state,
        CallbackGrid(
            key: state.gridKey,
            getCell: (i) => widget.api.directCell(i),
            initalScrollPosition: 0,
            scaffoldKey: state.scaffoldKey,
            systemNavigationInsets: insets,
            hasReachedEnd: () => true,
            immutable: false,
            tightMode: true,
            aspectRatio:
                state.settings.gallerySettings.filesAspectRatio?.value ?? 1,
            hideAlias: state.settings.gallerySettings.hideFileName,
            loadThumbsDirectly: _nextThumbnails,
            searchWidget: SearchAndFocus(searchWidget(context), searchFocus),
            mainFocus: state.mainFocus,
            refresh: () {
              _refresh();
              return null;
            },
            onBack: () {
              Navigator.pop(context);
            },
            progressTicker: stream.stream,
            updateScrollPosition: (pos, {infoPos, selectedCell}) {},
            description: GridDescription(kGalleryDrawerIndex, [],
                state.settings.gallerySettings.filesColumns ?? GridColumn.two,
                keybindsDescription: widget.dirName)));
  }
}
