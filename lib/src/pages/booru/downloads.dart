// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/chained_filter.dart";
import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/common_grid_data.dart";
import "package:azari/src/widgets/empty_widget.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/layouts/segment_layout.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:azari/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:azari/src/widgets/selection_actions.dart";
import "package:flutter/material.dart";

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({
    super.key,
    required this.downloadManager,
    required this.settingsService,
  });

  final DownloadManager downloadManager;

  final SettingsService settingsService;

  static bool hasServicesRequired(Services db) => Services.hasDownloadManager;

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage>
    with CommonGridData<Post, DownloadsPage> {
  DownloadManager get downloadManager => widget.downloadManager;

  @override
  SettingsService get settingsService => widget.settingsService;

  late final ChainedFilterResourceSource<String, DownloadHandle> filter;

  final searchTextController = TextEditingController();

  final gridSettings = CancellableWatchableGridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.three,
    layoutType: GridLayoutType.grid,
  );

  @override
  void initState() {
    super.initState();

    filter = ChainedFilterResourceSource(
      downloadManager,
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
  }

  @override
  void dispose() {
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

  GridAction<DownloadHandle> delete(BuildContext context) {
    return GridAction(
      Icons.remove,
      (selected) {
        if (selected.isEmpty) {
          return;
        }

        downloadManager.removeAll(selected.map((e) => e.key));
      },
      true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return GridConfiguration(
      watch: gridSettings.watch,
      child: WrapGridPage(
        child: GridFrame<DownloadHandle>(
          key: gridKey,
          slivers: [
            SegmentLayout<DownloadHandle>(
              segments: _makeSegments(context, l10n),
              localizations: l10n,
              suggestionPrefix: const [],
              progress: filter.progress,
              gridSeed: gridSeed,
              storage: filter.backingStorage,
            ),
          ],
          functionality: GridFunctionality(
            selectionActions: SelectionActions.of(context),
            onEmptySource: EmptyWidgetBackground(
              subtitle: l10n.emptyDownloadProgress,
            ),
            search: PageNameSearchWidget(
              leading: IconButton(
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                icon: const Icon(Icons.menu_rounded),
              ),
              trailingItems: [
                IconButton(
                  onPressed: downloadManager.clear,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            source: filter,
          ),
          description: GridDescription(
            actions: <GridAction<DownloadHandle>>[
              delete(context),
              GridAction(
                Icons.restart_alt_rounded,
                downloadManager.restartAll,
                false,
              ),
            ],
            pageName: l10n.downloadsPageName,
            gridSeed: gridSeed,
          ),
        ),
      ),
    );
  }
}
