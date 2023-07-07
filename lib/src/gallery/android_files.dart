import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/gallery/android_api/android_side.dart';
import 'package:gallery/src/gallery/android_api/interface_impl.dart';
import 'package:gallery/src/gallery/interface.dart';
import 'package:gallery/src/pages/senitel.dart';
import 'package:gallery/src/schemas/android_gallery_directory.dart';
import 'package:gallery/src/schemas/android_gallery_directory_file.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:logging/logging.dart';

import '../schemas/settings.dart';

class AndroidFiles extends StatefulWidget {
  final String dirName;
  final String dirId;
  final AndroidGalleryFiles api;
  const AndroidFiles(
      {super.key,
      required this.api,
      required this.dirName,
      required this.dirId});

  @override
  State<AndroidFiles> createState() => _AndroidFilesState();
}

class _AndroidFilesState extends State<AndroidFiles> {
  late final GridSkeletonState<SystemGalleryDirectoryFile, void> state =
      GridSkeletonState(
          index: kGalleryDrawerIndex,
          onWillPop: () => popUntilSenitel(context));
  final stream = StreamController<int>(sync: true);
  Result<SystemGalleryDirectoryFile>? result;

  @override
  void initState() {
    super.initState();
    widget.api.callback = (i) {
      stream.add(i);
    };
  }

  @override
  void dispose() {
    widget.api.close();
    stream.close();
    state.dispose();
    super.dispose();
  }

  Future<int> _refresh() async {
    try {
      var res = await widget.api.refresh();

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
            aspectRatio: 1,
            mainFocus: state.mainFocus,
            menuButtonItems: [
              FilledButton(
                  onPressed: () {
                    stream.add(0);
                    final db = widget.api.db;
                    db.writeTxnSync(
                        () => db.systemGalleryDirectoryFiles.clearSync());

                    const MethodChannel _channel =
                        MethodChannel("lol.bruh19.azari.gallery");
                    _channel.invokeMethod("refreshFiles", widget.dirId);
                    Navigator.pop(context);
                  },
                  child: Text("Deep refresh"))
            ],
            refresh: _refresh,
            progressTicker: stream.stream,
            updateScrollPosition: (pos, {infoPos, selectedCell}) {},
            description: GridDescription(
                kGalleryDrawerIndex, [], GridColumn.two,
                keybindsDescription: widget.dirName)));
  }
}
