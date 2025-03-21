// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:async/async.dart";
import "package:azari/init_main/app_info.dart";
import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/services/resource_source/basic.dart";
import "package:azari/src/services/resource_source/chained_filter.dart";
import "package:azari/src/services/resource_source/filtering_mode.dart";
import "package:azari/src/services/resource_source/source_storage.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/ui/material/pages/gallery/directories_actions.dart"
    as actions;
import "package:azari/src/ui/material/pages/gallery/gallery_return_callback.dart";
import "package:azari/src/platform/gallery_api.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/ui/material/widgets/empty_widget.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/segment_layout.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/widgets.dart";
import "package:local_auth/local_auth.dart";

mixin DirectoriesMixin<W extends StatefulWidget> on State<W> {
  Directories? get providedApi;
  GalleryReturnCallback? get callback;
  SelectionController get selectionController;

  WatchableGridSettingsData get gridSettings;
  DirectoryMetadataService? get directoryMetadata;
  DirectoryTagService? get directoryTags;
  FavoritePostSourceService? get favoritePosts;
  BlacklistedDirectoryService? get blacklistedDirectories;
  LocalTagsService? get localTagsService;

  GalleryService get galleryService;
  GridDbService get gridDbs;

  SettingsService get settingsService;

  late final StreamSubscription<void>? _blacklistedWatcher;
  late final StreamSubscription<void>? _directoryTagWatcher;

  late final AppLifecycleListener _lifecycleListener;

  late final ChainedFilterResourceSource<int, Directory> filter;
  late final SourceShellElementState<Directory> status;

  late final TextEditingController searchTextController;
  late final FocusNode searchFocus;

  late final Directories api;

  int _galleryVersion = 0;

  void onRequireAuth(
    BuildContext context,
    void Function() launchLocalAuth,
  );

  @override
  void initState() {
    super.initState();

    searchTextController = TextEditingController();
    searchFocus = FocusNode(canRequestFocus: false);

    api = providedApi ??
        galleryService.open(
          settingsService: settingsService,
          blacklistedDirectory: blacklistedDirectories,
          directoryTags: directoryTags,
          galleryTrash: galleryService.trash,
        );

    galleryService.version.then((value) => _galleryVersion = value);

    _lifecycleListener = AppLifecycleListener(
      onShow: () {
        galleryService.version.then((value) {
          if (value != _galleryVersion) {
            _galleryVersion = value;
            _refresh();
          }
        });
      },
    );

    _directoryTagWatcher = directoryMetadata?.cache.watch((s) {
      api.source.backingStorage.addAll([]);
    });

    _blacklistedWatcher = blacklistedDirectories?.backingStorage.watch((_) {
      api.source.clearRefresh();
    });

    filter = ChainedFilterResourceSource(
      api.source,
      ListStorage(),
      filter: (cells, mode, sorting, end, [data]) => (
        cells.where(
          (e) =>
              e.name.contains(searchTextController.text) ||
              e.tag.contains(searchTextController.text),
        ),
        null
      ),
      allowedFilteringModes: const {},
      allowedSortingModes: const {},
      initialFilteringMode: FilteringMode.noFilter,
      initialSortingMode: SortingMode.none,
    );

    if (providedApi == null) {
      api.trashCell?.refresh();
      api.source.clearRefresh();
    }

    status = SourceShellElementState(
      source: filter,
      selectionController: selectionController,
      actions: callback != null
          ? <SelectionBarAction>[
              if (callback?.isFile ?? false)
                actions.joinedDirectories(
                  context,
                  api,
                  callback?.toFileOrNull,
                  segmentCell,
                  directoryMetadata: directoryMetadata,
                  directoryTags: directoryTags,
                  favoritePosts: favoritePosts,
                  localTags: localTagsService,
                ),
            ]
          : <SelectionBarAction>[
              if (directoryMetadata != null && directoryTags != null)
                actions.addToGroup<Directory>(
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
                  (s, v, t) => _addToGroup(
                    context,
                    s,
                    v,
                    t,
                    directoryMetadata: directoryMetadata!,
                    directoryTags: directoryTags!,
                  ),
                  true,
                  completeDirectoryNameTag: completeDirectoryNameTag,
                ),
              if (blacklistedDirectories != null)
                actions.blacklist(
                  context,
                  segmentCell,
                  directoryMetadata: directoryMetadata,
                  blacklistedDirectory: blacklistedDirectories!,
                ),
              actions.joinedDirectories(
                context,
                api,
                callback?.toFileOrNull,
                segmentCell,
                directoryMetadata: directoryMetadata,
                directoryTags: directoryTags,
                favoritePosts: favoritePosts,
                localTags: localTagsService,
              ),
            ],
      onEmpty: _DirectoryOnEmpty(
        api.trashCell,
        api.source.backingStorage,
      ),
    );
  }

  @override
  void dispose() {
    _directoryTagWatcher!.cancel();
    _blacklistedWatcher!.cancel();
    searchTextController.dispose();

    status.destroy();

    filter.destroy();

    if (providedApi == null) {
      api.close();
    }

    searchFocus.dispose();
    _lifecycleListener.dispose();

    super.dispose();
  }

  // ignore: use_setters_to_change_properties
  void addShellConfig(ShellConfigurationData d) => gridSettings.current = d;

  void _refresh() {
    api.trashCell?.refresh();
    api.source.clearRefresh();
    galleryService.version.then((value) => _galleryVersion = value);
  }

  String segmentCell(Directory cell) => defaultSegmentCell(
        cell.name,
        cell.bucketId,
        directoryTags,
      );

  Segments<Directory> makeSegments(
    BuildContext context, {
    required AppLocalizations l10n,
    required DirectoryMetadataService? directoryMetadata,
  }) {
    return Segments(
      l10n.segmentsUncategorized,
      injectedLabel:
          callback != null ? l10n.suggestionsLabel : l10n.segmentsSpecial,
      displayFirstCellInSpecial: callback != null,
      caps: directoryMetadata != null
          ? DirectoryMetadataSegments(
              l10n.segmentsSpecial,
              directoryMetadata,
            )
          : const SegmentCapability.empty(),
      segment: segmentCell,
      injectedSegments: api.trashCell != null ? [api.trashCell!] : const [],
      onLabelPressed: callback == null || callback!.isFile
          ? (label, children) => actions.joinedDirectoriesFnc(
                context,
                label,
                children,
                api,
                callback?.toFile,
                segmentCell,
                directoryMetadata: directoryMetadata,
                directoryTags: directoryTags,
                favoritePosts: favoritePosts,
                localTags: localTagsService,
              )
          : null,
    );
  }

  Future<void Function(BuildContext)?> _addToGroup(
    BuildContext context,
    List<Directory> selected,
    String value,
    bool toPin, {
    required DirectoryMetadataService directoryMetadata,
    required DirectoryTagService directoryTags,
  }) async {
    final l10n = context.l10n();

    final requireAuth = <Directory>[];
    final noAuth = <Directory>[];

    for (final e in selected) {
      final m = directoryMetadata.cache.get(segmentCell(e));
      if (m != null && m.requireAuth) {
        requireAuth.add(e);
      } else {
        noAuth.add(e);
      }
    }

    if (noAuth.isEmpty &&
        requireAuth.isNotEmpty &&
        AppInfo().canAuthBiometric) {
      final success = await LocalAuthentication()
          .authenticate(localizedReason: l10n.changeGroupReason);
      if (!success) {
        return null;
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
        if (await directoryMetadata.canAuth(
          value,
          l10n.unstickyStickyDirectory,
        )) {
          directoryMetadata
              .getOrCreate(value)
              .copyBools(sticky: true)
              .maybeSave();
        }
      }
    }

    _refresh();

    if (noAuth.isNotEmpty && requireAuth.isNotEmpty) {
      return (BuildContext context) => onRequireAuth(
            context,
            () async {
              final success = await LocalAuthentication()
                  .authenticate(localizedReason: l10n.changeGroupReason);
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
          );
    } else {
      return null;
    }
  }

  Future<List<BooruTag>> completeDirectoryNameTag(String str) {
    final m = <String, void>{};

    return Future.value(
      api.source.backingStorage
          .map(
            (e) {
              if (e.tag.isNotEmpty &&
                  e.tag.contains(str) &&
                  !m.containsKey(e.tag)) {
                m[e.tag] = null;
                return e.tag;
              }

              if (e.name.startsWith(str) && !m.containsKey(e.name)) {
                m[e.name] = null;

                return e.name;
              } else {
                return null;
              }
            },
          )
          .where((e) => e != null)
          .take(15)
          .map((e) => BooruTag(e!, -1))
          .toList(),
    );
  }
}

class _DirectoryOnEmpty implements OnEmptyInterface {
  _DirectoryOnEmpty(this.trashCell, this.storage);

  final TrashCell? trashCell;
  final ReadOnlyStorage<dynamic, dynamic> storage;

  @override
  Widget build(BuildContext context) {
    return EmptyWidgetBackground(
      subtitle: context.l10n().emptyDevicePictures,
    );
  }

  @override
  bool get showEmpty {
    if (trashCell == null) {
      return storage.isEmpty;
    }

    return storage.isEmpty && !trashCell!.hasData;
  }

  @override
  StreamSubscription<bool> watch(void Function(bool showEmpty) fn) {
    if (trashCell == null) {
      return storage.countEvents.map((e) => e == 0).listen(fn);
    }

    return StreamGroup.merge([
      storage.countEvents,
      trashCell!.stream,
    ]).map((e) => showEmpty).listen(fn);
  }
}

String defaultSegmentCell(
  String name,
  String bucketId,
  DirectoryTagService? directoryTag,
) {
  for (final booru in Booru.values) {
    if (booru.url == name) {
      return "Booru";
    }
  }

  final dirTag = directoryTag?.get(bucketId);
  if (dirTag != null) {
    return dirTag;
  }

  return name.split(" ").first.toLowerCase();
}
