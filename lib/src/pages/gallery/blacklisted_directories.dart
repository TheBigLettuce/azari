// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/chained_filter.dart";
import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/common_grid_data.dart";
import "package:azari/src/widgets/selection_bar.dart";
import "package:azari/src/widgets/shell/configuration/grid_aspect_ratio.dart";
import "package:azari/src/widgets/shell/configuration/grid_column.dart";
import "package:azari/src/widgets/shell/configuration/shell_app_bar_type.dart";
import "package:azari/src/widgets/shell/layouts/list_layout.dart";
import "package:azari/src/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";

class BlacklistedDirectoriesPage extends StatefulWidget {
  const BlacklistedDirectoriesPage({
    super.key,
    required this.popScope,
    required this.settingsService,
    required this.blacklistedDirectories,
    required this.selectionController,
  });

  final void Function(bool) popScope;
  final SelectionController selectionController;

  final SettingsService settingsService;
  final BlacklistedDirectoryService blacklistedDirectories;

  @override
  State<BlacklistedDirectoriesPage> createState() =>
      _BlacklistedDirectoriesPageState();
}

class _BlacklistedDirectoriesPageState extends State<BlacklistedDirectoriesPage>
    with CommonGridData<BlacklistedDirectoriesPage> {
  BlacklistedDirectoryService get blacklistedDirectory =>
      widget.blacklistedDirectories;

  @override
  SettingsService get settingsService => widget.settingsService;

  late final ChainedFilterResourceSource<String, BlacklistedDirectoryData>
      filter;
  final searchTextController = TextEditingController();

  late final SourceShellElementState<BlacklistedDirectoryData> status;

  final gridConfiguration = CancellableWatchableGridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.three,
    layoutType: GridLayoutType.grid,
  );

  @override
  void initState() {
    super.initState();

    filter = ChainedFilterResourceSource(
      blacklistedDirectory,
      ListStorage(),
      filter: (cells, filteringMode, sortingMode, end, [data]) => (
        cells.where((e) => e.name.contains(searchTextController.text)),
        null
      ),
      allowedFilteringModes: const {},
      allowedSortingModes: const {},
      initialFilteringMode: FilteringMode.noFilter,
      initialSortingMode: SortingMode.none,
    );

    status = SourceShellElementState(
      source: filter,
      onEmpty: SourceOnEmptyInterface(
        filter,
        (context) => context.l10n().emptyHiddenDirectories,
      ),
      selectionController: widget.selectionController,
      actions: const [],
    );
  }

  @override
  void dispose() {
    searchTextController.dispose();
    status.destroy();

    filter.destroy();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    // WrapGridPage(
    //   child: ,
    // ),

    return ShellScope(
      stackInjector: status,
      configWatcher: gridConfiguration.watch,
      appBar: TitleAppBarType(
        title: l10n.blacklistedFoldersPage,
        leading: IconButton(
          onPressed: () {
            widget.popScope(false);
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      // gridSeed: gridSeed,
      elements: [
        ElementPriority(
          ShellElement(
            // key: gridKey,
            animationsOnSourceWatch: false,
            state: status,
            slivers: [
              ListLayout<BlacklistedDirectoryData>(
                hideThumbnails: false,
                source: filter.backingStorage,
                progress: filter.progress,
                selection: status.selection,
                itemFactory: (context, idx, cell) {
                  return DefaultListTile(
                    selection: status.selection,
                    index: idx,
                    cell: cell,
                    hideThumbnails: false,
                    dismiss: TileDismiss(
                      () {
                        blacklistedDirectory.backingStorage
                            .removeAll([cell.bucketId]);
                      },
                      Icons.restore_page_rounded,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
