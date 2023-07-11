// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:gallery/src/gallery/server_api/server_files.dart';
import 'package:gallery/src/gallery/server_api/modify_directory.dart';
import 'package:gallery/src/pages/senitel.dart';
import 'package:gallery/src/schemas/directory.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:logging/logging.dart';
import '../../db/isar.dart' as db;
import '../../widgets/drawer/drawer.dart';
import '../../widgets/grid/callback_grid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../widgets/search_filter_grid.dart';
import 'server_api_directories.dart';

class ServerDirectories extends StatefulWidget {
  const ServerDirectories({super.key});

  @override
  State<ServerDirectories> createState() => _ServerDirectoriesState();
}

class _ServerDirectoriesState extends State<ServerDirectories>
    with SearchFilterGrid<Directory, Directory> {
  late StreamSubscription<Settings?> settingsWatcher;
  bool isDisposed = false;

  final api = getServerGalleryApi();

  late final GridSkeletonStateFilter<Directory, Directory> skeletonState =
      GridSkeletonStateFilter(
          filter: api.getExtra().filter,
          index: kGalleryDrawerIndex,
          onWillPop: () => popUntilSenitel(context));

  @override
  void initState() {
    super.initState();

    searchHook(skeletonState);

    settingsWatcher = db.settingsIsar().settings.watchObject(0).listen((event) {
      skeletonState.settings = event!;

      setState(() {});
    });
  }

  @override
  void dispose() {
    isDisposed = true;

    settingsWatcher.cancel();

    disposeSearch();

    skeletonState.dispose();
    api.close();

    super.dispose();
  }

  void _setThumbnail(String hash, Directory d) async {
    try {
      await api.modify(d, d.copy(imageHash: hash));

      skeletonState.gridKey.currentState!.refresh();
    } catch (e, trace) {
      //progressTicker: thumbnailWatcher,
      log("setting thumbnail",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
    }
  }

  @override
  Widget build(BuildContext context) {
    var insets = MediaQuery.viewPaddingOf(context);

    return makeGridSkeleton<Directory, Directory>(
      context,
      skeletonState,
      CallbackGrid(
        mainFocus: skeletonState.mainFocus,
        systemNavigationInsets: insets,
        key: skeletonState.gridKey,
        aspectRatio: skeletonState
                .settings.gallerySettings.directoryAspectRatio?.value ??
            1,
        description: GridDescription(
            kGalleryDrawerIndex,
            [
              GridBottomSheetAction(Icons.info_outline, (selected) {
                var d = selected.first;

                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return ModifyDirectory(
                    api,
                    old: d,
                    refreshKey: skeletonState.gridKey,
                  );
                }));
              }, false, showOnlyWhenSingle: true)
            ],
            skeletonState.settings.gallerySettings.directoryColumns ??
                GridColumn.two,
            keybindsDescription: AppLocalizations.of(context)!.galleryPageName,
            listView: skeletonState.settings.listViewBooru),
        updateScrollPosition: (pos, {double? infoPos, int? selectedCell}) {},
        scaffoldKey: skeletonState.scaffoldKey,
        hasReachedEnd: () => true,
        refresh: () => api.refresh(),
        searchWidget: SearchAndFocus(searchWidget(context), searchFocus),
        hideAlias: skeletonState.settings.gallerySettings.hideDirectoryName,
        initalScrollPosition: 0,
        menuButtonItems: [
          TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    DialogRoute(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(AppLocalizations.of(context)!
                                .chooseDirectoryName),
                            content: TextField(
                              onSubmitted: (value) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            AppLocalizations.of(context)!
                                                .uploadStarted)));
                                api.newDirectory(value, () {
                                  if (!isDisposed) {
                                    skeletonState.gridKey.currentState
                                        ?.refresh();
                                  }
                                }).then((value) {
                                  skeletonState.gridKey.currentState!.refresh();
                                }).onError((error, stackTrace) {
                                  log("adding file to server",
                                      level: Level.SEVERE.value,
                                      error: error,
                                      stackTrace: stackTrace);
                                });
                              },
                            ),
                          );
                        }));
              },
              child: Text(AppLocalizations.of(context)!.newDirectory))
        ],
        getCell: (i) => api.directCell(i),
        immutable: false,
        hideShowFab: ({required bool fab, required bool foreground}) =>
            skeletonState.updateFab(setState,
                fab: fab,
                foreground:
                    foreground), //isar.directorys.getSync(i + 1)!.cell()
        overrideOnPress: (context, indx) {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            var d = skeletonState.gridKey.currentState!.mutationInterface!
                .getCell(indx);

            return Images(
              api.imagesReadWrite(d),
              cell: d,
              parentFocus: skeletonState.mainFocus,
              setThumbnail: _setThumbnail,
              parentGrid: skeletonState.gridKey,
            );
          }));
        },
      ),
    );
  }
}
