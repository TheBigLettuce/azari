// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/chained_filter.dart";
import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/widgets/empty_widget.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/layouts/list_layout.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:azari/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:azari/src/widgets/skeletons/skeleton_state.dart";
import "package:flutter/material.dart";

class BlacklistedDirectoriesPage extends StatefulWidget {
  const BlacklistedDirectoriesPage({
    super.key,
    required this.db,
    required this.popScope,
  });

  final DbConn db;
  final void Function(bool) popScope;

  @override
  State<BlacklistedDirectoriesPage> createState() =>
      _BlacklistedDirectoriesPageState();
}

class _BlacklistedDirectoriesPageState
    extends State<BlacklistedDirectoriesPage> {
  BlacklistedDirectoryService get blacklistedDirectory =>
      widget.db.blacklistedDirectories;

  late final state = GridSkeletonState<BlacklistedDirectoryData>();

  late final ChainedFilterResourceSource<String, BlacklistedDirectoryData>
      filter;
  final searchTextController = TextEditingController();

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
  }

  @override
  void dispose() {
    state.dispose();
    searchTextController.dispose();

    filter.destroy();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GridConfiguration(
      watch: gridConfiguration.watch,
      child: WrapGridPage(
        child: GridFrame<BlacklistedDirectoryData>(
          key: state.gridKey,
          slivers: [
            ListLayout<BlacklistedDirectoryData>(
              hideThumbnails: false,
              source: filter.backingStorage,
              progress: filter.progress,
              itemFactory: (context, idx, cell) {
                final extras =
                    GridExtrasNotifier.of<BlacklistedDirectoryData>(context);

                return DefaultListTile(
                  functionality: extras.functionality,
                  selection: extras.selection,
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
          functionality: GridFunctionality(
            onEmptySource: EmptyWidgetBackground(
              subtitle: l10n.emptyHiddenDirectories,
            ),
            search: PageNameSearchWidget(
              leading: IconButton(
                onPressed: () {
                  widget.popScope(false);
                },
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            source: filter,
          ),
          description: GridDescription(
            animationsOnSourceWatch: false,
            pageName: l10n.blacklistedFoldersPage,
            gridSeed: state.gridSeed,
          ),
        ),
      ),
    );
  }
}
