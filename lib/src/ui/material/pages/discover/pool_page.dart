// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/logic/cancellable_grid_settings_data.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/resource_source/basic.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/gallery/files.dart";
import "package:azari/src/ui/material/pages/home/booru_page.dart";
import "package:azari/src/ui/material/pages/home/booru_restored_page.dart";
import "package:azari/src/ui/material/widgets/scaffold_selection_bar.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_aspect_ratio.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_column.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/shell_app_bar_type.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";

class PoolPage extends StatefulWidget {
  const PoolPage({
    super.key,
    required this.pool,
    required this.selectionController,
    required this.favoritePools,
  });

  final BooruPool pool;
  final FavoritePoolServiceHandle favoritePools;

  final SelectionController selectionController;

  static void open(
    BuildContext context,
    BooruPool pool,
    FavoritePoolServiceHandle favoritePools,
  ) {
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (context) => PoolPage(
          pool: pool,
          favoritePools: favoritePools,
          selectionController: SelectionController.of(context),
        ),
      ),
    );
  }

  @override
  State<PoolPage> createState() => _PoolPageState();
}

class _PoolPageState extends State<PoolPage> with SettingsWatcherMixin {
  late final BooruCommunityAPI api;

  final pageSaver = PageSaver.noPersist();

  final gridSettings = CancellableGridSettingsData.noPersist(
    hideName: true,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.two,
    layoutType: GridLayoutType.gridQuilted,
  );

  late final GenericListSource<Post> source;

  late BooruPool pool;

  late final SourceShellScopeElementState<Post> status;

  bool isBookmarked = false;

  final actions = SelectionActions();

  @override
  void initState() {
    super.initState();

    pool = widget.pool;

    isBookmarked = widget.favoritePools.contains(pool);

    api = BooruCommunityAPI.fromEnum(settings.selectedBooru)!;

    source = GenericListSource<Post>(
      () async {
        if (isBookmarked) {
          final newPool = await api.pools.single(pool);
          widget.favoritePools.add(pool);
          pool = newPool;
        }

        return await api.pools.posts(pool: pool, page: 0, pageSaver: pageSaver);
      },
      next: () async => await api.pools.posts(
        pool: pool,
        page: pageSaver.page + 1,
        pageSaver: pageSaver,
      ),
    );

    status = SourceShellScopeElementState(
      source: source,
      gridSettings: gridSettings,
      selectionController: widget.selectionController,
      actions: const [],
      onEmpty: SourceOnEmptyInterface(source, (context) => "No items"),
    );
  }

  @override
  void dispose() {
    status.destroy();
    api.destroy();
    source.destroy();
    gridSettings.cancel();
    actions.dispose();

    super.dispose();
  }

  void _open(
    BuildContext context,
    Booru booru,
    String tag,
    SafeMode? safeMode,
  ) => BooruRestoredPage.open(
    context,
    booru: booru,
    tags: tag,
    overrideSafeMode: safeMode,
  );

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithSelectionBar(
      actions: actions,
      child: ShellScope(
        stackInjector: status,
        appBar: TitleAppBarType(
          title: pool.name,
          trailingItems: [
            IconButton(
              onPressed: () {
                if (isBookmarked) {
                  widget.favoritePools.remove(pool);
                } else {
                  widget.favoritePools.add(pool);
                }

                setState(() {
                  isBookmarked = widget.favoritePools.contains(pool);
                });
              },
              icon: switch (isBookmarked) {
                true => const Icon(Icons.bookmark_remove_rounded),
                false => const Icon(Icons.bookmark_add_rounded),
              },
            ),
          ],
        ),
        elements: [
          ElementPriority(
            ShellElement(
              state: status,
              animationsOnSourceWatch: false,
              gridSettings: gridSettings,
              registerNotifiers: (child) => OnBooruTagPressed(
                onPressed: _open,
                child: source.inject(child),
              ),
              slivers: [
                CurrentGridSettingsLayout<Post>(
                  source: source.backingStorage,
                  progress: source.progress,
                  selection: status.selection,
                ),
                Builder(
                  builder: (context) {
                    final padding = MediaQuery.systemGestureInsetsOf(context);

                    return SliverPadding(
                      padding: EdgeInsets.only(
                        left: padding.left * 0.2,
                        right: padding.right * 0.2,
                      ),
                      sliver: GridConfigPlaceholders(
                        progress: source.progress,
                        // randomNumber: gridSeed,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
