// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/gallery/system_gallery_directory_file.dart';
import 'package:gallery/src/db/schemas/grid_settings/directories.dart';
import 'package:gallery/src/db/schemas/settings/misc_settings.dart';
import 'package:gallery/src/db/schemas/statistics/statistics_gallery.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/grid/selection_glue.dart';
import 'package:gallery/src/interfaces/logging/logging.dart';
import 'package:gallery/src/pages/booru/grid_button.dart';
import 'package:gallery/src/pages/booru/grid_settings_button.dart';
import 'package:gallery/src/plugs/gallery.dart';
import 'package:gallery/src/widgets/copy_move_preview.dart';
import 'package:gallery/src/widgets/grid/actions/favorites.dart';
import 'package:gallery/src/widgets/grid/actions/gallery_directories.dart';
import 'package:gallery/src/db/tags/post_tags.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/plugs/platform_functions.dart';
import 'package:gallery/src/pages/gallery/files.dart';
import 'package:gallery/src/db/schemas/gallery/system_gallery_directory.dart';
import 'package:gallery/src/db/schemas/gallery/favorite_booru_post.dart';
import 'package:gallery/src/db/schemas/gallery/pinned_directories.dart';
import 'package:gallery/src/widgets/grid/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid/configuration/grid_on_cell_press_behaviour.dart';
import 'package:gallery/src/widgets/grid/configuration/grid_search_widget.dart';
import 'package:gallery/src/widgets/grid/configuration/image_view_description.dart';
import 'package:gallery/src/widgets/grid/grid_frame.dart';
import 'package:gallery/src/widgets/grid/layouts/grid_layout.dart';
import 'package:gallery/src/widgets/grid/layouts/segment_layout.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/search_bar/search_filter_grid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../db/schemas/settings/settings.dart';
import '../../interfaces/filtering/filtering_mode.dart';
import '../../widgets/skeletons/grid_skeleton_state_filter.dart';
import '../../widgets/skeletons/grid_skeleton.dart';
import 'callback_description.dart';
import 'callback_description_nested.dart';

class GalleryDirectories extends StatefulWidget {
  final CallbackDescription? callback;
  final CallbackDescriptionNested? nestedCallback;
  final bool showBackButton;
  final void Function(bool) procPop;
  final EdgeInsets? viewPadding;

  const GalleryDirectories({
    super.key,
    this.callback,
    this.nestedCallback,
    this.viewPadding,
    required this.procPop,
    this.showBackButton = false,
  }) : assert(!(callback != null && nestedCallback != null));

  @override
  State<GalleryDirectories> createState() => _GalleryDirectoriesState();
}

