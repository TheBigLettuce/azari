// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/post_tags.dart";
import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/booru/post.dart";
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
    required this.db,
    required this.safeMode,
    required this.booru,
    required this.onTagPressed,
    required this.listPadding,
    this.tags = "",
  });

  final String tags;

  final Booru booru;

  final EdgeInsets listPadding;

  final OnBooruTagPressedFunc onTagPressed;

  final SafeMode Function() safeMode;

  final DbConn db;

  void launchVideos(
    BuildContext gridContext,
    AppLocalizations l10n,
    ThemeData theme,
    // bool longPress,
  ) {
    if (tags.isNotEmpty) {
      db.tagManager.latest.add(tags);
    }

    final downloadManager = DownloadManager.of(gridContext);
    final postTags = PostTags.fromContext(gridContext);

    final client = BooruAPI.defaultClientForBooru(booru);
    final api = BooruAPI.fromEnum(booru, client);

    final value = <Post>[];
    int page = 0;
    bool canLoadMore = true;

    final stateController = DefaultStateController(
      getContent: (i) => value[i].content(),
      count: 0,
      wrapNotifiers: (child) => OnBooruTagPressed(
        onPressed: onTagPressed,
        child: child,
      ),
      statistics: StatisticsBooruService.asImageViewStatistics(),
      download: (i) => value[i].download(downloadManager, postTags),
      tags: (c) => DefaultPostPressable.imageViewTags(
        c,
        db.tagManager,
      ),
      watchTags: (c, f) => DefaultPostPressable.watchTags(
        c,
        f,
        db.tagManager,
      ),
      pageChange: (state) {
        final post = value[state.currentIndex];

        db.visitedPosts.addAll([
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
          final miscSettings = MiscSettingsService.db().current;
          next = await api.randomPosts(
            db.tagManager.excluded,
            safeMode(),
            true,
            // order: RandomPostsOrder.random,
            addTags: miscSettings.randomVideosAddTags,
            page: page + 1,
          );
        } else {
          next = await api.randomPosts(
            db.tagManager.excluded,
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
            );
          },
          newStatus: () async {
            page = 0;
            value.clear();
            canLoadMore = true;

            final List<Post> posts;

            if (tags.isEmpty) {
              final miscSettings = MiscSettingsService.db().current;

              posts = await api.randomPosts(
                db.tagManager.excluded,
                safeMode(),
                true,
                // order: RandomPostsOrder.random,
                addTags: miscSettings.randomVideosAddTags,
              );
            } else {
              posts = await api.randomPosts(
                db.tagManager.excluded,
                safeMode(),
                true,
                // order: RandomPostsOrder.random,
                addTags: tags,
              );
            }

            value.addAll(posts);

            final post = value.first;

            db.visitedPosts.addAll([
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
      db.tagManager.latest.add(tags);
    }

    final client = BooruAPI.defaultClientForBooru(booru);
    final api = BooruAPI.fromEnum(booru, client);

    final downloadManager = DownloadManager.of(gridContext);
    final postTags = PostTags.fromContext(gridContext);

    final value = <Post>[];
    int page = 0;
    bool canLoadMore = true;

    final stateController = DefaultStateController(
      getContent: (i) => value[i].content(),
      statistics: StatisticsBooruService.asImageViewStatistics(),
      download: (i) => value[i].download(downloadManager, postTags),
      tags: (c) => DefaultPostPressable.imageViewTags(
        c,
        db.tagManager,
      ),
      watchTags: (c, f) => DefaultPostPressable.watchTags(
        c,
        f,
        db.tagManager,
      ),
      preloadNextPictures: true,
      pageChange: (state) {
        final post = value[state.currentIndex];

        db.visitedPosts.addAll([
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
          db.tagManager.excluded,
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
              db.tagManager.excluded,
              safeMode(),
              false,
              addTags: tags,
            );

            value.addAll(ret);

            final post = value.first;

            db.visitedPosts.addAll([
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
                  db.tagManager.latest.add(tags);
                }

                final client = BooruAPI.defaultClientForBooru(booru);
                final api = BooruAPI.fromEnum(booru, client);

                Navigator.of(gridContext, rootNavigator: true)
                    .push<void>(
                      MaterialPageRoute(
                        builder: (context) => PopularPage(
                          api: api,
                          tags: tags,
                          db: db,
                          safeMode: safeMode,
                        ),
                      ),
                    )
                    .whenComplete(() => client.close(force: true));
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
  });

  final Booru booru;

  @override
  State<_VideosSettingsDialog> createState() => __VideosSettingsDialogState();
}

class __VideosSettingsDialogState extends State<_VideosSettingsDialog> {
  late final StreamSubscription<MiscSettingsData?> subscr;
  MiscSettingsData miscSettings = MiscSettingsService.db().current;

  late final TextEditingController textController;
  final focus = FocusNode();

  late final client = BooruAPI.defaultClientForBooru(widget.booru);
  late final BooruAPI api;

  @override
  void initState() {
    super.initState();

    api = BooruAPI.fromEnum(widget.booru, client);

    textController =
        TextEditingController(text: miscSettings.randomVideosAddTags);

    subscr = miscSettings.s.watch((settings) {
      setState(() {
        miscSettings = settings!;
      });
    });
  }

  @override
  void dispose() {
    subscr.cancel();
    focus.dispose();

    client.close(force: true);

    if (miscSettings.randomVideosAddTags != textController.text) {
      miscSettings.copy(randomVideosAddTags: textController.text).save();
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
          onPressed: () => miscSettings
              .copy(randomVideosOrder: RandomPostsOrder.random)
              .save(),
          icon: const Icon(Icons.shuffle_rounded),
          isSelected: miscSettings.randomVideosOrder == RandomPostsOrder.random,
        ),
        IconButton.filled(
          onPressed: () => miscSettings
              .copy(randomVideosOrder: RandomPostsOrder.rating)
              .save(),
          icon: const Icon(Icons.whatshot_rounded),
          isSelected: miscSettings.randomVideosOrder == RandomPostsOrder.rating,
        ),
        IconButton.filled(
          onPressed: () => miscSettings
              .copy(randomVideosOrder: RandomPostsOrder.latest)
              .save(),
          icon: const Icon(Icons.schedule_rounded),
          isSelected: miscSettings.randomVideosOrder == RandomPostsOrder.latest,
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
    required this.db,
    required this.tags,
    required this.safeMode,
  });

  final String tags;

  final BooruAPI api;

  final SafeMode Function() safeMode;

  final DbConn db;

  @override
  State<PopularPage> createState() => _PopularPageState();
}

class _PopularPageState extends State<PopularPage>
    with CommonGridData<Post, PopularPage> {
  GridBookmarkService get gridBookmarks => widget.db.gridBookmarks;
  HiddenBooruPostService get hiddenBooruPost => widget.db.hiddenBooruPost;
  FavoritePostSourceService get favoritePosts => widget.db.favoritePosts;

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
        widget.db.tagManager.excluded,
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
        widget.db.tagManager.excluded,
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

  void _download(int i) => source
      .forIdx(i)
      ?.download(DownloadManager.of(context), PostTags.fromContext(context));

  void _onBooruTagPressed(
    BuildContext _,
    Booru booru,
    String tag,
    SafeMode? safeMode,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) {
          return BooruRestoredPage(
            booru: booru,
            tags: tag,
            overrideSafeMode: safeMode,
            db: widget.db,
            wrapScaffold: true,
            saveSelectedPage: (_) {},
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    final gridActions = <GridAction<Post>>[
      actions.downloadPost(context, widget.api.booru, null),
      actions.favorites(
        context,
        favoritePosts,
        showDeleteSnackbar: true,
      ),
      actions.hide(context, hiddenBooruPost),
    ];

    return WrapGridPage(
      addScaffoldAndBar: true,
      child: GridPopScope(
        searchTextController: null,
        filter: null,
        child: GridConfiguration(
          watch: widget.db.gridSettings.booru.watch,
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
                  download: _download,
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
