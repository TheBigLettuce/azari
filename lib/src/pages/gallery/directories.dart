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
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/filtering/filtering_mode.dart";
import "package:gallery/src/interfaces/gallery/gallery_api_directories.dart";
import "package:gallery/src/interfaces/logging/logging.dart";
import "package:gallery/src/pages/gallery/callback_description.dart";
import "package:gallery/src/pages/gallery/callback_description_nested.dart";
import "package:gallery/src/pages/gallery/gallery_directories_actions.dart";
import "package:gallery/src/pages/more/favorite_booru_actions.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/plugs/gallery_management_api.dart";
import "package:gallery/src/widgets/copy_move_preview.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/layouts/segment_layout.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_settings_button.dart";
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
    required this.db,
  }) : assert(!(callback != null && nestedCallback != null));

  final CallbackDescription? callback;
  final CallbackDescriptionNested? nestedCallback;
  final bool showBackButton;
  final void Function(bool) procPop;
  final bool wrapGridPage;

  final DbConn db;

  static String segmentCell(
    String name,
    String bucketId,
    DirectoryTagService directoryTag,
  ) {
    for (final booru in Booru.values) {
      if (booru.url == name) {
        return "Booru";
      }
    }

    final dirTag = directoryTag.get(bucketId);
    if (dirTag != null) {
      return dirTag;
    }

    return name.split(" ").first.toLowerCase();
  }

  @override
  State<GalleryDirectories> createState() => _GalleryDirectoriesState();
}

class _GalleryDirectoriesState extends State<GalleryDirectories> {
  WatchableGridSettingsData get gridSettings =>
      widget.db.gridSettings.directories;
  DirectoryMetadataService get directoryMetadata => widget.db.directoryMetadata;
  DirectoryTagService get directoryTags => widget.db.directoryTags;
  FavoriteFileService get favoriteFiles => widget.db.favoriteFiles;
  BlacklistedDirectoryService get blacklistedDirectories =>
      widget.db.blacklistedDirectories;

  static const _log = LogTarget.gallery;

  late final StreamSubscription<SettingsData?> settingsWatcher;
  late final StreamSubscription<MiscSettingsData?> miscSettingsWatcher;
  late final StreamSubscription<void> blacklistedWatcher;
  late final AppLifecycleListener lifecycleListener;

  MiscSettingsData miscSettings = MiscSettingsService.db().current;

  int galleryVersion = 0;

  late final ChainedFilterResourceSource<int, GalleryDirectory> filter;

  late final GridSkeletonState<GalleryDirectory> state = GridSkeletonState();

  final galleryPlug = chooseGalleryPlug();

  late final api = galleryPlug.galleryApi(
    widget.db.blacklistedDirectories,
    widget.db.directoryTags,
    temporaryDb: widget.callback != null || widget.nestedCallback != null,
    setCurrentApi: widget.callback == null,
  );
  bool isThumbsLoading = false;

  int? trashThumbId;

  final searchFocus = FocusNode();
  final searchTextController = TextEditingController();

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

    miscSettingsWatcher = miscSettings.s.watch((s) {
      miscSettings = s!;

      setState(() {});
    });

    blacklistedWatcher = blacklistedDirectories.backingStorage.watch((_) {
      api.source.clearRefresh();
    });

    filter = ChainedFilterResourceSource(
      api.source,
      ListStorage(),
      filter: (cells, mode, sorting, end, [data]) => (
        cells.where((e) => e.name.contains(searchTextController.text)),
        null
      ),
      allowedFilteringModes: const {},
      allowedSortingModes: const {},
      initialFilteringMode: FilteringMode.noFilter,
      initialSortingMode: SortingMode.none,
    );

    if (widget.callback != null) {
      GalleryManagementApi.current().trashThumbId().then((value) {
        try {
          setState(() {
            trashThumbId = value;
          });
        } catch (_) {}
      });
    }

