// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:async/async.dart";
import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/logic/directory_metadata_segments.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/resource_source/basic.dart";
import "package:azari/src/logic/resource_source/chained_filter.dart";
import "package:azari/src/logic/resource_source/filtering_mode.dart";
import "package:azari/src/logic/resource_source/source_storage.dart";
import "package:azari/src/logic/trash_cell.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/gallery/directories.dart"
    as actions;
import "package:azari/src/ui/material/pages/gallery/files.dart";
import "package:azari/src/ui/material/widgets/empty_widget.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/segment_layout.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/widgets.dart";
import "package:local_auth/local_auth.dart";

mixin DirectoriesMixin<W extends StatefulWidget> on State<W> {
  SelectionController get selectionController;

  final gridSettings = GridSettingsData<DirectoriesData>();

  late final StreamSubscription<void>? _blacklistedWatcher;
  late final StreamSubscription<void>? _directoryTagWatcher;

  late final AppLifecycleListener? _lifecycleListener;

  late final ChainedFilterResourceSource<int, Directory> filter;
  late final SourceShellElementState<Directory> status;

  late final TextEditingController searchTextController;
  late final FocusNode searchFocus;

  final Directories api = Spaces().get<Directories>();

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

    GalleryApi.safe()?.version.then((value) => _galleryVersion = value);

    _lifecycleListener = AppLifecycleListener(
      onShow: () {
        GalleryApi.safe()?.version.then((value) {
          if (value != _galleryVersion) {
            _galleryVersion = value;
            _refresh();
          }
        });
      },
    );

    _directoryTagWatcher = DirectoryMetadataService.safe()?.cache.watch((s) {
      api.source.backingStorage.addAll([]);
    });

    _blacklistedWatcher =
        BlacklistedDirectoryService.safe()?.backingStorage.watch((_) {
      api.source.clearRefresh();
    });

    filter = ChainedFilterResourceSource(
      api.source,
      ListStorage(),
      filter: (cells, mode, sorting, colors, end, data) => (
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

    status = SourceShellElementState(
      source: filter,
      selectionController: selectionController,
      actions: <SelectionBarAction>[
        if (DirectoryMetadataService.available && DirectoryTagService.available)
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
            _addToGroup,
            true,
            completeDirectoryNameTag: completeDirectoryNameTag,
          ),
        if (BlacklistedDirectoryService.available)
          actions.blacklist(context, segmentCell),
        actions.joinedDirectories(
          context,
          api,
          segmentCell,
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

    // if (providedApi == null) {
    //   api.close();
    // }

    searchFocus.dispose();
    _lifecycleListener?.dispose();

    super.dispose();
  }

  // ignore: use_setters_to_change_properties
  void addShellConfig(ShellConfigurationData d) => gridSettings.current = d;

  void _refresh() {
    api.trashCell?.refresh();
    api.source.clearRefresh();

    GalleryApi.safe()?.version.then((value) => _galleryVersion = value);
  }

  String segmentCell(Directory cell) => defaultSegmentCell(
        cell.name,
        cell.bucketId,
      );

  Segments<Directory> makeSegments(
    BuildContext context, {
    required AppLocalizations l10n,
  }) {
    return Segments(
      l10n.segmentsUncategorized,
      injectedLabel: l10n.segmentsSpecial,
      caps: DirectoryMetadataService.available
          ? DirectoryMetadataSegments(l10n.segmentsSpecial)
          : const SegmentCapability.empty(),
      segment: segmentCell,
      injectedSegments: api.trashCell != null ? [api.trashCell!] : const [],
      onLabelPressed: (label, children) {
        Spaces().get<Directories>().files(children);
        FilesPage.open(context);
      },
    );
  }

  Future<void Function(BuildContext)?> _addToGroup(
    List<Directory> selected,
    String value,
    bool toPin,
  ) async {
    final l10n = context.l10n();
    const directoryTags = DirectoryTagService();
    const directoryMetadata = DirectoryMetadataService();

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
        const AppApi().canAuthBiometric) {
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

String defaultSegmentCell(String name, String bucketId) {
  for (final booru in Booru.values) {
    if (booru.url == name) {
      return "Booru";
    }
  }

  final dirTag = DirectoryTagService.safe()?.get(bucketId);
  if (dirTag != null) {
    return dirTag;
  }

  return name.split(" ").first.toLowerCase();
}
