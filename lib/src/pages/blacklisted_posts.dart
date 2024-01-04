// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/settings/hidden_booru_post.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/grid/layouts/list_layout.dart';
import 'package:gallery/src/widgets/grid/wrap_grid_page.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton_state.dart';

class BlacklistedPostsPage extends StatefulWidget {
  const BlacklistedPostsPage({super.key});

  @override
  State<BlacklistedPostsPage> createState() => _BlacklistedPostsPageState();
}

class _BlacklistedPostsPageState extends State<BlacklistedPostsPage> {
  final state = GridSkeletonState<HiddenBooruPost>();
  var list = <HiddenBooruPost>[];
  bool hideImages = true;

  @override
  void dispose() {
    state.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WrapGridPage<HiddenBooruPost>(
      scaffoldKey: state.scaffoldKey,
      child: GridSkeleton<HiddenBooruPost>(
        state,
        (context) => CallbackGrid(
          key: state.gridKey,
          getCell: (i) => list[i],
          initalCellCount: list.length,
          initalScrollPosition: 0,
          menuButtonItems: [
            IconButton(
                onPressed: () {
                  hideImages = !hideImages;

                  setState(() {});
                },
                icon: hideImages
                    ? const Icon(Icons.image_rounded)
                    : const Icon(Icons.hide_image_rounded))
          ],
          scaffoldKey: state.scaffoldKey,
          systemNavigationInsets: MediaQuery.systemGestureInsetsOf(context),
          hasReachedEnd: () => true,
          selectionGlue: GlueProvider.of(context),
          showCount: true,
          onBack: () => Navigator.of(context).pop(),
          overrideOnPress: (context, _) {},
          mainFocus: state.mainFocus,
          refresh: () {
            list = HiddenBooruPost.getAll();

            return Future.value(list.length);
          },
          description: GridDescription([
            GridAction(Icons.photo, (selected) {
              HiddenBooruPost.removeAll(
                  selected.map((e) => (e.postId, e.booru)).toList());

              state.gridKey.currentState?.refresh();
            }, true)
          ],
              keybindsDescription: "Blacklisted posts",
              layout: ListLayout(hideThumbnails: hideImages)),
        ),
        canPop: true,
      ),
    );
  }
}
