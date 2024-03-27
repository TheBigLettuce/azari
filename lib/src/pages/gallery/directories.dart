// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/gallery/directory_metadata.dart';
import 'package:gallery/src/db/schemas/grid_settings/directories.dart';
import 'package:gallery/src/db/schemas/settings/misc_settings.dart';
import 'package:gallery/src/db/schemas/statistics/statistics_gallery.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_mutation_interface.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart';
import 'package:gallery/src/interfaces/logging/logging.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_frame_settings_button.dart';
import 'package:gallery/src/plugs/gallery.dart';
import 'package:gallery/src/widgets/copy_move_preview.dart';
import 'package:gallery/src/pages/more/favorite_booru_actions.dart';
import 'package:gallery/src/pages/gallery/gallery_directories_actions.dart';
import 'package:gallery/src/db/tags/post_tags.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/plugs/platform_functions.dart';
import 'package:gallery/src/pages/gallery/files.dart';
import 'package:gallery/src/db/schemas/gallery/system_gallery_directory.dart';
import 'package:gallery/src/db/schemas/gallery/favorite_booru_post.dart';
import 'package:gallery/src/db/schemas/gallery/pinned_directories.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_on_cell_press_behaviour.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/image_view_description.dart';
import 'package:gallery/src/widgets/grid_frame/grid_frame.dart';
import 'package:gallery/src/widgets/grid_frame/layouts/segment_layout.dart';
import 'package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/search_bar/search_filter_grid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';

import '../../db/schemas/settings/settings.dart';
import '../../interfaces/filtering/filtering_mode.dart';
import '../../widgets/skeletons/grid.dart';
import 'callback_description.dart';
import 'callback_description_nested.dart';

class GalleryDirectories extends StatefulWidget {
  final CallbackDescription? callback;
  final CallbackDescriptionNested? nestedCallback;
  final bool showBackButton;
  final void Function(bool) procPop;
  final EdgeInsets? viewPadding;
  final bool wrapGridPage;

  const GalleryDirectories({
    super.key,
    this.callback,
    this.nestedCallback,
    this.viewPadding,
    required this.procPop,
    this.wrapGridPage = false,
    this.showBackButton = false,
  }) : assert(!(callback != null && nestedCallback != null));

  @override
  State<GalleryDirectories> createState() => _GalleryDirectoriesState();
}

class _GalleryDirectoriesState extends State<GalleryDirectories> {
  static const _log = LogTarget.gallery;

  late final StreamSubscription<Settings?> settingsWatcher;
  late final StreamSubscription<MiscSettings?> miscSettingsWatcher;
  late final AppLifecycleListener lifecycleListener;

  MiscSettings miscSettings = MiscSettings.current;

  int galleryVersion = 0;

  GridMutationInterface<SystemGalleryDirectory> get mutation =>
      state.refreshingStatus.mutation;

  bool proceed = true;
  late final extra = api.getExtra()
    ..setRefreshGridCallback(() {
      if (widget.callback != null) {
        mutation.cellCount = 0;
        mutation.isRefreshing = true;
      } else {
        if (!mutation.isRefreshing) {
          _refresh();
        }
      }
    });

  late final GridSkeletonStateFilter<SystemGalleryDirectory> state =
      GridSkeletonStateFilter(
    transform: (cell) => cell,
    filter: extra.filter,
    initalCellCount: widget.callback != null
        ? extra.db.systemGalleryDirectorys.countSync()
        : 0,
  );

  final galleryPlug = chooseGalleryPlug();

  late final SearchFilterGrid<SystemGalleryDirectory> search;

  late final api = galleryPlug.galleryApi(
      temporaryDb: widget.callback != null || widget.nestedCallback != null,
      setCurrentApi: widget.callback == null);
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

    settingsWatcher = Settings.watch((s) {
      state.settings = s!;
      setState(() {});
    });

    miscSettingsWatcher = MiscSettings.watch((s) {
      miscSettings = s!;

      setState(() {});
    });

    search = SearchFilterGrid(state, null);

    if (widget.callback != null) {
      search.performSearch("", true);

      extra.setTemporarySet((i, end) {
        if (end) {
          mutation.isRefreshing = false;
          search.performSearch(search.searchTextController.text);
        }
      });
    }

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

