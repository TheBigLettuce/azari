// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/post_tags.dart";
import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/booru/post.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/pages/anime/info_base/always_loading_anime_mixin.dart";
import "package:azari/src/pages/booru/actions.dart" as actions;
import "package:azari/src/pages/booru/booru_page.dart";
import "package:azari/src/pages/booru/booru_restored_page.dart";
import "package:azari/src/pages/gallery/directories.dart";
import "package:azari/src/pages/gallery/files.dart";
import "package:azari/src/widgets/glue_provider.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_settings_button.dart";
import "package:azari/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:azari/src/widgets/image_view/image_view.dart";
import "package:azari/src/widgets/skeletons/skeleton_state.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

class PopularRandomButtons extends StatelessWidget {
  const PopularRandomButtons({
    super.key,
    required this.db,
    required this.safeMode,
    this.tags = "",
    required this.booru,
    required this.onTagPressed,
  });

  final Booru booru;
  final String tags;

  final OnBooruTagPressedFunc onTagPressed;
  final SafeMode Function() safeMode;

  final DbConn db;

  void launchVideos(
    BuildContext gridContext,
    AppLocalizations l10n,
    ThemeData theme,
    bool longPress,
  ) {
    Navigator.pop(gridContext);

    if (tags.isNotEmpty) {
      db.tagManager.latest.add(tags);
    }

    final client = BooruAPI.defaultClientForBooru(booru);
    final api = BooruAPI.fromEnum(booru, client, PageSaver.noPersist());

    final value = <Post>[];
    int page = 0;
    bool canLoadMore = true;

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

                final downloadManager = DownloadManager.of(context);
                final postTags = PostTags.fromContext(context);

                {
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
                }

                final i = ImageView(
                  gridContext: gridContext,
                  cellCount: value.length,
                  scrollUntill: (_) {},
                  startingCell: 0,
                  getCell: (i) => value[i].content(),
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
                        order: miscSettings.randomVideosOrder,
                        addTags: miscSettings.randomVideosAddTags,
                        page: page + 1,
                      );
                    } else {
                      next = await api.randomPosts(
                        db.tagManager.excluded,
                        safeMode(),
                        true,
                        order: longPress
                            ? RandomPostsOrder.random
                            : RandomPostsOrder.latest,
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
                    final post = value[state.currentPage];

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
                );

                return OnBooruTagPressed(
                  onPressed: onTagPressed,
                  child: i,
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
                    order: miscSettings.randomVideosOrder,
                    addTags: miscSettings.randomVideosAddTags,
                  );
                } else {
                  posts = await api.randomPosts(
                    db.tagManager.excluded,
                    safeMode(),
                    true,
                    order: longPress
                        ? RandomPostsOrder.random
                        : RandomPostsOrder.latest,
                    addTags: tags,
                  );
                }

                value.addAll(posts);

                return value;
              },
            ),
          ),
        )
        .whenComplete(() => client.close(force: true));
  }

  void launchRandom(
    BuildContext gridContext,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    Navigator.pop(gridContext);

    if (tags.isNotEmpty) {
      db.tagManager.latest.add(tags);
    }

    final client = BooruAPI.defaultClientForBooru(booru);
    final api = BooruAPI.fromEnum(booru, client, PageSaver.noPersist());

    final value = <Post>[];
    int page = 0;
    bool canLoadMore = true;

    Navigator.of(gridContext, rootNavigator: true)
        .push<void>(
          MaterialPageRoute(
            builder: (context) => WrapFutureRestartable(
              builder: (context, value) {
                final downloadManager = DownloadManager.of(context);
                final postTags = PostTags.fromContext(context);

                {
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
                }

                final i = ImageView(
                  cellCount: value.length,
                  scrollUntill: (_) {},
                  startingCell: 0,
                  getCell: (i) => value[i].content(),
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
                    final post = value[state.currentPage];

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
                );

                return OnBooruTagPressed(
                  onPressed: onTagPressed,
                  child: i,
                );
              },
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

                return value;
              },
            ),
          ),
        )
        .whenComplete(() => client.close(force: true));
  }

  @override
  Widget build(BuildContext gridContext) {
    final l10n = AppLocalizations.of(gridContext)!;
    final theme = Theme.of(gridContext);

    return SliverPadding(
      padding: const EdgeInsets.only(
        top: 4,
        bottom: 4,
      ),
      sliver: SliverToBoxAdapter(
        child: Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(gridContext);

                    if (tags.isNotEmpty) {
                      db.tagManager.latest.add(tags);
                    }

                    final client = BooruAPI.defaultClientForBooru(booru);
                    final api =
                        BooruAPI.fromEnum(booru, client, PageSaver.noPersist());

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
                    "${l10n.popularPosts}${tags.isEmpty ? '' : " '$tags'"}",
                  ),
                  icon: const Icon(Icons.whatshot_outlined),
                ),
                TextButton.icon(
                  onPressed: () => launchRandom(gridContext, l10n, theme),
                  label: Text(
                    "${l10n.randomPosts}${tags.isEmpty ? '' : " '$tags'"}",
                  ),
                  icon: const Icon(Icons.shuffle_outlined),
                ),
                TextButton.icon(
                  onPressed: () =>
                      launchVideos(gridContext, l10n, theme, false),
                  onLongPress: tags.isNotEmpty
                      ? () => launchVideos(gridContext, l10n, theme, true)
                      : () {
                          Navigator.of(gridContext, rootNavigator: true)
                              .push<void>(
                            DialogRoute(
                              context: gridContext,
                              builder: (context) => _VideosSettingsDialog(
                                booru: booru,
                              ),
                            ),
                          );
                        },
                  label: Text(
                    "${l10n.videosLabel}${tags.isEmpty ? '' : " '$tags'"}",
                  ),
                  icon: const Icon(Icons.video_collection_outlined),
                ),
              ],
            ),
          ),
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

    api = BooruAPI.fromEnum(widget.booru, client, PageSaver.noPersist());

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
    final l10n = AppLocalizations.of(context)!;

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
            onChange: null,
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
            // onSubmitted: onSubmit,
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

  final BooruAPI api;
  final String tags;

  final SafeMode Function() safeMode;

  final DbConn db;

  @override
  State<PopularPage> createState() => _PopularPageState();
}