    api.source.clearRefresh();
  }

  @override
  void dispose() {
    blacklistedWatcher.cancel();
    settingsWatcher.cancel();
    miscSettingsWatcher.cancel();
    searchTextController.dispose();
    searchFocus.dispose();

    filter.destroy();

    api.close();
    // search.dispose();
    state.dispose();
    // Dbs.g.clearTemporaryImages();
    lifecycleListener.dispose();

    super.dispose();
  }

  void _refresh() {
    GalleryManagementApi.current().trashThumbId().then((value) {
      try {
        setState(() {
          trashThumbId = value;
        });
      } catch (_) {}
    });

    api.source.clearRefresh();
    galleryPlug.version.then((value) => galleryVersion = value);
  }

  String _segmentCell(GalleryDirectory cell) => GalleryDirectories.segmentCell(
        cell.name,
        cell.bucketId,
        directoryTags,
      );

  Segments<GalleryDirectory> _makeSegments(BuildContext context) {
    return Segments(
      AppLocalizations.of(context)!.segmentsUncategorized,
      injectedLabel: widget.callback != null || widget.nestedCallback != null
          ? "Suggestions"
          : AppLocalizations.of(context)!.segmentsSpecial, // TODO: change
      displayFirstCellInSpecial:
          widget.callback != null || widget.nestedCallback != null,
      caps:
          directoryMetadata.caps(AppLocalizations.of(context)!.segmentsSpecial),
      segment: _segmentCell,
      injectedSegments: [
        if (favoriteFiles.isNotEmpty())
          GalleryDirectory.forPlatform(
            bucketId: "favorites",
            name: AppLocalizations.of(context)!
                .galleryDirectoriesFavorites, // change
            tag: "",
            volumeName: "",
            relativeLoc: "",
            lastModified: 0,
            thumbFileId: miscSettings.favoritesThumbId != 0
                ? miscSettings.favoritesThumbId
                : favoriteFiles.thumbnail,
          ),
        if (trashThumbId != null)
          GalleryDirectory.forPlatform(
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
                api,
                widget.nestedCallback,
                GlueProvider.generateOf(context),
                _segmentCell,
                directoryMetadata,
                directoryTags,
              ),
    );
  }

  Future<void> _addToGroup(
    BuildContext context,
    List<GalleryDirectory> selected,
    String value,
    bool toPin,
  ) async {
    final requireAuth = <GalleryDirectory>[];
    final noAuth = <GalleryDirectory>[];

    for (final e in selected) {
      final m = directoryMetadata.get(_segmentCell(e));
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
      directoryTags.delete(
        (noAuth.isEmpty && requireAuth.isNotEmpty ? requireAuth : noAuth)
            .map((e) => e.bucketId),
      );
    } else {
      directoryTags.add(
        (noAuth.isEmpty && requireAuth.isNotEmpty ? requireAuth : noAuth)
            .map((e) => e.bucketId),
        value,
      );

      if (toPin) {
        if (await directoryMetadata.canAuth(value, "Sticky directory")) {
          directoryMetadata.getOrCreate(value).copyBools(sticky: true).save();
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
                directoryTags.delete(requireAuth.map((e) => e.bucketId));
              } else {
                directoryTags.add(
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

  // ignore: use_setters_to_change_properties
  void _add(GridSettingsData d) => gridSettings.current = d;

  Widget child(BuildContext context) {
    return GridSkeleton<GalleryDirectory>(
      state,
      (context) => GridFrame(
        key: state.gridKey,
        slivers: [
          SegmentLayout(
            getCell: filter.forIdxUnsafe,
            segments: _makeSegments(context),
            gridSeed: 1,
            suggestionPrefix: widget.callback?.suggestFor ?? const [],
            storage: filter.backingStorage,
            progress: filter.progress,
            localizations: AppLocalizations.of(context)!,
          ),
        ],
        functionality: GridFunctionality(
          selectionGlue: GlueProvider.generateOf(context)(),
          registerNotifiers: (child) => DirectoriesDataNotifier(
            api: api,
            nestedCallback: widget.nestedCallback,
            callback: widget.callback,
            segmentFnc: _segmentCell,
            child: child,
          ),
          source: filter,
          settingsButton: GridSettingsButton(
            add: _add,
            watch: gridSettings.watch,
          ),
          search: OverrideGridSearchWidget(
            SearchAndFocus(
              FilteringSearchWidget(
                hint: AppLocalizations.of(context)!.directoriesHint,
                filter: filter,
                textController: searchTextController,
                localTagDictionary: widget.db.localTagDictionary,
                focusNode: searchFocus,
              ),
              searchFocus,
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
                      api,
                      widget.nestedCallback,
                      GlueProvider.generateOf(context),
                      _segmentCell,
                      directoryMetadata,
                      directoryTags,
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
                    _segmentCell,
                    directoryMetadata,
                    blacklistedDirectories,
                  ),
                  SystemGalleryDirectoriesActions.joinedDirectories(
                    context,
                    api,
                    widget.nestedCallback,
                    GlueProvider.generateOf(context),
                    _segmentCell,
                    directoryMetadata,
                    directoryTags,
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
                      await GalleryManagementApi.current()
                          .chooseDirectory(temporary: true)
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
          inlineMenuButtonItems: true,
          keybindsDescription:
              AppLocalizations.of(context)!.androidGKeybindsDescription,
          gridSeed: state.gridSeed,
        ),
      ),
      canPop: widget.callback != null || widget.nestedCallback != null
          ? filter.filteringMode == FilteringMode.noFilter &&
              searchTextController.text.isEmpty
          : false,
      onPop: (pop) {
        if (filter.filteringMode != FilteringMode.noFilter ||
            searchTextController.text.isNotEmpty) {
          searchTextController.clear();

          // search.resetSearch();
          return;
        }

        widget.procPop(pop);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridConfiguration(
      watch: gridSettings.watch,
      child: widget.wrapGridPage
          ? WrapGridPage(
              addScaffold: widget.callback != null,
              child: Builder(
                builder: (context) => child(context),
              ),
            )
          : child(context),
    );
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
  final String Function(GalleryDirectory cell) segmentFnc;

  static (
    GalleryAPIDirectories,
    CallbackDescription?,
    CallbackDescriptionNested?,
    String Function(GalleryDirectory cell),
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
