// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/resource_source/basic.dart";
import "package:gallery/src/db/services/resource_source/chained_filter.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/filtering/filtering_mode.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/layouts/list_layout.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";

class BlacklistedPage extends StatefulWidget {
  const BlacklistedPage({
    super.key,
    required this.db,
    required this.generate,
    required this.popScope,
  });

  final DbConn db;
  final SelectionGlue Function([Set<GluePreferences> preferences]) generate;
  final void Function(bool) popScope;

  @override
  State<BlacklistedPage> createState() => _BlacklistedPageState();
}

class _BlacklistedPageState extends State<BlacklistedPage> {
  BlacklistedDirectoryService get blacklistedDirectory =>
      widget.db.blacklistedDirectories;

  late final state = GridSkeletonState<BlacklistedDirectoryData>();

  late final ChainedFilterResourceSource<String, BlacklistedDirectoryData>
      filter;
  final searchTextController = TextEditingController();

  final gridConfiguration = GridSettingsData.noPersist(
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
            ),
          ],
          functionality: GridFunctionality(
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
                Icons.restore_page,
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