      if (!inRefresh || empty) {
        mutation.isRefreshing = false;
        search.performSearch(search.searchTextController.text);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    settingsWatcher.cancel();
    miscSettingsWatcher.cancel();

    api.close();
    search.dispose();
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

    mutation.isRefreshing = true;
    api.refresh();
    galleryPlug.version.then((value) => galleryVersion = value);
  }

  Segments<SystemGalleryDirectory> _makeSegments(BuildContext context) {
    SelectionGlue<J> generate<J extends Cell>() =>
        GlueProvider.generateOf<SystemGalleryDirectory, J>(context);

    return Segments(
      AppLocalizations.of(context)!.segmentsUncategorized,
      injectedLabel: AppLocalizations.of(context)!.segmentsSpecial,
      displayFirstCellInSpecial:
          widget.callback != null || widget.nestedCallback != null,
      blur: (seg) {
        DirectoryMetadata.add(
          seg,
          !(DirectoryMetadata.get(seg)?.blur ?? false),
        );
      },
      isBlur: (seg) {
        return DirectoryMetadata.get(seg)?.blur ?? false;
      },
      isSticky: (seg) {
        if (seg == "Booru") {
          return true;
        }

        return PinnedDirectories.exist(seg);
      },
      segment: (cell) {
        for (final booru in Booru.values) {
          if (booru.url == cell.name) {
            return "Booru";
          }
        }

        final dirTag = PostTags.g.directoryTag(cell.bucketId);
        if (dirTag != null) {
          return dirTag;
        }

        final name = cell.name.split(" ");
        return name.first.toLowerCase();
      },
      addToSticky: (seg, {unsticky}) {
        if (seg == "Booru" ||
            seg == AppLocalizations.of(context)!.segmentsSpecial) {
          return false;
        }
        if (unsticky == true) {
          PinnedDirectories.delete(seg);
        } else {
          PinnedDirectories.add(seg, false);
        }

        return true;
      },
      injectedSegments: [
        if (FavoriteBooruPost.isNotEmpty())
          SystemGalleryDirectory(
            bucketId: "favorites",
            name: AppLocalizations.of(context)!
                .galleryDirectoriesFavorites, // change
            tag: "",
            volumeName: "",
            relativeLoc: "",
            lastModified: 0,
            thumbFileId: miscSettings.favoritesThumbId != 0
                ? miscSettings.favoritesThumbId
                : FavoriteBooruPost.thumbnail,
          ),
        if (trashThumbId != null)
          SystemGalleryDirectory(
            bucketId: "trash",
            name: AppLocalizations.of(context)!.galleryDirectoryTrash, // change
            tag: "",
            volumeName: "",
            relativeLoc: "",
            lastModified: 0,
            thumbFileId: trashThumbId!,
          ),
      ],
      onLabelPressed: widget.callback != null && !widget.callback!.joinable
          ? null
          : (label, children) =>
              SystemGalleryDirectoriesActions.joinedDirectoriesFnc(
                context,
                label,
                children,
                extra,
                widget.nestedCallback,
                widget.viewPadding ?? EdgeInsets.zero,
                state.settings.buddhaMode ? null : generate,
              ),
    );
  }

  void _closeIfNotInner(SelectionGlue<SystemGalleryDirectory> g) {
    if (extra.currentlyHostingFiles) {
      return;
    }

    g.close();
  }

