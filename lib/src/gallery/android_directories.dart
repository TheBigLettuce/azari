import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/gallery/android_api/android_side.dart';
import 'package:gallery/src/gallery/android_api/interface_impl.dart';
import 'package:gallery/src/gallery/android_files.dart';
import 'package:gallery/src/gallery/interface.dart';
import 'package:gallery/src/pages/senitel.dart';
import 'package:gallery/src/schemas/android_gallery_directory.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:logging/logging.dart';

import '../schemas/settings.dart';

class AndroidDirectories extends StatefulWidget {
  const AndroidDirectories({super.key});

  @override
  State<AndroidDirectories> createState() => _AndroidDirectoriesState();
}

class _AndroidDirectoriesState extends State<AndroidDirectories> {
  late final GridSkeletonState<SystemGalleryDirectory, void> state =
      GridSkeletonState(
          index: kGalleryDrawerIndex,
          onWillPop: () => popUntilSenitel(context));
  final api = AndroidGallery();
  final stream = StreamController<int>(sync: true);
  Result<SystemGalleryDirectory>? result;

  @override
  void initState() {
    super.initState();
    api.callback = (i) {
      stream.add(i);
    };
  }

  @override
  void dispose() {
    api.close();
    stream.close();
    state.dispose();
    api.callback = null;
    super.dispose();
  }

  Future<int> _refresh() async {
    try {
      var res = await api.directories();

      setState(() {
        result = res;
      });
    } catch (e, trace) {
      log("android gallery",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
    }

    return result?.count ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    var insets = MediaQuery.viewPaddingOf(context);

    return makeGridSkeleton<SystemGalleryDirectory, void>(
        context,
        state,
        CallbackGrid(
            key: state.gridKey,
            getCell: (i) => api.directCell(i),
            initalScrollPosition: 0,
            scaffoldKey: state.scaffoldKey,
            systemNavigationInsets: insets,
            hasReachedEnd: () => true,
            aspectRatio: 1,
            mainFocus: state.mainFocus,
            menuButtonItems: [
              FilledButton(
                  onPressed: () {
                    stream.add(0);
                    final db = GalleryImpl.instance().db;
                    db.writeTxnSync(
                        () => db.systemGalleryDirectorys.clearSync());

                    const MethodChannel channel =
                        MethodChannel("lol.bruh19.azari.gallery");
                    channel.invokeMethod("refreshGallery");
                    Navigator.pop(context);
                  },
                  child: Text("Deep refresh"))
            ],
            refresh: _refresh,
            overrideOnPress: (context, indx) {
              var d = api.directCell(indx);
              var apiFiles = api.images(d) as AndroidGalleryFiles;
              api.currentImages = apiFiles;

              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AndroidFiles(
                        api: apiFiles, dirName: d.name, dirId: d.id),
                  ));
            },
            progressTicker: stream.stream,
            updateScrollPosition: (pos, {infoPos, selectedCell}) {},
            description: GridDescription(
                kGalleryDrawerIndex, [], GridColumn.two,
                keybindsDescription: "Android Gallery")));
  }
}
