// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/logic/cancellable_grid_settings_data.dart";
import "package:azari/src/logic/resource_source/basic.dart";
import "package:azari/src/logic/resource_source/chained_filter.dart";
import "package:azari/src/logic/resource_source/filtering_mode.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_aspect_ratio.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_column.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/widgets.dart";

mixin BlacklistedDirectoriesMixin<W extends StatefulWidget> on State<W> {
  SelectionController get selectionController;

  late final ChainedFilterResourceSource<String, BlacklistedDirectoryData>
  filter;
  final searchTextController = TextEditingController();

  late final SourceShellScopeElementState<BlacklistedDirectoryData> status;

  final gridSettings = CancellableGridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.three,
    layoutType: GridLayoutType.grid,
  );

  @override
  void initState() {
    super.initState();

    filter = ChainedFilterResourceSource(
      const BlacklistedDirectoryService(),
      ListStorage(),
      filter: (cells, filteringMode, sortingMode, colors, end, data) => (
        cells.where((e) => e.name.contains(searchTextController.text)),
        null,
      ),
      allowedFilteringModes: const {},
      allowedSortingModes: const {},
      initialFilteringMode: FilteringMode.noFilter,
      initialSortingMode: SortingMode.none,
    );

    status = SourceShellScopeElementState(
      source: filter,
      gridSettings: gridSettings,
      onEmpty: SourceOnEmptyInterface(
        filter,
        (context) => context.l10n().emptyHiddenDirectories,
      ),
      selectionController: selectionController,
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
}
