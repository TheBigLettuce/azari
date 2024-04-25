// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/main.dart";
import "package:gallery/src/db/initalize_db.dart";
import "package:gallery/src/db/schemas/gallery/directory_metadata.dart";
import "package:gallery/src/db/schemas/gallery/favorite_file.dart";
import "package:gallery/src/db/schemas/gallery/system_gallery_directory.dart";
import "package:gallery/src/db/schemas/grid_settings/directories.dart";
import "package:gallery/src/db/schemas/settings/misc_settings.dart";
import "package:gallery/src/db/services/settings.dart";
import "package:gallery/src/db/tags/post_tags.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/filtering/filtering_mode.dart";
import "package:gallery/src/interfaces/gallery/gallery_api_directories.dart";
import "package:gallery/src/interfaces/logging/logging.dart";
import "package:gallery/src/pages/gallery/callback_description.dart";
import "package:gallery/src/pages/gallery/callback_description_nested.dart";
import "package:gallery/src/pages/gallery/gallery_directories_actions.dart";
import "package:gallery/src/pages/more/favorite_booru_actions.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/plugs/platform_functions.dart";
import "package:gallery/src/widgets/copy_move_preview.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_frame_settings_button.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_mutation_interface.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/layouts/segment_layout.dart";
import "package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:gallery/src/widgets/search_bar/search_filter_grid.dart";
import "package:gallery/src/widgets/skeletons/grid.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";
import "package:local_auth/local_auth.dart";

class GalleryDirectories extends StatefulWidget {
  const GalleryDirectories({
    super.key,
    this.callback,
    this.nestedCallback,
    required this.procPop,
    this.wrapGridPage = false,
    this.showBackButton = false,
  }) : assert(!(callback != null && nestedCallback != null));

  final CallbackDescription? callback;
  final CallbackDescriptionNested? nestedCallback;
  final bool showBackButton;
  final void Function(bool) procPop;
  final bool wrapGridPage;

  static String segmentCell(String name, String bucketId) {
    for (final booru in Booru.values) {
      if (booru.url == name) {
        return "Booru";
      }
    }

    final dirTag = PostTags.g.directoryTag(bucketId);
    if (dirTag != null) {
      return dirTag;
    }

    return name.split(" ").first.toLowerCase();
  }

  @override
  State<GalleryDirectories> createState() => _GalleryDirectoriesState();
}

class _GalleryDirectoriesState extends State<GalleryDirectories> {
  static const _log = LogTarget.gallery;

  late final StreamSubscription<SettingsData?> settingsWatcher;
  late final StreamSubscription<MiscSettings?> miscSettingsWatcher;
  late final AppLifecycleListener lifecycleListener;

  MiscSettings miscSettings = MiscSettings.current;

  int galleryVersion = 0;

