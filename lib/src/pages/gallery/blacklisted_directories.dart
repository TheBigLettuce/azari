// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/chained_filter.dart";
import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/widgets/empty_widget.dart";
import "package:azari/src/widgets/glue_provider.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:azari/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/layouts/list_layout.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:azari/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:azari/src/widgets/skeletons/skeleton_state.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

class BlacklistedDirectories extends StatefulWidget {
  const BlacklistedDirectories({
    super.key,
    required this.db,
    required this.generate,
    required this.popScope,
  });

  final DbConn db;
  final SelectionGlue Function([Set<GluePreferences> preferences]) generate;
  final void Function(bool) popScope;

  @override
  State<BlacklistedDirectories> createState() => _BlacklistedDirectoriesState();
}

class _BlacklistedDirectoriesState extends State<BlacklistedDirectories> {
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
    return GridConfiguration(
      watch: gridConfiguration.watch,
      child: WrapGridPage(
        provided: widget.generate,
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
            onEmptySource: const EmptyWidgetBackground(
              subtitle:
                  "Hidden directories will appear here...", // TODO: change
            ),
            search: PageNameSearchWidget(
              leading: IconButton(
                onPressed: () {
                  widget.popScope(false);
                },
                icon: const Icon(Icons.arrow_back),
              ),
              trailingItems: [
                IconButton(
                  onPressed: blacklistedDirectory.backingStorage.clear,
                  icon: const Icon(Icons.delete),
                ),
              ],
            ),
            selectionGlue: GlueProvider.generateOf(context)(),
            source: filter,
          ),
          description: GridDescription(
            actions: [
              GridAction(
                Icons.restore_page_rounded,
                (selected) {
                  blacklistedDirectory.backingStorage.removeAll(
                    selected.map((e) => e.bucketId).toList(),
                  );
                },
                true,
              ),
            ],
            keybindsDescription:
                AppLocalizations.of(context)!.blacklistedFoldersPage,
            gridSeed: state.gridSeed,
          ),
        ),
      ),
    );
  }
}
