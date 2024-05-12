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
import "package:gallery/src/interfaces/filtering/filtering_interface.dart";
import "package:gallery/src/interfaces/filtering/filtering_mode.dart";
import "package:gallery/src/pages/more/blacklisted_posts.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/page_description.dart";
import "package:gallery/src/widgets/grid_frame/configuration/page_switcher.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/layouts/list_layout.dart";
import "package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:gallery/src/widgets/search_bar/search_filter_grid.dart";
import "package:gallery/src/widgets/skeletons/grid.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";

class BlacklistedPage extends StatefulWidget {
  const BlacklistedPage({
    super.key,
    required this.generateGlue,
    required this.db,
  });

  final SelectionGlue Function([Set<GluePreferences>]) generateGlue;

  final DbConn db;

  @override
  State<BlacklistedPage> createState() => _BlacklistedPageState();
}

class _BlacklistedPageState extends State<BlacklistedPage> {
  BlacklistedDirectoryService get blacklistedDirectory =>
      widget.db.blacklistedDirectories;

  late final StreamSubscription<void> blacklistedWatcher;

  late final state = GridSkeletonRefreshingState<BlacklistedDirectoryData>(
    clearRefresh: SynchronousGridRefresh(() => filter.count),
  );

  late final ChainedFilterResourceSource<BlacklistedDirectoryData> filter;
  final searchTextController = TextEditingController();
  final searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    filter = ChainedFilterResourceSource(
      blacklistedDirectory.makeSource(),
      ListStorage(),
      fn: (e, filteringMode, sortingMode) =>
          e.name.contains(searchTextController.text),
      allowedFilteringModes: const {},
      allowedSortingModes: const {},
      initialFilteringMode: FilteringMode.noFilter,
      initialSortingMode: SortingMode.none,
    );

    blacklistedWatcher = blacklistedDirectory.watch((event) {
      filter.clearRefresh();
      setState(() {});
    });
  }

  @override
  void dispose() {
    blacklistedWatcher.cancel();
    state.dispose();
    searchTextController.dispose();
    searchFocus.dispose();

    filter.destroy();

    super.dispose();
  }

  bool hideBlacklistedImages = true;

  @override
  Widget build(BuildContext context) {
    return WrapGridPage(
      provided: widget.generateGlue,
      child: GridSkeleton(
        state,
        (context) => GridFrame<BlacklistedDirectoryData>(
          key: state.gridKey,
          slivers: const [ListLayout(hideThumbnails: false)],
          getCell: filter.forIdxUnsafe,
          functionality: GridFunctionality(
            registerNotifiers: (child) => HideBlacklistedImagesNotifier(
              hiding: hideBlacklistedImages,
              child: child,
            ),
            search: OverrideGridSearchWidget(
              SearchAndFocus(
                FilteringSearchWidget(
                  hint: AppLocalizations.of(context)!.blacklistedPage,
                  filter: filter,
                  textController: searchTextController,
                  localTagDictionary: widget.db.localTagDictionary,
                  focusNode: searchFocus,
                ),
                searchFocus,
              ),
            ),
            selectionGlue: GlueProvider.generateOf(context)(),
            refreshingStatus: state.refreshingStatus,
          ),
          mainFocus: state.mainFocus,
          description: GridDescription(
            pages: PageSwitcherIcons(
              const [PageIcon(Icons.image)],
              (context, state, i) => PageDescription(
                appIcons: [
                  IconButton(
                    onPressed: () {
                      hideBlacklistedImages = !hideBlacklistedImages;

                      setState(() {});
                    },
                    icon: hideBlacklistedImages
                        ? const Icon(Icons.image_rounded)
                        : const Icon(Icons.hide_image_rounded),
                  ),
                ],
                slivers: [
                  BlacklistedPostsPage(
                    generateGlue: widget.generateGlue,
                    conroller: state.controller,
                    db: widget.db.hiddenBooruPost,
                  ),
                ],
              ),
              overrideHomeIcon: const Icon(Icons.folder),
            ),
            actions: [
              GridAction(
                Icons.restore_page,
                (selected) {
                  blacklistedDirectory.deleteAll(
                    selected.map((e) => e.bucketId).toList(),
                  );
                },
                true,
              ),
            ],
            menuButtonItems: [
              IconButton(
                onPressed: () {
                  blacklistedDirectory.clear();
                  chooseGalleryPlug().notify(null);
                },
                icon: const Icon(Icons.delete),
              ),
            ],
            keybindsDescription: AppLocalizations.of(context)!.blacklistedPage,
            gridSeed: state.gridSeed,
          ),
        ),
        canPop: true,
      ),
    );
  }
}

class HideBlacklistedImagesNotifier extends InheritedWidget {
  const HideBlacklistedImagesNotifier({
    super.key,
    required this.hiding,
    required super.child,
  });
  final bool hiding;

  static bool of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<HideBlacklistedImagesNotifier>();

    return widget!.hiding;
  }

  @override
  bool updateShouldNotify(HideBlacklistedImagesNotifier oldWidget) =>
      hiding != oldWidget.hiding;
}
