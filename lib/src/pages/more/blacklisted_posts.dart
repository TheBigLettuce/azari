// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/impl/memory_only/impl.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/pages/more/blacklisted_page.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/layouts/list_layout.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";

class BlacklistedPostsPage extends StatefulWidget {
  const BlacklistedPostsPage({
    super.key,
    required this.generateGlue,
    required this.conroller,
    required this.db,
  });

  final SelectionGlue Function([Set<GluePreferences>]) generateGlue;
  final ScrollController conroller;

  final HiddenBooruPostService db;

  @override
  State<BlacklistedPostsPage> createState() => BlacklistedPostsPageState();
}

class BlacklistedPostsPageState extends State<BlacklistedPostsPage> {
  HiddenBooruPostService get hiddenBooruPost => widget.db;

  late final state = GridSkeletonState<HiddenBooruPostData>();
  late final source = GenericListSource<HiddenBooruPostData>(
    () => Future.value(
      hiddenBooruPost.cachedValues.entries
          .map((e) => PlainHiddenBooruPostData(e.key.$2, e.key.$1, e.value))
          .toList(),
    ),
  );

  @override
  void dispose() {
    source.destroy();
    state.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlueProvider(
      generate: widget.generateGlue,
      child: GridFrame<HiddenBooruPostData>(
        key: state.gridKey,
        overrideController: widget.conroller,
        slivers: [
          Builder(
            builder: (context) => ListLayout<HiddenBooruPostData>(
              hideThumbnails: HideBlacklistedImagesNotifier.of(context),
              source: source.backingStorage,
              progress: source.progress,
            ),
          ),
        ],
        functionality: GridFunctionality(
          selectionGlue: widget.generateGlue(),
          source: source,
        ),
        description: GridDescription(
          showAppBar: false,
          pullToRefresh: false,
          asSliver: true,
          actions: [
            GridAction(
              Icons.photo,
              (selected) {
                hiddenBooruPost.removeAll(
                  selected.map((e) => (e.postId, e.booru)).toList(),
                );

                source.clearRefresh();
              },
              true,
            ),
          ],
          keybindsDescription:
              AppLocalizations.of(context)!.blacklistedPostsPageName,
          gridSeed: state.gridSeed,
        ),
      ),
    );
  }
}
