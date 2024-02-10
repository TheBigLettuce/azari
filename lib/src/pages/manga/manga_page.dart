// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:gallery/src/interfaces/grid/grid_aspect_ratio.dart';
import 'package:gallery/src/interfaces/grid/grid_column.dart';
import 'package:gallery/src/interfaces/manga/manga_api.dart';
import 'package:gallery/src/net/manga/manga_dex.dart';
import 'package:gallery/src/pages/manga/manga_inner.dart';
import 'package:gallery/src/widgets/grid/grid_frame.dart';
import 'package:gallery/src/widgets/grid/layouts/grid_layout.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton_state.dart';

class MangaPage extends StatefulWidget {
  const MangaPage({super.key});

  @override
  State<MangaPage> createState() => _MangaPageState();
}

class _MangaPageState extends State<MangaPage> {
  late final List<MangaEntry> res = [];
  late final MangaAPI api;
  late final Dio client;

  final state = GridSkeletonState<MangaEntry>();

  int page = 0;
  bool reachedEnd = false;

  @override
  void initState() {
    super.initState();

    client = Dio();
    api = MangaDex(client);
  }

  @override
  void dispose() {
    super.dispose();

    state.dispose();
    client.close(force: true);
  }

  Future<int> _refresh() async {
    res.clear();
    page = 0;
    reachedEnd = false;

    final r = await api.top(page);
    res.addAll(r);

    return res.length;
  }

  Future<int> _loadNext() async {
    final r = await api.top(page + 1);
    res.addAll(r);
    page += 1;
    reachedEnd = r.isEmpty;

    return res.length;
  }

  @override
  Widget build(BuildContext context) {
    return GridSkeleton<MangaEntry>(
      state,
      (context) => GridFrame(
        key: state.gridKey,
        getCell: (i) => res[i],
        initalCellCount: 0,
        initalScrollPosition: 0,
        scaffoldKey: state.scaffoldKey,
        systemNavigationInsets: EdgeInsets.zero,
        hasReachedEnd: () => reachedEnd,
        selectionGlue: GlueProvider.generateOf<AnimeEntry, MangaEntry>(context),
        mainFocus: state.mainFocus,
        overrideOnPress: (context, cell) {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) {
              return MangaInnerPage(
                entry: cell,
                api: api,
              );
            },
          ));
        },
        refresh: _refresh,
        loadNext: _loadNext,
        description: const GridDescription(
          showAppBar: false,
          [],
          keybindsDescription: "Manga page",
          layout: GridLayout(
            GridColumn.three,
            GridAspectRatio.one,
            hideAlias: false,
          ),
        ),
      ),
      canPop: false,
    );
  }
}
