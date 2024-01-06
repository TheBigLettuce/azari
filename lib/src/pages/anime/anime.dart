// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/grid_settings/anime_discovery.dart';
import 'package:gallery/src/interfaces/anime.dart';
import 'package:gallery/src/interfaces/grid/grid_aspect_ratio.dart';
import 'package:gallery/src/net/anime/jikan.dart';
import 'package:gallery/src/pages/anime/inner/anime_inner.dart';
import 'package:gallery/src/pages/notes/tab_with_count.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/grid/layouts/grid_layout.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton_state.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_settings.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';

import 'search_anime.dart';

part 'discover_tab.dart';

class AnimePage extends StatefulWidget {
  final void Function(bool) procPop;

  const AnimePage({super.key, required this.procPop});

  @override
  State<AnimePage> createState() => _AnimePageState();
}

class _AnimePageState extends State<AnimePage>
    with SingleTickerProviderStateMixin {
  final state = SkeletonState();
  late final tabController =
      TabController(initialIndex: 1, length: 4, vsync: this);

  @override
  void initState() {
    super.initState();

    tabController.addListener(() {
      GlueProvider.of<AnimeEntry>(context).close();

      setState(() {});
    });
  }

  @override
  void dispose() {
    state.dispose();
    tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: tabController.index == 2 ? null : widget.procPop,
      child: SkeletonSettings(
        "Anime",
        state,
        appBar: AppBar(
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) {
                      return const SearchAnimePage();
                    },
                  ));
                  // searchController.
                },
                icon: const Icon(Icons.search)),
          ],
          title: Text("Anime"),
          bottom: TabBar(controller: tabController, tabs: [
            Tab(text: "News"),
            TabWithCount("Watching", 0),
            Tab(text: "Discover"),
            Tab(text: "All"),
          ]),
        ),
        child: TabBarView(
          controller: tabController,
          children: [
            EmptyWidget(),
            EmptyWidget(),
            _DiscoverTab(procPop: widget.procPop),
            EmptyWidget(),
          ],
        ),
      ),
    );
  }
}

   //  IconButton(onPressed: (){

            //  }, icon: const Icon(Icons.search)),
            // if (tabController.index == 2)
            //   GridSettingsButton(gridSettings,
            //       selectRatio: null,
            //       selectHideName: (value) =>
            //           gridSettings.copy(hideName: value).save(),
            //       selectListView: null,
            //       selectGridColumn: (value) =>
            //           gridSettings.copy(columns: value).save())