class _PopularPageState extends State<PopularPage> {
  GridBookmarkService get gridBookmarks => widget.db.gridBookmarks;
  HiddenBooruPostService get hiddenBooruPost => widget.db.hiddenBooruPost;
  FavoritePostSourceService get favoritePosts => widget.db.favoritePosts;
  WatchableGridSettingsData get gridSettings => widget.db.gridSettings.booru;

  int page = 0;

  late final GenericListSource<Post> source = GenericListSource<Post>(
    () async {
      page = 0;

      final ret = await widget.api.page(
        page,
        widget.tags,
        widget.db.tagManager.excluded,
        widget.safeMode(),
        order: BooruPostsOrder.score,
      );

      return ret.$1;
    },
    next: () async {
      final ret = await widget.api.page(
        page + 1,
        widget.tags,
        widget.db.tagManager.excluded,
        widget.safeMode(),
        order: BooruPostsOrder.score,
      );

      page += 1;

      return ret.$1;
    },
  );

  late final state = GridSkeletonState<Post>();

  @override
  void dispose() {
    source.destroy();
    state.dispose();

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
            // pagingRegistry: widget.pagingRegistry,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return WrapGridPage(
      addScaffold: true,
      child: Builder(
        builder: (context) => GridPopScope(
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
                  key: state.gridKey,
                  slivers: [
                    CurrentGridSettingsLayout<Post>(
                      source: source.backingStorage,
                      progress: source.progress,
                      gridSeed: state.gridSeed,
                      unselectOnUpdate: false,
                      // buildEmpty: (e) => EmptyWidgetWithButton(
                      //   error: e,
                      //   buttonText: l10n.openInBrowser,
                      //   onPressed: () {
                      //     launchUrl(
                      //       Uri.https(widget.api.booru.url),
                      //       mode: LaunchMode.externalApplication,
                      //     );
                      //   },
                      // ),
                    ),
                    GridConfigPlaceholders(
                      progress: source.progress,
                      randomNumber: state.gridSeed,
                    ),
                    GridFooter<void>(storage: source.backingStorage),
                  ],
                  functionality: GridFunctionality(
                    settingsButton: GridSettingsButton.fromWatchable(
                      gridSettings,
                    ),
                    selectionGlue: GlueProvider.generateOf(context)(),
                    source: source,
                    search: RawSearchWidget(
                      (settingsButton, bottomWidget) => SliverAppBar(
                        floating: true,
                        pinned: true,
                        snap: true,
                        stretch: true,
                        bottom: bottomWidget ??
                            const PreferredSize(
                              preferredSize: Size.zero,
                              child: SizedBox.shrink(),
                            ),
                        // centerTitle: true,
                        title: Text(
                          widget.tags.isNotEmpty
                              ? "${l10n.popularPosts} '${widget.tags}'"
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
                    showLoadingIndicator: false,
                    actions: [
                      actions.download(context, widget.api.booru, null),
                      actions.favorites(
                        context,
                        favoritePosts,
                        showDeleteSnackbar: true,
                      ),
                      actions.hide(context, hiddenBooruPost),
                    ],
                    animationsOnSourceWatch: false,
                    pageName: l10n.booruLabel,
                    keybindsDescription: l10n.booruGridPageName,
                    gridSeed: state.gridSeed,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