class _GalleryDirectoriesState extends State<GalleryDirectories>
    with SearchFilterGrid<SystemGalleryDirectory> {
  static const _log = LogTarget.gallery;

  late final StreamSubscription<Settings?> settingsWatcher;
  late final StreamSubscription<MiscSettings?> miscSettingsWatcher;
  late final AppLifecycleListener lifecycleListener;

  MiscSettings miscSettings = MiscSettings.current;

  int galleryVersion = 0;

  bool proceed = true;
  late final extra = api.getExtra()
    ..setRefreshGridCallback(() {
      if (widget.callback != null) {
        stream.add(0);
        state.gridKey.currentState?.mutation.isRefreshing = true;
      } else {
        if (state.gridKey.currentState?.mutation.isRefreshing == false) {
          _refresh();
        }
      }
    });

  late final GridSkeletonStateFilter<SystemGalleryDirectory> state =
      GridSkeletonStateFilter(
    transform: (cell, _) => cell,
    filter: extra.filter,
    initalCellCount: widget.callback != null
        ? extra.db.systemGalleryDirectorys.countSync()
        : 0,
  );

  late final galleryPlug = chooseGalleryPlug();

  late final api = galleryPlug.galleryApi(
      temporaryDb: widget.callback != null || widget.nestedCallback != null,
      setCurrentApi: widget.callback == null);
  final stream = StreamController<int>(sync: true);

  bool isThumbsLoading = false;

  int? trashThumbId;

  @override
  void initState() {
    super.initState();

    galleryPlug.version.then((value) => galleryVersion = value);

    lifecycleListener = AppLifecycleListener(
      onShow: () {
        galleryPlug.version.then((value) {
          if (value != galleryVersion) {
            galleryVersion = value;
            _refresh();
          }
        });
      },
    );

    if (widget.callback != null) {
      extra.setTemporarySet((i, end) {
        stream.add(i);

        if (end) {
          state.gridKey.currentState?.mutation.isRefreshing = false;
        }
      });
    }

    settingsWatcher = Settings.watch((s) {
      state.settings = s!;
      setState(() {});
    });

    miscSettingsWatcher = MiscSettings.watch((s) {
      miscSettings = s!;

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
      state.gridKey.currentState?.selection.reset();

      stream.add(i);

      if (!inRefresh || empty) {
        state.gridKey.currentState?.mutation.isRefreshing = false;
        performSearch(searchTextController.text);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    settingsWatcher.cancel();
    miscSettingsWatcher.cancel();

    api.close();
    stream.close();
    disposeSearch();
    state.dispose();
    Dbs.g.clearTemporaryImages();
    lifecycleListener.dispose();

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
    state.gridKey.currentState?.mutation.isRefreshing = true;
    api.refresh();
    galleryPlug.version.then((value) => galleryVersion = value);
  }

  Segments<SystemGalleryDirectory> _makeSegments(BuildContext context) =>
      Segments(
        "Uncategorized",
        segment: (cell) {
          for (final booru in Booru.values) {
            if (booru.url == cell.name) {
              return ("Booru", true);
            }
          }

          final dirTag = PostTags.g.directoryTag(cell.bucketId);
          if (dirTag != null) {
            return (dirTag, PinnedDirectories.exist(dirTag));
          }

          final name = cell.name.split(" ");
          return (
            name.first.toLowerCase(),
            PinnedDirectories.exist(name.first.toLowerCase())
          );
        },
        addToSticky: (seg, {unsticky}) {
          if (seg == "Booru" || seg == "Special") {
            return false;
          }
          if (unsticky == true) {
            PinnedDirectories.delete(seg);
          } else {
            PinnedDirectories.add(seg);
          }

          return true;
        },
        injectedSegments: [
          if (FavoriteBooruPost.isNotEmpty())
            SystemGalleryDirectory(
                bucketId: "favorites",
                name: "Favorites", // change
                tag: "",
                volumeName: "",
                relativeLoc: "",
                lastModified: 0,
                thumbFileId: miscSettings.favoritesThumbId != 0
                    ? miscSettings.favoritesThumbId
                    : FavoriteBooruPost.thumbnail),
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
        onLabelPressed: widget.callback != null && !widget.callback!.joinable
            ? null
            : (label, children) =>
                SystemGalleryDirectoriesActions.joinedDirectoriesFnc(
                    context,
                    label,
                    children,
                    extra,
                    widget.viewPadding ?? EdgeInsets.zero,
                    widget.nestedCallback),
      );

  void _closeIfNotInner(SelectionGlue<SystemGalleryDirectory> g) {
    if (extra.currentlyHostingFiles) {
      return;
    }

    g.close();
  }

  @override
  Widget build(BuildContext context) {
    final glue = GlueProvider.of<SystemGalleryDirectory>(context)
        .chain(close: _closeIfNotInner);

    return GridSkeleton<SystemGalleryDirectory>(
        state,
        (context) => GridFrame(
              key: state.gridKey,
              layout: const GridSettingsLayoutBehaviour(
                  GridSettingsDirectories.current),
              refreshingStatus: state.refreshingStatus,
              getCell: (i) => api.directCell(i),
              functionality: GridFunctionality(
                  onPressed: OverrideGridOnCellPressBehaviour(
                      onPressed: (context, idx) {
                    final cell = CellProvider.getOf<SystemGalleryDirectory>(
                        context, idx);

                    if (widget.callback != null) {
                      widget.callback!.c(cell, null).then((_) {
                        Navigator.pop(context);
                      });
                    } else {
                      StatisticsGallery.addViewedDirectories();
                      final d = cell;

                      SelectionGlue<J> generate<J extends Cell>() =>
                          GlueProvider.generateOf<SystemGalleryDirectory, J>(
                              context);

                      final glue = generate<SystemGalleryDirectoryFile>();

                      final apiFiles = switch (cell.bucketId) {
                        "trash" => extra.trash(),
                        "favorites" => extra.favorites(),
                        String() => api.files(d),
                      };

                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => switch (cell.bucketId) {
                              "favorites" => GalleryFiles(
                                  viewPadding: widget.viewPadding,
                                  glue: glue,
                                  generateGlue: generate,
                                  api: apiFiles,
                                  callback: widget.nestedCallback,
                                  dirName: "favorites",
                                  bucketId: "favorites"),
                              "trash" => GalleryFiles(
                                  viewPadding: widget.viewPadding,
                                  glue: glue,
                                  api: apiFiles,
                                  generateGlue: generate,
                                  callback: widget.nestedCallback,
                                  dirName: "trash",
                                  bucketId: "trash"),
                              String() => GalleryFiles(
                                  viewPadding: widget.viewPadding,
                                  generateGlue: generate,
                                  glue: glue,
                                  api: apiFiles,
                                  dirName: d.name,
                                  callback: widget.nestedCallback,
                                  bucketId: d.bucketId)
                            },
                          ));
                    }
                  }),
                  progressTicker: stream.stream,
                  selectionGlue: glue,
                  watchLayoutSettings: GridSettingsDirectories.watch,
                  refresh: widget.callback != null
                      ? SynchronousGridRefresh(() {
                          PlatformFunctions.trashThumbId().then((value) {
                            try {
                              setState(() {
                                trashThumbId = value;
                              });
                            } catch (_) {}
                          });

                          return extra.db.systemGalleryDirectorys.countSync();
                        })
                      : RetainedGridRefresh(_refresh),
                  search: OverrideGridSearchWidget(
                    SearchAndFocus(
                        searchWidget(context,
                            hint:
                                AppLocalizations.of(context)!.directoriesHint),
                        searchFocus),
                  )),
              imageViewDescription: ImageViewDescription(
                imageViewKey: state.imageViewKey,
              ),
              systemNavigationInsets: widget.viewPadding ?? EdgeInsets.zero,
              mainFocus: state.mainFocus,
              description: GridDescription(
                actions:
                    widget.callback != null || widget.nestedCallback != null
                        ? [
                            if (widget.callback == null ||
                                widget.callback!.joinable)
                              SystemGalleryDirectoriesActions.joinedDirectories(
                                  context,
                                  extra,
                                  widget.viewPadding ?? EdgeInsets.zero,
                                  widget.nestedCallback)
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
                            }, (selected, value, toPin) {
                              if (value.isEmpty) {
                                PostTags.g.removeDirectoriesTag(
                                    selected.map((e) => e.bucketId));
                              } else {
                                PostTags.g.setDirectoriesTag(
                                    selected.map((e) => e.bucketId), value);

                                if (toPin) {
                                  PinnedDirectories.add(value, true);
                                }
                              }

                              _refresh();

                              Navigator.of(context, rootNavigator: true).pop();
                            }),
                            SystemGalleryDirectoriesActions.blacklist(
                                context, extra),
                            SystemGalleryDirectoriesActions.joinedDirectories(
                                context,
                                extra,
                                widget.viewPadding ?? EdgeInsets.zero,
                                widget.nestedCallback)
                          ],
                footer: widget.callback?.preview,
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
                          } catch (e, trace) {
                            _log.logDefaultImportant(
                                "new folder in android_directories"
                                    .errorMessage(e),
                                trace);

                            // ignore: use_build_context_synchronously
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.create_new_folder_outlined)),
                ],
                bottomWidget:
                    widget.callback != null || widget.nestedCallback != null
                        ? CopyMovePreview.hintWidget(
                            context,
                            widget.callback != null
                                ? widget.callback!.description
                                : widget.nestedCallback!.description)
                        : null,
                settingsButton: GridFrameSettingsButton(
                  selectRatio: (ratio, settings) =>
                      (settings as GridSettingsDirectories)
                          .copy(aspectRatio: ratio)
                          .save(),
                  selectHideName: (hideNames, settings) =>
                      (settings as GridSettingsDirectories)
                          .copy(hideName: hideNames)
                          .save(),
                  selectGridLayout: null,
                  selectGridColumn: (columns, settings) =>
                      (settings as GridSettingsDirectories)
                          .copy(columns: columns)
                          .save(),
                ),
                inlineMenuButtonItems: true,
                keybindsDescription:
                    AppLocalizations.of(context)!.androidGKeybindsDescription,
                gridSeed: state.gridSeed,
              ),
            ),
        canPop: widget.callback != null || widget.nestedCallback != null
            ? currentFilteringMode() == FilteringMode.noFilter &&
                searchTextController.text.isEmpty
            : false, overrideOnPop: (pop, hideAppBar) {
      final filterMode = currentFilteringMode();
      if (filterMode != FilteringMode.noFilter ||
          searchTextController.text.isNotEmpty) {
        resetSearch();
        return;
      }

      if (hideAppBar()) {
        setState(() {});
        return;
      }

      widget.procPop(pop);
    });
  }
}
