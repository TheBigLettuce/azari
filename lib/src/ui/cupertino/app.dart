// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/logic/booru_page_mixin.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/platform/notification_api.dart";
import "package:azari/src/services/resource_source/resource_source.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/widgets/common_grid_data.dart";
import "package:azari/src/ui/material/widgets/grid_cell_widget.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";

class AppCupertino extends StatefulWidget {
  const AppCupertino({
    super.key,
    required this.color,
    required this.notificationStream,
  });

  final Color color;
  final Stream<NotificationRouteEvent> notificationStream;

  @override
  State<AppCupertino> createState() => _AppCupertinoState();
}

class _AppCupertinoState extends State<AppCupertino> {
  @override
  Widget build(BuildContext context) {
    return Services.inject(
      const CupertinoApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _Home(),
      ),
    );
  }
}

class _Home extends StatefulWidget {
  const _Home({
    super.key,
  });

  @override
  State<_Home> createState() => __HomeState();
}

class __HomeState extends State<_Home> {
  late final PagingStateRegistry pagingRegistry;
  final selectionEvents = SelectionActions();

  @override
  void initState() {
    super.initState();

    pagingRegistry = PagingStateRegistry();
  }

  @override
  void dispose() {
    pagingRegistry.recycle();
    selectionEvents.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
    final db = Services.of(context);

    return selectionEvents.inject(
      CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          items: [
            BottomNavigationBarItem(
              label: Services.requireOf<SettingsService>(context)
                  .current
                  .selectedBooru
                  .string,
              icon: Icon(CupertinoIcons.home),
            ),
            BottomNavigationBarItem(
              label: l10n.discoverPage,
              icon: Icon(CupertinoIcons.search_circle_fill),
            ),
            BottomNavigationBarItem(
              label: l10n.galleryLabel,
              icon: Icon(CupertinoIcons.photo),
            ),
          ],
        ),
        tabBuilder: (context, index) {
          return CupertinoTabView(
            builder: (context) => CupertinoPageScaffold(
              child: switch (index) {
                0 => _BooruPage(
                    pagingRegistry: pagingRegistry,
                    selectionController: SelectionActions.controllerOf(context),
                    gridBookmarks: db.get<GridBookmarkService>(),
                    hiddenBooruPosts: db.get<HiddenBooruPostsService>(),
                    favoritePosts: db.get<FavoritePostSourceService>(),
                    tagManager: db.get<TagManagerService>(),
                    downloadManager: DownloadManager.of(context),
                    localTags: db.get<LocalTagsService>(),
                    hottestTags: db.get<HottestTagsService>(),
                    gridSettings: db.get<GridSettingsService>(),
                    visitedPosts: db.get<VisitedPostsService>(),
                    gridDbs: db.get<GridDbService>()!,
                    settingsService: db.require<SettingsService>(),
                  ),
                int() => Placeholder(),
              },
            ),
          );
        },
      ),
    );
  }
}

class _BooruPage extends StatefulWidget {
  const _BooruPage({
    super.key,
    required this.pagingRegistry,
    required this.selectionController,
    required this.gridBookmarks,
    required this.hiddenBooruPosts,
    required this.favoritePosts,
    required this.tagManager,
    required this.downloadManager,
    required this.localTags,
    required this.hottestTags,
    required this.gridSettings,
    required this.visitedPosts,
    required this.gridDbs,
    required this.settingsService,
  });

  final PagingStateRegistry pagingRegistry;
  final SelectionController selectionController;

  final GridBookmarkService? gridBookmarks;
  final HiddenBooruPostsService? hiddenBooruPosts;
  final FavoritePostSourceService? favoritePosts;
  final TagManagerService? tagManager;
  final DownloadManager? downloadManager;
  final LocalTagsService? localTags;
  final HottestTagsService? hottestTags;
  final GridSettingsService? gridSettings;
  final VisitedPostsService? visitedPosts;

  final GridDbService gridDbs;

  final SettingsService settingsService;

  @override
  State<_BooruPage> createState() => __BooruPageState();
}

class __BooruPageState extends State<_BooruPage>
    with CommonGridData, BooruPageMixin {
  @override
  DownloadManager? get downloadManager => widget.downloadManager;

  @override
  FavoritePostSourceService? get favoritePosts => widget.favoritePosts;

  @override
  GridBookmarkService? get gridBookmarks => widget.gridBookmarks;

  @override
  GridDbService get gridDbs => widget.gridDbs;

  @override
  HiddenBooruPostsService? get hiddenBooruPosts => widget.hiddenBooruPosts;

  @override
  LocalTagsService? get localTags => widget.localTags;

  @override
  PagingStateRegistry get pagingRegistry => widget.pagingRegistry;

  @override
  SelectionController get selectionController => widget.selectionController;

  @override
  SettingsService get settingsService => widget.settingsService;

  @override
  TagManagerService? get tagManager => widget.tagManager;

  @override
  void openSecondaryBooruPage(GridBookmark bookmark) {
    // TODO: implement openSecondaryBooruPage
  }

  @override
  void initState() {
    super.initState();

    watchSettings();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
      itemCount: source.count,
      itemBuilder: (context, index) {
        final data = source.forIdxUnsafe(index);

        return GridCell(
          data: data,
          hideTitle: true,
        );
      },
    );
  }
}
