// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/pages/booru/booru_page.dart";
import "package:azari/src/pages/booru/booru_restored_page.dart";
import "package:azari/src/pages/gallery/files.dart";
import "package:azari/src/pages/home/home.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/common_grid_data.dart";
import "package:azari/src/widgets/grid_cell/cell.dart";
import "package:azari/src/widgets/selection_bar.dart";
import "package:azari/src/widgets/shell/configuration/grid_aspect_ratio.dart";
import "package:azari/src/widgets/shell/configuration/grid_column.dart";
import "package:azari/src/widgets/shell/configuration/shell_app_bar_type.dart";
import "package:azari/src/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";

class VisitedPostsPage extends StatefulWidget {
  const VisitedPostsPage({
    super.key,
    required this.visitedPosts,
    required this.settingsService,
    required this.selectionController,
  });

  final SelectionController selectionController;

  final VisitedPostsService visitedPosts;
  final SettingsService settingsService;

  static bool hasServicesRequired(Services db) =>
      db.get<VisitedPostsService>() != null;

  @override
  State<VisitedPostsPage> createState() => _VisitedPostsPageState();
}

class _VisitedPostsPageState extends State<VisitedPostsPage>
    with CommonGridData<VisitedPostsPage> {
  VisitedPostsService get visitedPosts => widget.visitedPosts;

  @override
  SettingsService get settingsService => widget.settingsService;

  late final StreamSubscription<void> events;

  late final source = GenericListSource<VisitedPost>(
    () => Future.value(
      visitedPosts.all
          .where((e) => settings.safeMode.inLevel(e.rating.asSafeMode))
          .toList(),
    ),
  );

  late final SourceShellElementState<VisitedPost> status;

  final gridSettings = CancellableWatchableGridSettingsData.noPersist(
    hideName: true,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.three,
    layoutType: GridLayoutType.grid,
  );

  @override
  void initState() {
    super.initState();

    status = SourceShellElementState(
      source: source,
      onEmpty: SourceOnEmptyInterface(
        source,
        (context) => context.l10n().emptyPostsVisited,
      ),
      selectionController: widget.selectionController,
      actions: [
        SelectionBarAction(
          Icons.remove_rounded,
          (selected) => visitedPosts.removeAll(selected.cast()),
          true,
        ),
      ],
      wrapRefresh: null,
    );

    events = widget.visitedPosts.watch((_) {
      source.clearRefresh();
    });

    watchSettings();
  }

  @override
  void dispose() {
    status.destroy();
    events.cancel();
    gridSettings.cancel();
    source.destroy();

    super.dispose();
  }

  void _onBooruTagPressed(
    BuildContext imageViewContext,
    Booru booru,
    String tag,
    SafeMode? safeMode,
  ) {
    if (tag.isEmpty) {
      return;
    }

    ExitOnPressRoute.maybeExitOf(imageViewContext);

    BooruRestoredPage.open(
      context,
      booru: booru,
      tags: tag,
      rootNavigator: false,
      overrideSafeMode: safeMode,
      saveSelectedPage: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return ShellScope(
      stackInjector: status,
      configWatcher: gridSettings.watch,
      appBar: TitleAppBarType(
        title: l10n.visitedPage,
        leading: IconButton(
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
          icon: const Icon(Icons.menu_rounded),
        ),
        trailingItems: [
          IconButton(
            onPressed: visitedPosts.clear,
            icon: const Icon(Icons.clear_all_rounded),
          ),
        ],
      ),
      elements: [
        ElementPriority(
          ShellElement(
            // key: gridKey,
            registerNotifiers: (child) => OnBooruTagPressed(
              onPressed: _onBooruTagPressed,
              child: child,
            ),
            scrollingState: ScrollingStateSinkProvider.maybeOf(context),
            state: status,
            slivers: [
              CurrentGridSettingsLayout<VisitedPost>(
                source: source.backingStorage,
                gridSeed: gridSeed,
                progress: source.progress,
                selection: status.selection,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
