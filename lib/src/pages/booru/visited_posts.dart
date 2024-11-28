// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/pages/booru/booru_page.dart";
import "package:azari/src/pages/booru/booru_restored_page.dart";
import "package:azari/src/pages/gallery/files.dart";
import "package:azari/src/pages/home/home.dart";
import "package:azari/src/widgets/empty_widget.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:azari/src/widgets/selection_actions.dart";
import "package:azari/src/widgets/skeletons/skeleton_state.dart";
import "package:flutter/material.dart";

class VisitedPostsPage extends StatefulWidget {
  const VisitedPostsPage({
    super.key,
    required this.db,
  });

  final VisitedPostsService db;

  @override
  State<VisitedPostsPage> createState() => _VisitedPostsPageState();
}

class _VisitedPostsPageState extends State<VisitedPostsPage> {
  VisitedPostsService get visitedPosts => widget.db;

  late final StreamSubscription<void> subscr;
  late final StreamSubscription<SettingsData?> settingsSubsc;

  late final state = GridSkeletonState<VisitedPost>();
  late final source = GenericListSource<VisitedPost>(
    () => Future.value(
      visitedPosts.all
          .where((e) => state.settings.safeMode.inLevel(e.rating.asSafeMode))
          .toList(),
    ),
  );

  final gridSettings = CancellableWatchableGridSettingsData.noPersist(
    hideName: true,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.three,
    layoutType: GridLayoutType.grid,
  );

  @override
  void initState() {
    super.initState();

    subscr = widget.db.watch((_) {
      source.clearRefresh();
    });

    settingsSubsc = state.settings.s.watch((settings) {
      setState(() {
        state.settings = settings!;
      });
    });
  }

  @override
  void dispose() {
    settingsSubsc.cancel();
    subscr.cancel();
    gridSettings.cancel();
    source.destroy();
    state.dispose();

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

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) {
          return BooruRestoredPage(
            booru: booru,
            tags: tag,
            overrideSafeMode: safeMode,
            db: DatabaseConnectionNotifier.of(context),
            saveSelectedPage: (_) {},
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GridConfiguration(
      watch: gridSettings.watch,
      child: GridFrame<VisitedPost>(
        key: state.gridKey,
        slivers: [
          CurrentGridSettingsLayout<VisitedPost>(
            source: source.backingStorage,
            gridSeed: state.gridSeed,
            progress: source.progress,
          ),
        ],
        functionality: GridFunctionality(
          selectionActions: SelectionActions.of(context),
          scrollingSink: ScrollingSinkProvider.maybeOf(context),
          onEmptySource: EmptyWidgetBackground(
            subtitle: l10n.emptyPostsVisited,
          ),
          registerNotifiers: (child) => OnBooruTagPressed(
            onPressed: _onBooruTagPressed,
            child: child,
          ),
          search: PageNameSearchWidget(
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
          source: source,
        ),
        description: GridDescription(
          pullToRefresh: false,
          actions: [
            GridAction(
              Icons.remove_rounded,
              visitedPosts.removeAll,
              true,
            ),
          ],
          pageName: l10n.visitedPage,
          gridSeed: state.gridSeed,
        ),
      ),
    );
  }
}