  GridMutationInterface get mutation => state.refreshingStatus.mutation;

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
    setCurrentApi: widget.callback == null,
  );
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

    settingsWatcher = state.settings.s.watch((s) {
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

  String _segmentCell(SystemGalleryDirectory cell) =>
      GalleryDirectories.segmentCell(cell.name, cell.bucketId);

  Segments<SystemGalleryDirectory> _makeSegments(BuildContext context) {
    return Segments(
      AppLocalizations.of(context)!.segmentsUncategorized,
      injectedLabel: widget.callback != null || widget.nestedCallback != null
          ? "Suggestions"
          : AppLocalizations.of(context)!.segmentsSpecial, // TODO: change
      displayFirstCellInSpecial:
          widget.callback != null || widget.nestedCallback != null,
      caps:
          DirectoryMetadata.caps(AppLocalizations.of(context)!.segmentsSpecial),
      segment: _segmentCell,
      injectedSegments: [
        if (FavoriteFile.isNotEmpty())
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
                : FavoriteFile.thumbnail,
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
                GlueProvider.generateOf(context),
                _segmentCell,
              ),
    );
  }

  Future<void> _addToGroup(
    BuildContext context,
    List<SystemGalleryDirectory> selected,
    String value,
    bool toPin,
  ) async {
    final requireAuth = <SystemGalleryDirectory>[];
    final noAuth = <SystemGalleryDirectory>[];

    for (final e in selected) {
      final m = DirectoryMetadata.get(_segmentCell(e));
      if (m != null && m.requireAuth) {
        requireAuth.add(e);
      } else {
        noAuth.add(e);
      }
    }

    if (noAuth.isEmpty && requireAuth.isNotEmpty && canAuthBiometric) {
      final success = await LocalAuthentication()
          .authenticate(localizedReason: "Change directories group");
      if (!success) {
        return;
      }
    }

    if (value.isEmpty) {
      PostTags.g.removeDirectoriesTag(
        (noAuth.isEmpty && requireAuth.isNotEmpty ? requireAuth : noAuth)
            .map((e) => e.bucketId),
      );
    } else {
      PostTags.g.setDirectoriesTag(
        (noAuth.isEmpty && requireAuth.isNotEmpty ? requireAuth : noAuth)
            .map((e) => e.bucketId),
        value,
      );

      if (toPin) {
        if (await DirectoryMetadata.canAuth(value, "Sticky directory")) {
          final m = (DirectoryMetadata.get(value) ??
                  DirectoryMetadata(
                    value,
                    DateTime.now(),
                    blur: false,
                    sticky: false,
                    requireAuth: false,
                  ))
              .copyBools(sticky: true);
          m.save();
        }
      }
    }

    if (noAuth.isNotEmpty && requireAuth.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Some directories require authentication",
          ), // TODO: change
          action: SnackBarAction(
            label: "Auth",
            onPressed: () async {
              final success = await LocalAuthentication()
                  .authenticate(localizedReason: "Change group on directories");
              if (!success) {
                return;
              }

              if (value.isEmpty) {
                PostTags.g
                    .removeDirectoriesTag(requireAuth.map((e) => e.bucketId));
              } else {
                PostTags.g.setDirectoriesTag(
                  requireAuth.map((e) => e.bucketId),
                  value,
                );
              }

              _refresh();
            },
          ),
        ),
      );
    }

    _refresh();

    Navigator.of(context, rootNavigator: true).pop();
  }

  Widget child(BuildContext context) {
    return GridSkeleton<SystemGalleryDirectory>(
      state,
      (context) => GridFrame(
        key: state.gridKey,
        layout: SegmentLayout(
          _makeSegments(context),
          GridSettingsDirectories.current,
          suggestionPrefix: widget.callback?.suggestFor ?? const [],
        ),
        getCell: (i) => api.directCell(i),
        functionality: GridFunctionality(
          selectionGlue: GlueProvider.generateOf(context)(),
          registerNotifiers: (child) => DirectoriesDataNotifier(
            api: api,
            nestedCallback: widget.nestedCallback,
            callback: widget.callback,
            segmentFnc: _segmentCell,
            child: child,
          ),
          refreshingStatus: state.refreshingStatus,
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
              search.searchWidget(
                context,
                count: widget.callback != null
                    ? extra.db.systemGalleryDirectorys.countSync()
                    : null,
                hint: AppLocalizations.of(context)!.directoriesHint,
              ),
              search.searchFocus,
            ),
          ),
        ),
        mainFocus: state.mainFocus,
        description: GridDescription(
          actions: widget.callback != null || widget.nestedCallback != null
              ? [
                  if (widget.callback == null || widget.callback!.joinable)
                    SystemGalleryDirectoriesActions.joinedDirectories(
                      context,
                      extra,
                      widget.nestedCallback,
                      GlueProvider.generateOf(context),
                      _segmentCell,
                    ),
                ]
              : [
                  FavoritesActions.addToGroup(
                    context,
                    (selected) {
                      final t = selected.first.tag;
                      for (final e in selected.skip(1)) {
                        if (t != e.tag) {
                          return null;
                        }
                      }

                      return t;
                    },
                    (s, v, t) => _addToGroup(context, s, v, t),
                    true,
                  ),
                  SystemGalleryDirectoriesActions.blacklist(
                    context,
                    extra,
                    _segmentCell,
                  ),
                  SystemGalleryDirectoriesActions.joinedDirectories(
                    context,
                    extra,
                    widget.nestedCallback,
                    GlueProvider.generateOf(context),
                    _segmentCell,
                  ),
                ],
          footer: widget.callback?.preview,
          menuButtonItems: [
            if (widget.callback != null)
              IconButton(
                onPressed: () async {
                  try {
                    widget.callback!(
                      null,
                      await PlatformFunctions.chooseDirectory(temporary: true)
                          .then((value) => value!.path),
                    );
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                  } catch (e, trace) {
                    _log.logDefaultImportant(
                      "new folder in android_directories".errorMessage(e),
                      trace,
                    );

                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.create_new_folder_outlined),
              ),
          ],
          bottomWidget: widget.callback != null || widget.nestedCallback != null
              ? CopyMovePreview.hintWidget(
                  context,
                  widget.callback != null
                      ? widget.callback!.description
                      : widget.nestedCallback!.description,
                  widget.callback != null
                      ? widget.callback!.icon
                      : widget.nestedCallback!.icon,
                )
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
          ? search.currentFilteringMode() == FilteringMode.noFilter &&
              search.searchTextController.text.isEmpty
          : false,
      onPop: (pop) {
        final filterMode = search.currentFilteringMode();
        if (filterMode != FilteringMode.noFilter ||
            search.searchTextController.text.isNotEmpty) {
          search.resetSearch();
          return;
        }

        widget.procPop(pop);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.wrapGridPage
        ? WrapGridPage(
            addScaffold: widget.callback != null,
            child: Builder(
              builder: (context) => child(context),
            ),
          )
        : child(context);
  }
}

class DirectoriesDataNotifier extends InheritedWidget {
  const DirectoriesDataNotifier({
    super.key,
    required this.api,
    required this.nestedCallback,
    required this.callback,
    required this.segmentFnc,
    required super.child,
  });
  final GalleryAPIDirectories api;
  final CallbackDescription? callback;
  final CallbackDescriptionNested? nestedCallback;
  final String Function(SystemGalleryDirectory cell) segmentFnc;

  static (
    GalleryAPIDirectories,
    CallbackDescription?,
    CallbackDescriptionNested?,
    String Function(SystemGalleryDirectory cell),
  ) of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<DirectoriesDataNotifier>();

    return (
      widget!.api,
      widget.callback,
      widget.nestedCallback,
      widget.segmentFnc,
    );
  }

  @override
  bool updateShouldNotify(DirectoriesDataNotifier oldWidget) =>
      api != oldWidget.api ||
      callback != oldWidget.callback ||
      nestedCallback != oldWidget.nestedCallback ||
      segmentFnc != oldWidget.segmentFnc;
}
