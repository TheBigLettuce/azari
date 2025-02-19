// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/obj_impls/post_impl.dart";
import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/pages/booru/actions.dart" as actions;
import "package:azari/src/pages/booru/booru_page.dart";
import "package:azari/src/pages/booru/booru_restored_page.dart";
import "package:azari/src/pages/gallery/directories.dart";
import "package:azari/src/pages/gallery/files.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/common_grid_data.dart";
import "package:azari/src/widgets/empty_widget.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:azari/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:azari/src/widgets/image_view/default_state_controller.dart";
import "package:azari/src/widgets/image_view/image_view.dart";
import "package:azari/src/widgets/wrap_future_restartable.dart";
import "package:flutter/material.dart";

class PopularRandomChips extends StatelessWidget {
  const PopularRandomChips({
    super.key,
    required this.safeMode,
    required this.booru,
    required this.onTagPressed,
    required this.listPadding,
    required this.tagManager,
    required this.visitedPosts,
    required this.miscSettingsService,
    this.tags = "",
  });

  final String tags;

  final Booru booru;

  final EdgeInsets listPadding;

  final OnBooruTagPressedFunc onTagPressed;

  final SafeMode Function() safeMode;

  final TagManagerService? tagManager;
  final VisitedPostsService? visitedPosts;
  final MiscSettingsService? miscSettingsService;

