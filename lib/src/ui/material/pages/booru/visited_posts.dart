// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/logic/cancellable_grid_settings_data.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/resource_source/basic.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/booru/booru_page.dart";
import "package:azari/src/ui/material/pages/booru/booru_restored_page.dart";
import "package:azari/src/ui/material/pages/gallery/files.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_aspect_ratio.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_column.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/shell_app_bar_type.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";

class VisitedPostsPage extends StatefulWidget {
  const VisitedPostsPage({super.key, required this.selectionController});

  final SelectionController selectionController;

  static bool hasServicesRequired() => VisitedPostsService.available;

  @override
  State<VisitedPostsPage> createState() => _VisitedPostsPageState();
}

class _VisitedPostsPageState extends State<VisitedPostsPage>
    with SettingsWatcherMixin, VisitedPostsService {
  late final StreamSubscription<void> events;

  late final source = GenericListSource<VisitedPost>(
    () => Future.value(
      all.where((e) => settings.safeMode.inLevel(e.rating.asSafeMode)).toList(),
    ),
  );

  late final SourceShellElementState<VisitedPost> status;

  final gridSettings = CancellableGridSettingsData.noPersist(
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
          (selected) => removeAll(selected.cast()),
          true,
        ),
      ],
      wrapRefresh: null,
    );

    events = watch((_) {
      source.clearRefresh();
    });
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
      overrideSafeMode: safeMode,
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
            onPressed: clear,
            icon: const Icon(Icons.clear_all_rounded),
          ),
        ],
      ),
      elements: [
        ElementPriority(
          ShellElement(
            // key: gridKey,
            registerNotifiers: (child) =>
                OnBooruTagPressed(onPressed: _onBooruTagPressed, child: child),
            scrollingState: ScrollingStateSinkProvider.maybeOf(context),
            state: status,
            slivers: [
              CurrentGridSettingsLayout<VisitedPost>(
                source: source.backingStorage,
                // gridSeed: gridSeed,
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
