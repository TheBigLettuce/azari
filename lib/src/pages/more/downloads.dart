// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/filtering/filtering_mode.dart";
import "package:gallery/src/net/download_manager/download_manager.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/layouts/segment_layout.dart";
import "package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:gallery/src/widgets/search_bar/search_filter_grid.dart";
import "package:gallery/src/widgets/skeletons/grid.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";

class Downloads extends StatefulWidget {
  const Downloads({
    super.key,
    required this.generateGlue,
    required this.downloadManager,
    required this.db,
  });

  final SelectionGlue Function([Set<GluePreferences>]) generateGlue;
  final DownloadManager downloadManager;

  final DbConn db;

  @override
  State<Downloads> createState() => _DownloadsState();
}

class _DownloadsState extends State<Downloads> {
  DownloadManager get downloadManager => widget.downloadManager;

  late final StreamSubscription<void> _updates;

  late final ChainedFilterResourceSource<int, DownloadHandle> filter;

  late final state = GridSkeletonState<DownloadHandle>();

  final searchTextController = TextEditingController();
  final searchFocus = FocusNode();

  final gridSettings = GridSettingsData.noPersist(
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

    // Downloader.g.markStale();

    _updates = downloadManager.watch((_) {
      filter.clearRefresh();
    });
  }

  @override
  void dispose() {
    gridSettings.cancel();
    _updates.cancel();
    filter.destroy();

    searchFocus.dispose();
    searchTextController.dispose();
    state.dispose();

    super.dispose();
  }

  Segments<DownloadHandle> _makeSegments(BuildContext context) => Segments(
        AppLocalizations.of(context)!.unknownSegmentsPlaceholder,
        hidePinnedIcon: true,
        limitLabelChildren: 6,
        injectedLabel: "",
        segment: (e) => e.data.status.name,
        // onLabelPressed: (label, children) {
        //   if (children.isEmpty) {
        //     return;
        //   }

        //   if (label == kDownloadInProgress) {
        //     Downloader.g.markStale(override: children);
        //   } else if (label == kDownloadOnHold) {
        //     Downloader.g.addAll(children, state.settings);
        //   } else if (label == kDownloadFailed) {
        //     final n = 6 - children.length;

        //     if (!n.isNegative && n != 0) {
        //       downloadManager.addAll(children);
        //       Downloader.g.addAll(
        //         [
        //           ...children,
        //           ...DownloadFile.nextNumber(children.length),
        //         ],
        //         state.settings,
        //       );
        //     } else {
        //       downloadManager.putAll(
        //         children.map((e) => e.data),
        //         state.settings,
        //       );
        //       // Downloader.g.addAll(children, state.settings);
        //     }
        //   }
        // },
        caps: SegmentCapability.alwaysPinned(),
      );

  GridAction<DownloadHandle> delete(BuildContext context) {
    return GridAction(
      Icons.remove,
      (selected) {
        if (selected.isEmpty) {
          return;
        }

        downloadManager.remove(selected);
      },
      true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l8n = AppLocalizations.of(context)!;

    return GridConfiguration(
      watch: gridSettings.watch,
      child: WrapGridPage(
        provided: widget.generateGlue,
        child: GridSkeleton(
          state,
          (context) => GridFrame<DownloadHandle>(
            key: state.gridKey,
            slivers: [
              SegmentLayout<DownloadHandle>(
                segments: _makeSegments(context),
                localizations: l8n,
                suggestionPrefix: const [],
                getCell: filter.forIdxUnsafe,
                progress: filter.progress,
                gridSeed: state.gridSeed,
                storage: filter.backingStorage,
              ),
            ],
            functionality: GridFunctionality(
              search: OverrideGridSearchWidget(
                SearchAndFocus(
                  FilteringSearchWidget(
                    hint: l8n.downloadsPageName,
                    filter: filter,
                    textController: searchTextController,
                    localTagDictionary: widget.db.localTagDictionary,
                    focusNode: searchFocus,
                  ),
                  searchFocus,
                ),
              ),
              selectionGlue: GlueProvider.generateOf(context)(),
              source: filter,
            ),
            mainFocus: state.mainFocus,
            description: GridDescription(
              actions: [
                delete(context),
              ],
              // menuButtonItems: [
              //   IconButton(
              //     onPressed: Downloader.g.restartFailed,
              //     icon: const Icon(Icons.download_rounded),
              //   ),
              //   IconButton(
              //     onPressed: Downloader.g.removeAll,
              //     icon: const Icon(Icons.close),
              //   ),
              // ],
              keybindsDescription: l8n.downloadsPageName,
              inlineMenuButtonItems: true,
              gridSeed: state.gridSeed,
            ),
          ),
          canPop: true,
        ),
      ),
    );
  }
}
