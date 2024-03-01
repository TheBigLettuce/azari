// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/base/grid_settings_base.dart';
import 'package:gallery/src/db/schemas/grid_settings/booru.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:gallery/src/interfaces/grid/grid_aspect_ratio.dart';
import 'package:gallery/src/interfaces/grid/grid_column.dart';
import 'package:gallery/src/interfaces/manga/manga_api.dart';
import 'package:gallery/src/pages/anime/manga/manga_info_page.dart';
import 'package:gallery/src/pages/anime/paging_container.dart';
import 'package:gallery/src/widgets/grid/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid/configuration/grid_layout_behaviour.dart';
import 'package:gallery/src/widgets/grid/configuration/grid_on_cell_press_behaviour.dart';
import 'package:gallery/src/widgets/grid/configuration/image_view_description.dart';
import 'package:gallery/src/widgets/grid/grid_frame.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton_state.dart';

class MangaTab extends StatefulWidget {
  final MangaAPI api;
  final List<MangaEntry> elems;
  final EdgeInsets viewInsets;
  final PagingContainer<MangaEntry> container;

  const MangaTab({
    super.key,
    required this.api,
    required this.elems,
    required this.viewInsets,
    required this.container,
  });

  @override
  State<MangaTab> createState() => _MangaTabState();
}

class _MangaTabState extends State<MangaTab> {
  late final state = GridSkeletonState<MangaEntry>(
    initalCellCount: widget.elems.length,
    overrideRefreshStatus: widget.container.refreshingStatus,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();

    state.dispose();
  }

  Future<int> _refresh() async {
    widget.elems.clear();
    widget.container.page = 0;
    widget.container.reachedEnd = false;

    final r = await widget.api.top(widget.container.page, 30);
    widget.elems.addAll(r);

    return widget.elems.length;
  }

  Future<int> _loadNext() async {
    final r = await widget.api.top(widget.container.page + 1, 30);
    widget.elems.addAll(r);
    widget.container.page += 1;
    widget.container.reachedEnd = r.isEmpty;

    return widget.elems.length;
  }

  static GridSettingsBase _settings() => const GridSettingsBase(
        columns: GridColumn.three,
        aspectRatio: GridAspectRatio.zeroSeven,
        hideName: false,
        layoutType: GridLayoutType.grid,
      );

  @override
  Widget build(BuildContext context) {
    return GridSkeleton<MangaEntry>(
      state,
      (context) => GridFrame(
        key: state.gridKey,
        layout: const GridSettingsLayoutBehaviour(_settings),
        refreshingStatus: state.refreshingStatus,
        getCell: (i) => widget.elems[i],
        initalScrollPosition: widget.container.scrollPos,
        imageViewDescription: ImageViewDescription(
          imageViewKey: state.imageViewKey,
        ),
        functionality: GridFunctionality(
          updateScrollPosition: widget.container.updateScrollPos,
          selectionGlue:
              GlueProvider.generateOf<AnimeEntry, MangaEntry>(context),
          refresh: AsyncGridRefresh(_refresh),
          loadNext: _loadNext,
          onPressed: OverrideGridOnCellPressBehaviour(
            onPressed: (context, idx, _) {
              final cell = CellProvider.getOf<MangaEntry>(context, idx);

              Navigator.push(context, MaterialPageRoute(
                builder: (context) {
                  return MangaInfoPage(
                    id: cell.id,
                    entry: cell,
                    api: widget.api,
                  );
                },
              ));
            },
          ),
        ),
        systemNavigationInsets: widget.viewInsets,
        mainFocus: state.mainFocus,
        description: GridDescription(
          actions: const [],
          ignoreSwipeSelectGesture: true,
          showAppBar: false,
          keybindsDescription: "Manga page",
          gridSeed: state.gridSeed,
        ),
      ),
      canPop: false,
    );
  }
}
