// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/gallery/android_api/android_api_directories.dart';
import 'package:gallery/src/gallery/android_api/android_files.dart';
import 'package:gallery/src/pages/senitel.dart';
import 'package:gallery/src/schemas/android_gallery_directory.dart';
import 'package:gallery/src/schemas/blacklisted_directory.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:gallery/src/widgets/search_filter_grid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../schemas/settings.dart';

class CallbackDescription {
  final void Function(SystemGalleryDirectoryShrinked chosen) c;
  final String description;

  void call(SystemGalleryDirectoryShrinked chosen) {
    c(chosen);
  }

  const CallbackDescription(this.description, this.c);
}

class AndroidDirectories extends StatefulWidget {
  final CallbackDescription? callback;
  const AndroidDirectories({super.key, this.callback});

  @override
  State<AndroidDirectories> createState() => _AndroidDirectoriesState();
}

class _AndroidDirectoriesState extends State<AndroidDirectories>
    with SearchFilterGrid {
  late StreamSubscription<Settings?> settingsWatcher;
  late final extra = api.getExtra()
    ..setOnThumbnailCallback(() {
      setState(() {});
    })
    ..setRefreshGridCallback(_refresh);

  late final GridSkeletonStateFilter<SystemGalleryDirectory,
          SystemGalleryDirectoryShrinked> state =
      GridSkeletonStateFilter(
          filter: extra.filter,
          index: kGalleryDrawerIndex,
          onWillPop: () => popUntilSenitel(context));
  late final api = getAndroidGalleryApi(temporary: widget.callback != null);
  final stream = StreamController<int>(sync: true);

  bool isThumbsLoading = false;

  @override
  void initState() {
    super.initState();
    settingsWatcher = settingsIsar().settings.watchObject(0).listen((event) {
      state.settings = event!;

      setState(() {});
    });
    searchHook(state);

    extra.setRefreshingStatusCallback((i, inRefresh, empty) {
      state.gridKey.currentState?.mutationInterface?.unselectAll();

      if (!inRefresh || empty) {
        state.gridKey.currentState?.mutationInterface?.setIsRefreshing(false);
        setState(() {});
      }

      stream.add(i);
    });
  }

  @override
  void dispose() {
    api.close();
    stream.close();
    settingsWatcher.cancel();
    disposeSearch();
    state.dispose();
    clearTemporaryImagesDir();
    super.dispose();
  }

  void _refresh() {
    stream.add(0);
    state.gridKey.currentState?.mutationInterface?.setIsRefreshing(true);
    api.refresh();
  }

  @override
  Widget build(BuildContext context) {
    var insets = MediaQuery.viewPaddingOf(context);

    return makeGridSkeleton<SystemGalleryDirectory,
            SystemGalleryDirectoryShrinked>(
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
            loadThumbsDirectly: extra.loadThumbs,
            initalCellCount: widget.callback != null
                ? GalleryImpl.instance().db.systemGalleryDirectorys.countSync()
                : 0,
            searchWidget: SearchAndFocus(
                searchWidget(context,
                    hint: AppLocalizations.of(context)!.directoriesHint),
                searchFocus),
            refresh: () {
              if (widget.callback == null) {
                _refresh();

                return null;
              } else {
                return Future.value(GalleryImpl.instance()
                    .db
                    .systemGalleryDirectorys
                    .countSync());
              }
            },
            overrideOnPress: (context, indx) {
              if (widget.callback != null) {
                widget.callback!(state.gridKey.currentState!.mutationInterface!
                    .getCell(indx)
                    .shrinkedData());
                Navigator.pop(context);
              } else {
                var d = state.gridKey.currentState!.mutationInterface!
                    .getCell(indx);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AndroidFiles(
                          api: api.imagesRead(d),
                          dirName: d.name,
                          bucketId: d.bucketId),
                    ));
              }
            },
            progressTicker: stream.stream,
            hideShowFab: ({required bool fab, required bool foreground}) =>
                state.updateFab(setState, fab: fab, foreground: foreground),
            description: GridDescription(
                kGalleryDrawerIndex,
                widget.callback != null
                    ? []
                    : [
                        GridBottomSheetAction(Icons.hide_image_outlined,
                            (selected) {
                          extra.addBlacklisted(selected
                              .map((e) =>
                                  BlacklistedDirectory(e.bucketId, e.name))
                              .toList());
                        }, true)
                      ],
                state.settings.gallerySettings.directoryColumns ??
                    GridColumn.two,
                listView: state.settings.listViewBooru,
                bottomWidget: widget.callback == null
                    ? null
                    : PreferredSize(
                        preferredSize: const Size.fromHeight(12),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            "Choose ${widget.callback!.description} destination",
                            style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.fontSize,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.8)),
                          ),
                        ), // TODO: change
                      ),
                keybindsDescription:
                    AppLocalizations.of(context)!.androidGKeybindsDescription)),
        popSenitel: widget.callback == null);
  }
}