  void launchVideos(
    BuildContext gridContext,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (tags.isNotEmpty) {
      tagManager?.latest.add(tags);
    }

    final db = Services.of(gridContext);
    final (
      downloadManager,
      localTags,
      settingsService,
      videoSettingsService,
      galleryService
    ) = (
      DownloadManager.of(gridContext),
      db.get<LocalTagsService>(),
      db.require<SettingsService>(),
      db.get<VideoSettingsService>(),
      db.get<GalleryService>(),
    );

    final client = BooruAPI.defaultClientForBooru(booru);
    final api = BooruAPI.fromEnum(booru, client);

    final value = <Post>[];
    int page = 0;
    bool canLoadMore = true;

    final stateController = DefaultStateController(
      getContent: (i) => value[i].content(gridContext),
      count: 0,
      wrapNotifiers: (child) => OnBooruTagPressed(
        onPressed: onTagPressed,
        child: child,
      ),
      statistics: StatisticsBooruService.asImageViewStatistics(),
      download: downloadManager != null && localTags != null
          ? (i) => value[i].download(
                downloadManager: downloadManager,
                localTags: localTags,
                settingsService: settingsService,
              )
          : null,
      tags: tagManager != null
          ? (c) => DefaultPostPressable.imageViewTags(
                c,
                tagManager!,
              )
          : null,
      watchTags: tagManager != null
          ? (c, f) => DefaultPostPressable.watchTags(
                c,
                f,
                tagManager!.pinned,
              )
          : null,
      pageChange: (state) {
        final post = value[state.currentIndex];

        visitedPosts?.addAll([
          VisitedPost(
            booru: post.booru,
            id: post.id,
            thumbUrl: post.previewUrl,
            rating: post.rating,
            date: DateTime.now(),
          ),
        ]);
      },
      onNearEnd: () async {
        if (!canLoadMore) {
          return value.length;
        }

        final List<Post> next;

        if (tags.isEmpty) {
          final miscSettings = miscSettingsService?.current;
          next = await api.randomPosts(
            tagManager?.excluded,
            safeMode(),
            true,
            // order: RandomPostsOrder.random,
            addTags: miscSettings?.randomVideosAddTags ?? "",
            page: page + 1,
          );
        } else {
          next = await api.randomPosts(
            tagManager?.excluded,
            safeMode(),
            true,
            // order: RandomPostsOrder.random,
            addTags: tags,
            page: page + 1,
          );
        }

        page += 1;
        value.addAll(next);
        if (next.isEmpty) {
          canLoadMore = false;
        }

        return value.length;
      },
      videoSettingsService: videoSettingsService,
    );

    Navigator.of(gridContext, rootNavigator: true)
        .push<void>(
      MaterialPageRoute(
        builder: (context) => WrapFutureRestartable(
          builder: (context, _) {
            if (value.isEmpty) {
              return Scaffold(
                appBar: AppBar(),
                body: Center(
                  child: Text(
                    l10n.emptyResult,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              );
            }

            return ImageView(
              stateController: stateController,
              galleryService: galleryService,
              videoSettingsService: videoSettingsService,
              settingsService: settingsService,
            );
          },
          newStatus: () async {
            page = 0;
            value.clear();
            canLoadMore = true;

            final List<Post> posts;

            if (tags.isEmpty) {
              final miscSettings = miscSettingsService?.current;

              posts = await api.randomPosts(
                tagManager?.excluded,
                safeMode(),
                true,
                // order: RandomPostsOrder.random,
                addTags: miscSettings?.randomVideosAddTags ?? "",
              );
            } else {
              posts = await api.randomPosts(
                tagManager?.excluded,
                safeMode(),
                true,
                // order: RandomPostsOrder.random,
                addTags: tags,
              );
            }

            value.addAll(posts);

            final post = value.first;

            visitedPosts?.addAll([
              VisitedPost(
                booru: post.booru,
                id: post.id,
                thumbUrl: post.previewUrl,
                rating: post.rating,
                date: DateTime.now(),
              ),
            ]);

            stateController.count = value.length;

            return value;
          },
        ),
      ),
    )
        .whenComplete(() {
      stateController.dispose();
      client.close(force: true);
    });
  }

  void launchRandom(
    BuildContext gridContext,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (tags.isNotEmpty) {
      tagManager?.latest.add(tags);
    }

    final client = BooruAPI.defaultClientForBooru(booru);
    final api = BooruAPI.fromEnum(booru, client);

    final db = Services.of(gridContext);
    final (
      downloadManager,
      localTags,
      settingsService,
      videoSettingsService,
      galleryService
    ) = (
      DownloadManager.of(gridContext),
      db.get<LocalTagsService>(),
      db.require<SettingsService>(),
      db.get<VideoSettingsService>(),
      db.get<GalleryService>(),
    );

    final value = <Post>[];
    int page = 0;
    bool canLoadMore = true;

    final stateController = DefaultStateController(
      getContent: (i) => value[i].content(gridContext),
      statistics: StatisticsBooruService.asImageViewStatistics(),
      download: downloadManager != null && localTags != null
          ? (i) => value[i].download(
                downloadManager: downloadManager,
                localTags: localTags,
                settingsService: settingsService,
              )
          : null,
      tags: tagManager != null
          ? (c) => DefaultPostPressable.imageViewTags(
                c,
                tagManager!,
              )
          : null,
      watchTags: tagManager != null
          ? (c, f) => DefaultPostPressable.watchTags(
                c,
                f,
                tagManager!.pinned,
              )
          : null,
      preloadNextPictures: true,
      pageChange: (state) {
        final post = value[state.currentIndex];

        visitedPosts?.addAll([
          VisitedPost(
            booru: post.booru,
            id: post.id,
            rating: post.rating,
            thumbUrl: post.previewUrl,
            date: DateTime.now(),
          ),
        ]);
      },
      wrapNotifiers: (child) => OnBooruTagPressed(
        onPressed: onTagPressed,
        child: child,
      ),
      onNearEnd: () async {
        if (!canLoadMore) {
          return value.length;
        }

        final ret = await api.randomPosts(
          tagManager?.excluded,
          safeMode(),
          false,
          addTags: tags,
          page: page + 1,
        );

        page += 1;
        value.addAll(ret);
        if (ret.isEmpty) {
          canLoadMore = false;
        }

        return value.length;
      },
      count: 0,
      videoSettingsService: videoSettingsService,
    );

    Navigator.of(gridContext, rootNavigator: true)
        .push<void>(
      MaterialPageRoute(
        builder: (context) => WrapFutureRestartable(
          newStatus: () async {
            page = 0;
            value.clear();
            canLoadMore = true;

            final ret = await api.randomPosts(
              tagManager?.excluded,
              safeMode(),
              false,
              addTags: tags,
            );

            value.addAll(ret);

            final post = value.first;

            visitedPosts?.addAll([
              VisitedPost(
                booru: post.booru,
                id: post.id,
                rating: post.rating,
                thumbUrl: post.previewUrl,
                date: DateTime.now(),
              ),
            ]);

            stateController.count = value.length;

            return value;
          },
          builder: (context, value) {
            return ImageView(
              stateController: stateController,
              galleryService: galleryService,
              videoSettingsService: videoSettingsService,
              settingsService: settingsService,
            );
          },
        ),
      ),
    )
        .whenComplete(() {
      stateController.dispose();
      client.close(force: true);
    });
  }

  @override
  Widget build(BuildContext gridContext) {
    final l10n = AppLocalizations.of(gridContext)!;
    final theme = Theme.of(gridContext);

    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        padding: listPadding,
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.min,
          children: [
            ActionChip(
              onPressed: () {
                if (tags.isNotEmpty) {
                  tagManager?.latest.add(tags);
                }

                final client = BooruAPI.defaultClientForBooru(booru);
                final api = BooruAPI.fromEnum(booru, client);

                PopularPage.open(
                  gridContext,
                  tags: tags,
                  api: api,
                  safeMode: safeMode,
                ).whenComplete(() => client.close(force: true));
              },
              label: Text(
                "${l10n.popularPosts}${tags.isEmpty ? '' : " #$tags"}",
              ),
              avatar: const Icon(Icons.whatshot_outlined),
            ),
            const Padding(padding: EdgeInsets.only(right: 6)),
            ActionChip(
              onPressed: () => launchRandom(gridContext, l10n, theme),
              label: Text(
                "${l10n.randomPosts}${tags.isEmpty ? '' : " #$tags"}",
              ),
              avatar: const Icon(Icons.shuffle_outlined),
            ),
            const Padding(padding: EdgeInsets.only(right: 6)),
            ActionChip(
              onPressed: () => launchVideos(gridContext, l10n, theme),
              label: Text(
                "${l10n.videosLabel}${tags.isEmpty ? '' : " #$tags"}",
              ),
              avatar: const Icon(Icons.video_collection_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideosSettingsDialog extends StatefulWidget {
  const _VideosSettingsDialog({
    // super.key,
    required this.booru,
    required this.miscSettingsService,
  });

  final Booru booru;
  final MiscSettingsService miscSettingsService;

  @override
  State<_VideosSettingsDialog> createState() => __VideosSettingsDialogState();
}

class __VideosSettingsDialogState extends State<_VideosSettingsDialog>
    with MiscSettingsWatcherMixin {
  @override
  MiscSettingsService get miscSettingsService => widget.miscSettingsService;

  late final TextEditingController textController;
  final focus = FocusNode();

  late final client = BooruAPI.defaultClientForBooru(widget.booru);
  late final BooruAPI api;

  @override
  void initState() {
    super.initState();

    api = BooruAPI.fromEnum(widget.booru, client);

    textController =
        TextEditingController(text: miscSettings!.randomVideosAddTags);
  }

  @override
  void dispose() {
    focus.dispose();

    client.close(force: true);

    if (miscSettings!.randomVideosAddTags != textController.text) {
      miscSettings!.copy(randomVideosAddTags: textController.text).maybeSave();
    }

    textController.dispose();

    super.dispose();
  }

  (String, List<BooruTag>)? latestSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return AlertDialog(
      title: Text(l10n.settingsLabel),
      actions: [
        IconButton.filled(
          onPressed: () => miscSettings!
              .copy(randomVideosOrder: RandomPostsOrder.random)
              .maybeSave(),
          icon: const Icon(Icons.shuffle_rounded),
          isSelected:
              miscSettings!.randomVideosOrder == RandomPostsOrder.random,
        ),
        IconButton.filled(
          onPressed: () => miscSettings!
              .copy(randomVideosOrder: RandomPostsOrder.rating)
              .maybeSave(),
          icon: const Icon(Icons.whatshot_rounded),
          isSelected:
              miscSettings!.randomVideosOrder == RandomPostsOrder.rating,
        ),
        IconButton.filled(
          onPressed: () => miscSettings!
              .copy(randomVideosOrder: RandomPostsOrder.latest)
              .maybeSave(),
          icon: const Icon(Icons.schedule_rounded),
          isSelected:
              miscSettings!.randomVideosOrder == RandomPostsOrder.latest,
        ),
      ],
      content: Padding(
        padding: EdgeInsets.zero,
        child: SearchBarAutocompleteWrapper(
          search: BarSearchWidget(
            onChanged: null,
            complete: (str) async {
              if (str == latestSearch?.$1) {
                return latestSearch!.$2;
              }

              final res = await api.searchTag(str);

              latestSearch = (str, res);

              return res;
            },
            textEditingController: textController,
          ),
          searchFocus: focus,
          child: (context, controller, focus, onSelected) => TextField(
            decoration: InputDecoration(
              icon: const Icon(Icons.tag_outlined),
              suffix: IconButton(
                onPressed: () {
                  controller.clear();
                  focus.unfocus();
                },
                icon: const Icon(Icons.close_rounded),
              ),
              hintText: l10n.addTagsSearch,
              border: InputBorder.none,
            ),
            controller: controller,
            focusNode: focus,
          ),
        ),
      ),
    );
  }
}

class PopularPage extends StatefulWidget {
  const PopularPage({
    super.key,
    required this.api,
    required this.tags,
    required this.safeMode,
    required this.gridBookmarks,
    required this.hiddenBooruPosts,
    required this.favoritePosts,
    required this.tagManager,
    required this.settingsService,
    required this.downloadManager,
    required this.localTags,
  });

  final String tags;

  final BooruAPI api;

  final SafeMode Function() safeMode;

  final GridBookmarkService? gridBookmarks;
  final HiddenBooruPostsService? hiddenBooruPosts;
  final FavoritePostSourceService? favoritePosts;
  final TagManagerService? tagManager;
  final DownloadManager? downloadManager;
  final LocalTagsService? localTags;

  final SettingsService settingsService;

  static Future<void> open(
    BuildContext context, {
    required String tags,
    required BooruAPI api,
    required SafeMode Function() safeMode,
  }) {
    final db = Services.of(context);

    return Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (context) => PopularPage(
          api: api,
          tags: tags,
          safeMode: safeMode,
          gridBookmarks: db.get<GridBookmarkService>(),
          hiddenBooruPosts: db.get<HiddenBooruPostsService>(),
          favoritePosts: db.get<FavoritePostSourceService>(),
          tagManager: db.get<TagManagerService>(),
          downloadManager: DownloadManager.of(context),
          localTags: db.get<LocalTagsService>(),
          settingsService: db.require<SettingsService>(),
        ),
      ),
    );
  }

  @override
  State<PopularPage> createState() => _PopularPageState();
}

class _PopularPageState extends State<PopularPage>
    with CommonGridData<Post, PopularPage> {
  GridBookmarkService? get gridBookmarks => widget.gridBookmarks;
  HiddenBooruPostsService? get hiddenBooruPosts => widget.hiddenBooruPosts;
  FavoritePostSourceService? get favoritePosts => widget.favoritePosts;
  TagManagerService? get tagManager => widget.tagManager;
  DownloadManager? get downloadManager => widget.downloadManager;
  LocalTagsService? get localTags => widget.localTags;

  @override
  SettingsService get settingsService => widget.settingsService;

  final gridSettings = CancellableWatchableGridSettingsData.noPersist(
    hideName: true,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.two,
    layoutType: GridLayoutType.gridQuilted,
  );

  final pageSaver = PageSaver.noPersist();

  late final GenericListSource<Post> source = GenericListSource<Post>(
    () async {
      pageSaver.page = 0;

      final ret = await widget.api.page(
        pageSaver.page,
        widget.tags,
        tagManager?.excluded,
        widget.safeMode(),
        order: BooruPostsOrder.score,
        pageSaver: pageSaver,
      );

      return ret.$1;
    },
    next: () async {
      final ret = await widget.api.page(
        pageSaver.page + 1,
        widget.tags,
        tagManager?.excluded,
        widget.safeMode(),
        order: BooruPostsOrder.score,
        pageSaver: pageSaver,
      );

      return ret.$1;
    },
  );

  @override
  void dispose() {
    gridSettings.cancel();
    source.destroy();

    super.dispose();
  }

  void _download(int i) => source.forIdx(i)?.download(
        downloadManager: downloadManager!,
        localTags: localTags!,
        settingsService: settingsService,
      );

  void _onBooruTagPressed(
    BuildContext _,
    Booru booru,
    String tag,
    SafeMode? safeMode,
  ) {
    BooruRestoredPage.open(
      context,
      booru: booru,
      tags: tag,
      overrideSafeMode: safeMode,
      rootNavigator: true,
      saveSelectedPage: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    final gridActions = <GridAction<Post>>[
      if (downloadManager != null && localTags != null)
        actions.downloadPost(
          context,
          widget.api.booru,
          null,
          downloadManager: downloadManager!,
          localTags: localTags!,
          settingsService: settingsService,
        ),
      if (favoritePosts != null)
        actions.favorites(
          context,
          favoritePosts!,
          showDeleteSnackbar: true,
        ),
      if (hiddenBooruPosts != null) actions.hide(context, hiddenBooruPosts!),
    ];

    return WrapGridPage(
      addScaffoldAndBar: true,
      child: GridPopScope(
        searchTextController: null,
        filter: null,
        child: GridConfiguration(
          watch: gridSettings.watch,
          child: BooruAPINotifier(
            api: widget.api,
            child: OnBooruTagPressed(
              onPressed: (context, booru, value, safeMode) {
                ExitOnPressRoute.maybeExitOf(context);

                _onBooruTagPressed(context, booru, value, safeMode);
              },
              child: GridFrame<Post>(
                key: gridKey,
                slivers: [
                  CurrentGridSettingsLayout<Post>(
                    source: source.backingStorage,
                    progress: source.progress,
                    gridSeed: gridSeed,
                    unselectOnUpdate: false,
                  ),
                  GridConfigPlaceholders(
                    progress: source.progress,
                    randomNumber: gridSeed,
                  ),
                  GridFooter<void>(storage: source.backingStorage),
                ],
                functionality: GridFunctionality(
                  onEmptySource: _EmptyWidget(progress: source.progress),
                  source: source,
                  search: RawSearchWidget(
                    (context, settingsButton, bottomWidget) => SliverAppBar(
                      floating: true,
                      pinned: true,
                      snap: true,
                      stretch: true,
                      bottom: bottomWidget ??
                          const PreferredSize(
                            preferredSize: Size.zero,
                            child: SizedBox.shrink(),
                          ),
                      title: Text(
                        widget.tags.isNotEmpty
                            ? "${l10n.popularPosts} #${widget.tags}"
                            : l10n.popularPosts,
                      ),
                      actions: [if (settingsButton != null) settingsButton],
                    ),
                  ),
                  download: downloadManager != null && localTags != null
                      ? _download
                      : null,
                  registerNotifiers: (child) => OnBooruTagPressed(
                    onPressed: (context, booru, value, safeMode) {
                      ExitOnPressRoute.maybeExitOf(context);

                      _onBooruTagPressed(context, booru, value, safeMode);
                    },
                    child: BooruAPINotifier(
                      api: widget.api,
                      child: child,
                    ),
                  ),
                ),
                description: GridDescription(
                  actions: gridActions,
                  animationsOnSourceWatch: false,
                  pageName: l10n.booruLabel,
                  gridSeed: gridSeed,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyWidget extends StatefulWidget {
  const _EmptyWidget({
    // super.key,
    required this.progress,
  });

  final RefreshingProgress progress;

  @override
  State<_EmptyWidget> createState() => __EmptyWidgetState();
}

class __EmptyWidgetState extends State<_EmptyWidget> {
  late final StreamSubscription<void> subscr;

  @override
  void initState() {
    super.initState();

    subscr = widget.progress.watch(
      (t) {
        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    subscr.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    if (widget.progress.inRefreshing) {
      return const SizedBox.shrink();
    }

    return EmptyWidgetBackground(
      subtitle: l10n.emptyNoPosts,
    );
  }
}
