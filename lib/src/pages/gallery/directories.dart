// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:gallery/src/plugs/gallery.dart';
import 'package:gallery/src/widgets/copy_move_preview.dart';
import 'package:gallery/src/widgets/grid/actions/favorites.dart';
import 'package:gallery/src/widgets/grid/actions/gallery_directories.dart';
import 'package:gallery/src/db/post_tags.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/plugs/platform_channel.dart';
import 'package:gallery/src/pages/gallery/files.dart';
import 'package:gallery/src/pages/booru/main.dart';
import 'package:gallery/src/db/schemas/system_gallery_directory.dart';
import 'package:gallery/src/db/schemas/system_gallery_directory_file.dart';
import 'package:gallery/src/db/schemas/favorite_media.dart';
import 'package:gallery/src/db/schemas/pinned_directories.dart';
import 'package:gallery/src/db/schemas/tags.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/search_bar/search_filter_grid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';

import '../../interfaces/booru.dart';
import '../../db/schemas/settings.dart';
import '../../interfaces/filtering/filtering_mode.dart';
import '../../widgets/skeletons/grid_skeleton_state_filter.dart';
import '../../widgets/skeletons/make_grid_skeleton.dart';

class CallbackDescription {
  final Future<void> Function(SystemGalleryDirectory? chosen, String? newDir) c;
  final String description;

  final PreferredSizeWidget? preview;

  final bool joinable;

  void call(SystemGalleryDirectory? chosen, String? newDir) {
    c(chosen, newDir);
  }

  const CallbackDescription(this.description, this.c,
      {this.preview, required this.joinable});
}

class CallbackDescriptionNested {
  final void Function(SystemGalleryDirectoryFile chosen) c;
  final String description;

  void call(SystemGalleryDirectoryFile chosen) {
    c(chosen);
  }

  const CallbackDescriptionNested(this.description, this.c);
}

class GalleryDirectories extends StatefulWidget {
  final CallbackDescription? callback;
  final CallbackDescriptionNested? nestedCallback;
  final bool? noDrawer;
  final bool showBackButton;
  final Future<bool> Function() procPop;
  final SelectionGlue<SystemGalleryDirectory> glue;
  final double bottomPadding;

  const GalleryDirectories(
      {super.key,
      this.callback,
      this.nestedCallback,
      this.noDrawer,
      required this.glue,
      required this.procPop,
      this.bottomPadding = 0,
      this.showBackButton = false})
      : assert(!(callback != null && nestedCallback != null));

  @override
  State<GalleryDirectories> createState() => _GalleryDirectoriesState();
}

