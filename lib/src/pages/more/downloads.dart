// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/base/grid_settings_base.dart';
import 'package:gallery/src/db/schemas/grid_settings/booru.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart';
import 'package:gallery/src/net/downloader.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/downloader/download_file.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/image_view_description.dart';
import 'package:gallery/src/widgets/grid_frame/grid_frame.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_column.dart';
import 'package:gallery/src/widgets/grid_frame/layouts/segment_layout.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/search_bar/search_filter_grid.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../db/loaders/linear_isar_loader.dart';
import '../../widgets/grid_frame/wrappers/wrap_grid_page.dart';
import '../../widgets/skeletons/grid.dart';

class Downloads extends StatefulWidget {
  final SelectionGlue<J> Function<J extends Cell>() generateGlue;

  const Downloads({
    super.key,
    required this.generateGlue,
  });

  @override
  State<Downloads> createState() => _DownloadsState();
}

class _DownloadsState extends State<Downloads> {
  final loader = LinearIsarLoader<DownloadFile>(DownloadFileSchema, Dbs.g.main,
      (offset, limit, s, sort, mode) {
    return Dbs.g.main.downloadFiles
        .where()
        .sortByInProgressDesc()
        .offset(offset)
        .limit(limit)
        .findAllSync();
  });

  late final SearchFilterGrid<DownloadFile> search;

  late final StreamSubscription<void> _updates;

  late final state = GridSkeletonStateFilter<DownloadFile>(
    filter: loader.filter,
    transform: (cell) => cell,
  );

  @override
  void initState() {
    super.initState();

    search = SearchFilterGrid(state, null);

    Downloader.g.markStale();

    _updates = DownloadFile.watch((_) async {
      search.performSearch(search.searchTextController.text);
    });
  }

  @override
  void dispose() {
    _updates.cancel();
    search.dispose();
    state.dispose();

    super.dispose();
  }

  Segments<DownloadFile> _makeSegments(BuildContext context) => Segments(
        AppLocalizations.of(context)!.unknownSegmentsPlaceholder,
        hidePinnedIcon: true,
        limitLabelChildren: 6,
        injectedLabel: "",
        segment: (cell) {
          return (Downloader.g.downloadDescription(cell));
        },
        onLabelPressed: (label, children) {
          if (children.isEmpty) {
            return;
          }

          if (label == kDownloadInProgress) {
            Downloader.g.markStale(override: children);
          } else if (label == kDownloadOnHold) {
            Downloader.g.addAll(children, state.settings);
          } else if (label == kDownloadFailed) {
            final n = (6 - children.length);

            if (!n.isNegative && n != 0) {
              Downloader.g.addAll([
                ...children,
                ...DownloadFile.nextNumber(children.length),
              ], state.settings);
            } else {
              Downloader.g.addAll(children, state.settings);
            }
          }
        },
        caps: SegmentCapability.empty(),
      );

  GridSettingsBase _gridSettingsBase() => const GridSettingsBase(
        aspectRatio: GridAspectRatio.one,
        columns: GridColumn.three,
        layoutType: GridLayoutType.grid,
        hideName: false,
      );

  static GridAction<DownloadFile> delete(BuildContext context) {
    return GridAction(Icons.remove, (selected) {
      if (selected.isEmpty) {
        return;
      }

      Downloader.g.remove(selected);
    }, true);
  }

  @override
  Widget build(BuildContext context) {
    return WrapGridPage<DownloadFile>(
      scaffoldKey: state.scaffoldKey,
      provided: widget.generateGlue,
      child: GridSkeleton(
        state,
        (context) => GridFrame<DownloadFile>(
          key: state.gridKey,
          layout: SegmentLayout(_makeSegments(context), _gridSettingsBase),
          refreshingStatus: state.refreshingStatus,
          getCell: loader.getCell,
          initalScrollPosition: 0,
          systemNavigationInsets: MediaQuery.viewPaddingOf(context),
          imageViewDescription: ImageViewDescription(
            imageViewKey: state.imageViewKey,
          ),
          functionality: GridFunctionality(
            search: OverrideGridSearchWidget(
              SearchAndFocus(
                search.searchWidget(context,
                    hint: AppLocalizations.of(context)!.downloadsPageName),
                search.searchFocus,
              ),
            ),
            selectionGlue: GlueProvider.of(context),
            refresh: SynchronousGridRefresh(() => loader.count()),
          ),
          mainFocus: state.mainFocus,
          description: GridDescription(
            actions: [
              delete(context),
            ],
            menuButtonItems: [
              IconButton(
                onPressed: Downloader.g.removeAll,
                icon: const Icon(Icons.close),
              ),
            ],
            keybindsDescription:
                AppLocalizations.of(context)!.downloadsPageName,
            inlineMenuButtonItems: true,
            gridSeed: state.gridSeed,
          ),
        ),
        canPop: true,
      ),
    );
  }
}
