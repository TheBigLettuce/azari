import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/gallery/android_api/android_side.dart';
import 'package:gallery/src/gallery/android_api/interface_impl.dart';
import 'package:gallery/src/gallery/android_files.dart';
import 'package:gallery/src/gallery/interface.dart';
import 'package:gallery/src/pages/senitel.dart';
import 'package:gallery/src/schemas/android_gallery_directory.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:gallery/src/widgets/search_filter_grid.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';

import '../schemas/settings.dart';

class AndroidDirectories extends StatefulWidget {
  const AndroidDirectories({super.key});

  @override
  State<AndroidDirectories> createState() => _AndroidDirectoriesState();
}

class _AndroidDirectoriesState extends State<AndroidDirectories>
    with SearchFilterGrid {
  late StreamSubscription<Settings?> settingsWatcher;
  late final GridSkeletonStateFilter<SystemGalleryDirectory, String> state =
      GridSkeletonStateFilter(
          filterFunc: (value) => isarFilterFunc(
              value, state.gridKey.currentState?.mutationInterface, filter),
          index: kGalleryDrawerIndex,
          onWillPop: () => popUntilSenitel(context));
  final api = AndroidGallery();
  final stream = StreamController<int>(sync: true);

  @override
  void initState() {
    super.initState();
    settingsWatcher = settingsIsar().settings.watchObject(0).listen((event) {
      state.settings = event!;

      setState(() {});
    });
    searchHook(state, "directories"); // TODO: change
    api.callback = (i, inRefresh) {
      if (!inRefresh) {
        state.gridKey.currentState?.mutationInterface?.setIsRefreshing(false);
      }

      stream.add(i);
    };
    api.refresh = _refresh;
  }

  List<SystemGalleryDirectory> _getCells(int offset, int limit, String v) {
    return api.db.systemGalleryDirectorys
        .filter()
        .nameContains(v, caseSensitive: false)
        .offset(offset)
        .limit(limit)
        .findAllSync();
  }

  late final filter = IsarFilter<SystemGalleryDirectory, String>(
      api.db, openAndroidGalleryIsar(temporary: true), _getCells);

  @override
  void dispose() {
    api.close();
    stream.close();
    filter.dispose();
    settingsWatcher.cancel();
    disposeSearch();
    state.dispose();
    api.refresh = null;
    api.callback = null;
    clearTemporaryImagesDir();
    super.dispose();
  }

  void _refresh() async {
    try {
      stream.add(0);
      state.gridKey.currentState?.mutationInterface?.setIsRefreshing(true);
      final db = GalleryImpl.instance().db;
      db.writeTxnSync(() => db.systemGalleryDirectorys.clearSync());
      const MethodChannel channel = MethodChannel("lol.bruh19.azari.gallery");
      channel.invokeMethod("refreshGallery");
      // Navigator.pop(context);
      // var res = await api.directories();

      // setState(() {
      //   result = res;
      // });
    } catch (e, trace) {
      log("android gallery",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
    }
  }

  @override
  Widget build(BuildContext context) {
    var insets = MediaQuery.viewPaddingOf(context);

    return makeGridSkeleton<SystemGalleryDirectory, String>(
        context,
        state,
        CallbackGrid(
            key: state.gridKey,
            getCell: (i) => api.directCell(i),
            initalScrollPosition: 0,
            scaffoldKey: state.scaffoldKey,
            systemNavigationInsets: insets,
            hasReachedEnd: () => true,
            aspectRatio:
                state.settings.gallerySettings.directoryAspectRatio?.value ?? 1,
            hideAlias: state.settings.gallerySettings.hideDirectoryName,
            immutable: false,
            mainFocus: state.mainFocus,
            searchWidget: SearchAndFocus(searchWidget(context), searchFocus),
            refresh: () {
              _refresh();

              return null;
            },
            overrideOnPress: (context, indx) {
              var d =
                  state.gridKey.currentState!.mutationInterface!.getCell(indx);
              var apiFiles = api.images(d) as AndroidGalleryFiles;
              api.currentImages = apiFiles;

              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AndroidFiles(
                        api: apiFiles, dirName: d.name, bucketId: d.bucketId),
                  ));
            },
            progressTicker: stream.stream,
            updateScrollPosition: (pos, {infoPos, selectedCell}) {},
            description: GridDescription(
                kGalleryDrawerIndex,
                [
                  GridBottomSheetAction(Icons.hide_image_outlined, (selected) {
                    api.addBlacklisted(selected);
                  }, true)
                ],
                state.settings.gallerySettings.directoryColumns ??
                    GridColumn.two,
                keybindsDescription: "Android Gallery"))); // TODO: change
  }
}