class _GalleryDirectoriesState extends State<GalleryDirectories>
    with SearchFilterGrid<SystemGalleryDirectory> {
  late StreamSubscription<Settings?> settingsWatcher;
  bool proceed = true;
  late final extra = api.getExtra()
    ..setRefreshGridCallback(() {
      if (widget.callback != null) {
        stream.add(0);
        state.gridKey.currentState?.mutationInterface?.setIsRefreshing(true);
      } else {
        if (state.gridKey.currentState?.mutationInterface?.isRefreshing ==
            false) {
          _refresh();
        }
      }
    });

  late final GridSkeletonStateFilter<SystemGalleryDirectory> state =
      GridSkeletonStateFilter(
    transform: (cell, _) => cell,
    filter: extra.filter,
  );
  late final api = chooseGalleryPlug().galleryApi(
      temporaryDb: widget.callback != null || widget.nestedCallback != null,
      setCurrentApi: widget.callback == null);
  final stream = StreamController<int>(sync: true);

  bool isThumbsLoading = false;

  int? trashThumbId;

  @override
  void initState() {
    super.initState();
    if (widget.callback != null) {
      extra.setTemporarySet((i, end) {
        stream.add(i);

        if (end) {
          state.gridKey.currentState?.mutationInterface?.setIsRefreshing(false);
        }
      });
    }

    settingsWatcher = Settings.watch((s) {
      state.settings = s!;
      setState(() {});
    });

    searchHook(state);

    if (widget.callback != null) {
      PlatformFunctions.trashThumbId().then((value) {
        try {
          setState(() {
            trashThumbId = value;
          });
        } catch (_) {}
      });
    }

    extra.setRefreshingStatusCallback((i, inRefresh, empty) {
      state.gridKey.currentState?.mutationInterface?.unselectAll();

      stream.add(i);

      if (!inRefresh || empty) {
        state.gridKey.currentState?.mutationInterface?.setIsRefreshing(false);
        performSearch(searchTextController.text);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    api.close();
    stream.close();
    settingsWatcher.cancel();
    disposeSearch();
    state.dispose();
    Dbs.g.clearTemporaryImages();

    super.dispose();
  }

  void _refresh() {
    PlatformFunctions.trashThumbId().then((value) {
      try {
        setState(() {
          trashThumbId = value;
        });
      } catch (_) {}
    });
    stream.add(0);
    state.gridKey.currentState?.mutationInterface?.setIsRefreshing(true);
    api.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return makeGridSkeleton<SystemGalleryDirectory>(
        context,
        state,
        CallbackGrid(
            key: state.gridKey,
            getCell: (i) => api.directCell(i),
            initalScrollPosition: 0,
            scaffoldKey: state.scaffoldKey,
            onBack: widget.showBackButton ? () => Navigator.pop(context) : null,
            systemNavigationInsets: EdgeInsets.only(
                bottom: MediaQuery.of(context).systemGestureInsets.bottom +
                    (widget.glue.isOpen() ? 80 : widget.bottomPadding)),
            hasReachedEnd: () => true,
            showCount: true,
            selectionGlue: widget.glue,
            addFabPadding: widget.callback != null ||
                widget.nestedCallback != null ||
                !widget.glue.isOpen(),
            inlineMenuButtonItems: true,
            menuButtonItems: [
              if (widget.callback != null)
                IconButton(
                    onPressed: () async {
                      try {
                        widget.callback!(
                            null,
                            await PlatformFunctions.chooseDirectory(
                                temporary: true));
                        // ignore: use_build_context_synchronously
                        Navigator.pop(context);
                      } catch (e) {
                        log("new folder in android_directories",
                            level: Level.SEVERE.value, error: e);
                        // ignore: use_build_context_synchronously
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.create_new_folder_outlined)),
              gridSettingsButton(state.settings.galleryDirectories,
                  selectRatio: (ratio) => state.settings
                      .copy(
                          galleryDirectories: state.settings.galleryDirectories
                              .copy(aspectRatio: ratio))
                      .save(),
                  selectHideName: (hideNames) => state.settings
                      .copy(
                          galleryDirectories: state.settings.galleryDirectories
                              .copy(hideName: hideNames))
                      .save(),
                  selectListView: null,
                  selectGridColumn: (columns) => state.settings
                      .copy(
                          galleryDirectories: state.settings.galleryDirectories
                              .copy(columns: columns))
                      .save()),
            ],
            aspectRatio: state.settings.galleryDirectories.aspectRatio.value,
            hideAlias: state.settings.galleryDirectories.hideName,
            immutable: false,
            segments: Segments(
              "Uncategorized",
              segment: (cell) {
                for (final booru in Booru.values) {
                  if (booru.url == cell.name) {
                    return ("Booru", true);
                  }
                }

                final dirTag = PostTags.g.directoryTag(cell.bucketId);
                if (dirTag != null) {
                  return (
                    dirTag,
                    Dbs.g.blacklisted.pinnedDirectories
                            .getSync(fastHash(dirTag)) !=
                        null
                  );
                }

                final name = cell.name.split(" ");
                return (
                  name.first.toLowerCase(),
                  Dbs.g.blacklisted.pinnedDirectories
                          .getSync(fastHash(name.first.toLowerCase())) !=
                      null
                );
              },
              addToSticky: (seg, {unsticky}) {
                if (seg == "Booru" || seg == "Special") {
                  return false;
                }
                if (unsticky == true) {
                  Dbs.g.blacklisted.writeTxnSync(() {
                    Dbs.g.blacklisted.pinnedDirectories
                        .deleteSync(fastHash(seg));
                  });
                } else {
                  Dbs.g.blacklisted.writeTxnSync(() {
                    Dbs.g.blacklisted.pinnedDirectories
                        .putSync(PinnedDirectories(seg, DateTime.now()));
                  });
                }

                return true;
              },
              injectedSegments: [
                if (Dbs.g.blacklisted.favoriteMedias.countSync() != 0)
                  SystemGalleryDirectory(
                      bucketId: "favorites",
                      name: "Favorites", // change
                      tag: "",
                      volumeName: "",
                      relativeLoc: "",
                      lastModified: 0,
                      thumbFileId: Dbs.g.blacklisted.favoriteMedias
                          .where()
                          .sortByTimeDesc()
                          .findFirstSync()!
                          .id),
                if (trashThumbId != null)
                  SystemGalleryDirectory(
                      bucketId: "trash",
                      name: "Trash", // change
                      tag: "",
                      volumeName: "",
                      relativeLoc: "",
                      lastModified: 0,
                      thumbFileId: trashThumbId!),
              ],
              onLabelPressed:
                  widget.callback != null && !widget.callback!.joinable
                      ? null
                      : (label, children) =>
                          SystemGalleryDirectoriesActions.joinedDirectoriesFnc(
                              context,
                              label,
                              children,
                              extra,
                              widget.nestedCallback),
            ),
            mainFocus: state.mainFocus,
            footer: widget.callback?.preview,
            initalCellCount: widget.callback != null
                ? extra.db.systemGalleryDirectorys.countSync()
                : 0,
            searchWidget: SearchAndFocus(
                searchWidget(context,
                    hint: AppLocalizations.of(context)!.directoriesHint),
                searchFocus),
            refresh: () {
              if (widget.callback != null) {
                PlatformFunctions.trashThumbId().then((value) {
                  try {
                    setState(() {
                      trashThumbId = value;
                    });
                  } catch (_) {}
                });
                return Future.value(
                    extra.db.systemGalleryDirectorys.countSync());
              } else {
                _refresh();

                return null;
              }
            },
            showSearchBarFirst: widget.callback != null,
            overrideOnPress: (context, cell) {
              if (widget.callback != null) {
                widget.callback!.c(cell, null).then((_) {
                  Navigator.pop(context);
                });
              } else {
                final d = cell;

                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => switch (cell.bucketId) {
                        "favorites" => GalleryFiles(
                            api: extra.favorites(),
                            callback: widget.nestedCallback,
                            dirName: "favorites",
                            bucketId: "favorites"),
                        "trash" => GalleryFiles(
                            api: extra.trash(),
                            callback: widget.nestedCallback,
                            dirName: "trash",
                            bucketId: "trash"),
                        String() => GalleryFiles(
                            api: api.files(d),
                            dirName: d.name,
                            callback: widget.nestedCallback,
                            bucketId: d.bucketId)
                      },
                    ));
              }
            },
            progressTicker: stream.stream,
            description: GridDescription(
                widget.callback != null || widget.nestedCallback != null
                    ? [
                        if (widget.callback == null ||
                            widget.callback!.joinable)
                          SystemGalleryDirectoriesActions.joinedDirectories(
                              context, extra, widget.nestedCallback)
                      ]
                    : [
                        FavoritesActions.addToGroup(context, (selected) {
                          final t = selected.first.tag;
                          for (final e in selected.skip(1)) {
                            if (t != e.tag) {
                              return null;
                            }
                          }

                          return t;
                        }, (selected, value) {
                          if (value.isEmpty) {
                            PostTags.g.removeDirectoriesTag(
                                selected.map((e) => e.bucketId));
                          } else {
                            PostTags.g.setDirectoriesTag(
                                selected.map((e) => e.bucketId), value);
                          }

                          _refresh();

                          Navigator.pop(context);
                        }),
                        SystemGalleryDirectoriesActions.blacklist(
                            context, extra),
                        SystemGalleryDirectoriesActions.joinedDirectories(
                            context, extra, widget.nestedCallback)
                      ],
                state.settings.galleryDirectories.columns,
                listView: false,
                bottomWidget:
                    widget.callback != null || widget.nestedCallback != null
                        ? CopyMovePreview.hintWidget(
                            context,
                            widget.callback != null
                                ? widget.callback!.description
                                : widget.nestedCallback!.description)
                        : null,
                keybindsDescription:
                    AppLocalizations.of(context)!.androidGKeybindsDescription)),
        noDrawer: widget.noDrawer ?? false, overrideOnPop: () {
      final filterMode = currentFilteringMode();
      if (filterMode != FilteringMode.noFilter ||
          searchTextController.text.isNotEmpty) {
        resetSearch();
        return Future.value(false);
      }

      if (widget.glue.isOpen()) {
        state.gridKey.currentState?.selection.reset();
        return Future.value(false);
      }

      return widget.procPop();
    });
  }
}