  Widget child(BuildContext context, EdgeInsets insets) {
    final glue = GlueProvider.of<SystemGalleryDirectory>(context)
        .chain(close: _closeIfNotInner);

    SelectionGlue<J> generate<J extends Cell>() =>
        GlueProvider.generateOf<SystemGalleryDirectory, J>(context);

    return GridSkeleton<SystemGalleryDirectory>(
        state,
        (context) => GridFrame(
              key: state.gridKey,
              layout: SegmentLayout(
                _makeSegments(context),
                GridSettingsDirectories.current,
                suggestionPrefix: widget.callback?.suggestFor ?? const [],
              ),
              refreshingStatus: state.refreshingStatus,
              getCell: (i) => api.directCell(i),
              functionality: GridFunctionality(
                  onPressed: OverrideGridOnCellPressBehaviour(
                      onPressed: (context, idx, providedCell) {
                    final cell = providedCell as SystemGalleryDirectory? ??
                        CellProvider.getOf<SystemGalleryDirectory>(
                            context, idx);

                    if (widget.callback != null) {
                      state.refreshingStatus.mutation.cellCount = 0;

                      Navigator.pop(context);
                      widget.callback!.c(cell, null);
                    } else {
                      StatisticsGallery.addViewedDirectories();
                      final d = cell;

                      SelectionGlue<J> generate<J extends Cell>() =>
                          GlueProvider.generateOf<SystemGalleryDirectory, J>(
                              context);

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
                                  generateGlue: state.settings.buddhaMode
                                      ? null
                                      : generate,
                                  api: apiFiles,
                                  callback: widget.nestedCallback,
                                  addInset:
                                      widget.viewPadding ?? EdgeInsets.zero,
                                  dirName: AppLocalizations.of(context)!
                                      .galleryDirectoriesFavorites,
                                  bucketId: "favorites",
                                ),
                              "trash" => GalleryFiles(
                                  api: apiFiles,
                                  generateGlue: state.settings.buddhaMode
                                      ? null
                                      : generate,
                                  callback: widget.nestedCallback,
                                  addInset:
                                      widget.viewPadding ?? EdgeInsets.zero,
                                  dirName: AppLocalizations.of(context)!
                                      .galleryDirectoryTrash,
                                  bucketId: "trash",
                                ),
                              String() => GalleryFiles(
                                  generateGlue: state.settings.buddhaMode
                                      ? null
                                      : generate,
                                  api: apiFiles,
                                  dirName: d.name,
                                  addInset:
                                      widget.viewPadding ?? EdgeInsets.zero,
                                  callback: widget.nestedCallback,
                                  bucketId: d.bucketId,
                                )
                            },
                          ));
                    }
                  }),
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
                        search.searchWidget(context,
                            count: widget.callback != null
                                ? extra.db.systemGalleryDirectorys.countSync()
                                : null,
                            hint:
                                AppLocalizations.of(context)!.directoriesHint),
                        search.searchFocus),
                  )),
              imageViewDescription: ImageViewDescription(
                imageViewKey: state.imageViewKey,
              ),
              systemNavigationInsets: insets,
              mainFocus: state.mainFocus,
              description: GridDescription(
                appBarSnap: !state.settings.buddhaMode,
                risingAnimation: !state.settings.buddhaMode &&
                    widget.nestedCallback == null &&
                    widget.callback == null,
                actions:
                    widget.callback != null || widget.nestedCallback != null
                        ? [
                            if (widget.callback == null ||
                                widget.callback!.joinable)
                              SystemGalleryDirectoriesActions.joinedDirectories(
                                context,
                                extra,
                                widget.nestedCallback,
                                widget.viewPadding ?? EdgeInsets.zero,
                                state.settings.buddhaMode ? null : generate,
                              )
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
                            }, true),
                            SystemGalleryDirectoriesActions.blacklist(
                                context, extra),
                            SystemGalleryDirectoriesActions.joinedDirectories(
                              context,
                              extra,
                              widget.nestedCallback,
                              widget.viewPadding ?? EdgeInsets.zero,
                              state.settings.buddhaMode ? null : generate,
                            )
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
                                      temporary: true)
                                  .then((value) => value!.path),
                            );
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
        canPop: widget.callback != null ||
                widget.nestedCallback != null ||
                state.settings.buddhaMode
            ? search.currentFilteringMode() == FilteringMode.noFilter &&
                search.searchTextController.text.isEmpty
            : false, overrideOnPop: (pop) {
      final filterMode = search.currentFilteringMode();
      if (filterMode != FilteringMode.noFilter ||
          search.searchTextController.text.isNotEmpty) {
        search.resetSearch();
        return;
      }

      widget.procPop(pop);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewPadding = widget.viewPadding ?? MediaQuery.viewPaddingOf(context);

    return widget.wrapGridPage
        ? WrapGridPage<SystemGalleryDirectory>(
            scaffoldKey: state.scaffoldKey,
            child: Builder(
              builder: (context) => child(context, viewPadding),
            ),
          )
        : child(context, viewPadding);
  }
}
