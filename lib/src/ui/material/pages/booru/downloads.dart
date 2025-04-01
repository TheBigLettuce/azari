// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/logic/cancellable_grid_settings_data.dart";
import "package:azari/src/logic/resource_source/basic.dart";
import "package:azari/src/logic/resource_source/chained_filter.dart";
import "package:azari/src/logic/resource_source/filtering_mode.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/widgets/scaffold_selection_bar.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_aspect_ratio.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_column.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/shell_app_bar_type.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/segment_layout.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({
    super.key,
    required this.selectionController,
  });

  final SelectionController selectionController;

  static bool hasServicesRequired() => DownloadManager.available;

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage>
    with SettingsWatcherMixin, DownloadManager {
  late final ChainedFilterResourceSource<String, DownloadHandle> filter;

  final searchTextController = TextEditingController();

  late final SourceShellElementState<DownloadHandle> status;

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
      source,
      ListStorage(),
      filter: (cells, filteringMode, sortingMode, end, [data]) {
        final text = searchTextController.text;
        if (text.isEmpty) {
          return (cells, null);
        }

        return (cells.where((e) => e.data.name.contains(text)), null);
      },
      allowedFilteringModes: const {},
      allowedSortingModes: const {},
      initialFilteringMode: FilteringMode.noFilter,
      initialSortingMode: SortingMode.none,
    );

    status = SourceShellElementState(
      source: filter,
      onEmpty: SourceOnEmptyInterface(
        filter,
        (context) => context.l10n().emptyDownloadProgress,
      ),
      selectionController: widget.selectionController,
      actions: <SelectionBarAction>[
        delete(context),
        SelectionBarAction(
          Icons.restart_alt_rounded,
          (selected) => restartAll(selected.cast()),
          false,
        ),
      ],
    );
  }

  @override
  void dispose() {
    status.destroy();
    gridSettings.cancel();
    filter.destroy();

    searchTextController.dispose();

    super.dispose();
  }

  Segments<DownloadHandle> _makeSegments(
    BuildContext context,
    AppLocalizations l10n,
  ) =>
      Segments(
        l10n.unknownSegmentsPlaceholder,
        hidePinnedIcon: true,
        limitLabelChildren: 6,
        injectedLabel: "",
        segment: (e) => e.data.status.translatedString(l10n),
        caps: const SegmentCapability.alwaysPinned(),
      );

  SelectionBarAction delete(BuildContext context) {
    return SelectionBarAction(
      Icons.remove,
      (selected) {
        if (selected.isEmpty) {
          return;
        }

        storage.removeAll(selected.map((e) => (e as DownloadHandle).key));
      },
      true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return ScaffoldSelectionBar(
      child: ShellScope(
        stackInjector: status,
        configWatcher: gridSettings.watch,
        appBar: TitleAppBarType(
          title: l10n.downloadsPageName,
          leading: IconButton(
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            icon: const Icon(Icons.menu_rounded),
          ),
          trailingItems: [
            IconButton(
              onPressed: storage.clear,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        elements: [
          ElementPriority(
            ShellElement(
              // key: gridKey,
              state: status,
              slivers: [
                SegmentLayout<DownloadHandle>(
                  segments: _makeSegments(context, l10n),
                  l10n: l10n,
                  suggestionPrefix: const [],
                  progress: filter.progress,
                  // gridSeed: gridSeed,
                  storage: filter.backingStorage,
                  selection: status.selection,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
