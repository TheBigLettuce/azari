// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/settings/hidden_booru_post.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/grid/selection_glue.dart';
import 'package:gallery/src/widgets/grid/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid/configuration/grid_on_cell_press_behaviour.dart';
import 'package:gallery/src/widgets/grid/configuration/image_view_description.dart';
import 'package:gallery/src/widgets/grid/grid_frame.dart';
import 'package:gallery/src/widgets/grid/layouts/list_layout.dart';
import 'package:gallery/src/widgets/grid/wrappers/wrap_grid_page.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton_state.dart';

class BlacklistedPostsPage extends StatefulWidget {
  final SelectionGlue<HiddenBooruPost> glue;
  final SelectionGlue<J> Function<J extends Cell>() generateGlue;

  const BlacklistedPostsPage({
    super.key,
    required this.generateGlue,
    required this.glue,
  });

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
      provided: (widget.glue, widget.generateGlue),
      child: GridSkeleton<HiddenBooruPost>(
        state,
        (context) => GridFrame(
          key: state.gridKey,
          getCell: (i) => list[i],
          initalCellCount: list.length,
          functionality: GridFunctionality(
            selectionGlue: GlueProvider.of(context),
            onPressed: const OverrideGridOnCellPressBehaviour(),
            refresh: SynchronousGridRefresh(() {
              list = HiddenBooruPost.getAll();

              return list.length;
            }),
          ),
          imageViewDescription: ImageViewDescription(
            imageViewKey: state.imageViewKey,
          ),
          systemNavigationInsets: MediaQuery.viewPaddingOf(context),
          hasReachedEnd: () => true,
          mainFocus: state.mainFocus,
          description: GridDescription([
            GridAction(Icons.photo, (selected) {
              HiddenBooruPost.removeAll(
                  selected.map((e) => (e.postId, e.booru)).toList());

              state.gridKey.currentState?.refresh();
            }, true)
          ],
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
              keybindsDescription: "Blacklisted posts",
              layout: ListLayout(hideThumbnails: hideImages)),
        ),
        canPop: true,
      ),
    );
  }
}
