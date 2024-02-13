// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/manga/compact_manga_data.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:gallery/src/interfaces/grid/grid_aspect_ratio.dart';
import 'package:gallery/src/interfaces/grid/grid_column.dart';
import 'package:gallery/src/interfaces/manga/manga_api.dart';
import 'package:gallery/src/pages/anime/anime.dart';
import 'package:gallery/src/pages/anime/manga/manga_inner.dart';
import 'package:gallery/src/widgets/grid/grid_frame.dart';
import 'package:gallery/src/widgets/grid/layouts/grid_layout.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton_state.dart';

class MangaTab extends StatefulWidget {
  final MangaAPI api;
  final List<MangaEntry> elems;
  final EdgeInsets viewInsets;
  final PagingContainer container;

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
  final state = GridSkeletonState<MangaEntry>();

  bool reachedEnd = false;

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
    reachedEnd = false;

    final r = await widget.api.top(widget.container.page, 30);
    widget.elems.addAll(r);

    return widget.elems.length;
  }

  Future<int> _loadNext() async {
    final r = await widget.api.top(widget.container.page + 1, 30);
    widget.elems.addAll(r);
    widget.container.page += 1;
    reachedEnd = r.isEmpty;

    return widget.elems.length;
  }

  @override
  Widget build(BuildContext context) {
    return GridSkeleton<MangaEntry>(
      state,
      (context) => GridFrame(
        key: state.gridKey,
        getCell: (i) => widget.elems[i],
        initalCellCount: widget.elems.length,
        initalScrollPosition: widget.container.scrollPos,
        scaffoldKey: state.scaffoldKey,
        systemNavigationInsets: widget.viewInsets,
        hasReachedEnd: () => reachedEnd,
        refreshInterface: widget.container.refreshingInterface,
        updateScrollPosition: widget.container.updateScrollPos,
        selectionGlue: GlueProvider.generateOf<AnimeEntry, MangaEntry>(context),
        mainFocus: state.mainFocus,
        overrideOnPress: (context, cell) {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) {
              return MangaInnerPage(
                entry: Future.value(cell),
                api: widget.api,
              );
            },
          ));
        },
        refresh: _refresh,
        loadNext: _loadNext,
        description: const GridDescription(
          [],
          ignoreSwipeSelectGesture: true,
          showAppBar: false,
          keybindsDescription: "Manga page",
          layout: GridLayout(
            GridColumn.three,
            GridAspectRatio.zeroSeven,
            hideAlias: false,
          ),
        ),
      ),
      canPop: false,
    );
  }
}
