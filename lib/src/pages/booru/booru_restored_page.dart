// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/post_tags.dart";
import "package:azari/src/db/services/posts_source.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/booru/post.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/pages/booru/actions.dart" as actions;
import "package:azari/src/pages/booru/booru_page.dart";
import "package:azari/src/pages/booru/tags/tag_suggestions.dart";
import "package:azari/src/pages/gallery/directories.dart";
import "package:azari/src/pages/gallery/files.dart";
import "package:azari/src/pages/home.dart";
import "package:azari/src/pages/more/settings/settings_widget.dart";
import "package:azari/src/widgets/glue_provider.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:azari/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/layouts/grid_layout.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_settings_button.dart";
import "package:azari/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:azari/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:azari/src/widgets/search/launching_search_widget.dart";
import "package:azari/src/widgets/skeletons/skeleton_state.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:url_launcher/url_launcher.dart";

class BooruRestoredPage extends StatefulWidget {
  const BooruRestoredPage({
    super.key,
    this.generateGlue,
    this.pagingRegistry,
    this.overrideSafeMode,
    required this.db,
    this.name,
    required this.booru,
    required this.tags,
    this.wrapScaffold = false,
    required this.saveSelectedPage,
    this.thenMoveTo,
    this.trySearchBookmarkByTags = false,
  });

  final String? name;
  final Booru booru;
  final String tags;
  final PagingStateRegistry? pagingRegistry;
  final SafeMode? overrideSafeMode;
  final void Function(String? e) saveSelectedPage;
  final SelectionGlue Function([Set<GluePreferences>])? generateGlue;
  final bool wrapScaffold;

  final PathVolume? thenMoveTo;
  final bool trySearchBookmarkByTags;

  final DbConn db;

  @override
  State<BooruRestoredPage> createState() => _BooruRestoredPageState();
}

class _BooruRestoredPageState extends State<BooruRestoredPage> {
  GridBookmarkService get gridBookmarks => widget.db.gridBookmarks;
  HiddenBooruPostService get hiddenBooruPost => widget.db.hiddenBooruPost;
  FavoritePostSourceService get favoritePosts => widget.db.favoritePosts;
  WatchableGridSettingsData get gridSettings => widget.db.gridSettings.booru;

  BooruAPI get api => pagingState.api;
  GridSkeletonState<Post> get state => pagingState.state;
  TagManager get tagManager => pagingState.tagManager;
  GridPostSource get source => pagingState.source;

  late final StreamSubscription<SettingsData?> settingsWatcher;
  late final StreamSubscription<void> favoritesWatcher;
  late final StreamSubscription<void> hiddenPostWatcher;

  late final SearchLaunchGridData search;
  final searchController = SearchController();

  late final RestoredBooruPageState pagingState;

  final _textKey = GlobalKey<__AppBarTextState>();

  RestoredBooruPageState makePageEntry(
    String name,
    bool addToBookmarks,
    SafeMode? safeMode,
    String tags,
  ) {
    final secondary = widget.db.secondaryGrid(
      widget.booru,
      name,
      safeMode,
      !addToBookmarks,
    );

    return RestoredBooruPageState(
      widget.booru,
      tags,
      widget.db.tagManager,
      secondary,
      hiddenBooruPost,
      gridBookmarks,
      addToBookmarks,
    );
  }

  @override
  void initState() {
    super.initState();

    final tagsTrimmed = widget.tags.trim();

    final bookmarkByName = widget.trySearchBookmarkByTags
        ? gridBookmarks.getFirstByTags(tagsTrimmed, widget.booru)
        : null;

    final String name;
    if (bookmarkByName == null) {
      name = widget.name ?? DateTime.now().microsecondsSinceEpoch.toString();
    } else {
      name = bookmarkByName.name;
    }

    widget.saveSelectedPage(name);

    pagingState = widget.pagingRegistry?.getOrRegister(
          name,
          () => makePageEntry(
            name,
            bookmarkByName != null || widget.name != null,
            bookmarkByName != null ? null : widget.overrideSafeMode,
            bookmarkByName?.tags ?? tagsTrimmed,
          ),
        ) ??
        makePageEntry(
          name,
          bookmarkByName != null || widget.name != null,
          bookmarkByName != null ? null : widget.overrideSafeMode,
          bookmarkByName?.tags ?? tagsTrimmed,
        );

    pagingState.tagManager.latest.add(bookmarkByName?.tags ?? tagsTrimmed);

    if (gridBookmarks.get(pagingState.secondaryGrid.name) == null) {
      gridBookmarks.add(
        GridBookmark(
          booru: widget.booru,
          name: pagingState.secondaryGrid.name,
          time: DateTime.now(),
          tags: bookmarkByName?.tags ?? tagsTrimmed,
        ),
      );
    }

    search = SearchLaunchGridData(
      completeTag: api.searchTag,
      header: Padding(
        padding: const EdgeInsets.only(top: 8, left: 8),
        child: TagSuggestions(
          tagging: tagManager.latest,
          onPress: (tag, safeMode) {
            pagingState.source.tags = tag;
            pagingState.source.clearRefresh();
            gridBookmarks.get(name)!.copy(tags: tag).save();
            _textKey.currentState?.setState(() {});
            pagingState.tagManager.latest.add(tag);

            Navigator.pop(context);
          },
        ),
      ),
      searchText: pagingState.source.tags,
      addItems: (_) => const [],
      onSubmit: (context, tag) {
        pagingState.source.tags = tag;
        pagingState.source.clearRefresh();
        gridBookmarks.get(name)!.copy(tags: tag).save();
        _textKey.currentState?.setState(() {});
        pagingState.tagManager.latest.add(tag);

        Navigator.pop(context);
      },
    );

    settingsWatcher = state.settings.s.watch((s) {
      state.settings = s!;

      setState(() {});
    });

    hiddenPostWatcher = widget.db.hiddenBooruPost.watch((_) {
      source.backingStorage.addAll([]);
    });

    favoritesWatcher = favoritePosts.backingStorage.watch((event) {
      source.backingStorage.addAll([]);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    settingsWatcher.cancel();
    favoritesWatcher.cancel();
    hiddenPostWatcher.cancel();

    if (widget.pagingRegistry == null) {
      widget.saveSelectedPage(null);
      if (!pagingState.addToBookmarks) {
        gridBookmarks.delete(pagingState.secondaryGrid.name);
      } else {
        gridBookmarks
            .get(pagingState.secondaryGrid.name)!
            .copy(
              thumbnails: source.lastFive
                  .map(
                    (e) => GridBookmarkThumbnail(
                      url: e.previewUrl,
                      rating: e.rating,
                    ),
                  )
                  .toList(),
            )
            .save();
      }
      pagingState.dispose(pagingState.addToBookmarks);
    } else {
      if (!isRestart) {
        widget.saveSelectedPage(null);
        if (!pagingState.addToBookmarks) {
          gridBookmarks.delete(pagingState.secondaryGrid.name);
        } else {
          gridBookmarks
              .get(pagingState.secondaryGrid.name)!
              .copy(
                thumbnails: source.lastFive
                    .map(
                      (e) => GridBookmarkThumbnail(
                        url: e.previewUrl,
                        rating: e.rating,
                      ),
                    )
                    .toList(),
              )
              .save();
        }
        (widget.pagingRegistry!.remove(pagingState.secondaryGrid.name)!
                as RestoredBooruPageState)
            .dispose(pagingState.addToBookmarks);
      }
    }

    super.dispose();
  }

  void _download(int i) => source.forIdx(i)?.download(
        DownloadManager.of(context),
        PostTags.fromContext(context),
        widget.thenMoveTo,
      );

  void _onTagPressed(
    BuildContext context,
    Booru booru,
    String tag,
    SafeMode? safeMode,
  ) {
    PauseVideoNotifier.maybePauseOf(context, true);

    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return BooruRestoredPage(
            booru: booru,
            tags: tag,
            wrapScaffold: true,
            overrideSafeMode: safeMode,
            db: widget.db,
            saveSelectedPage: (s) {},
          );
        },
      ),
    ).then((value) {
      if (context.mounted) {
        PauseVideoNotifier.maybePauseOf(context, false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GridConfiguration(
      watch: gridSettings.watch,
      child: WrapGridPage(
        addScaffold: widget.wrapScaffold,
        provided: widget.generateGlue,
        child: Builder(
          builder: (context) {
            return BooruAPINotifier(
              api: api,
              child: GridPopScope(
                searchTextController: null,
                filter: null,
                child: GridFrame<Post>(
                  key: state.gridKey,
                  slivers: [
                    CurrentGridSettingsLayout<Post>(
                      source: source.backingStorage,
                      progress: source.progress,
                      gridSeed: state.gridSeed,
                      unselectOnUpdate: false,
                      buildEmpty: (e) => EmptyWidgetWithButton(
                        error: e,
                        buttonText: l10n.openInBrowser,
                        onPressed: () {
                          launchUrl(
                            Uri.https(api.booru.url),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                    ),
                    GridConfigPlaceholders(
                      progress: source.progress,
                      randomNumber: state.gridSeed,
                    ),
                    GridFooter<void>(
                      storage: source.backingStorage,
                      name: source.tags,
                    ),
                  ],
                  initalScrollPosition: pagingState.offset,
                  functionality: GridFunctionality(
                    updatesAvailable: source.updatesAvailable,
                    settingsButton: GridSettingsButton.fromWatchable(
                      gridSettings,
                      SafeModeButton(secondaryGrid: pagingState.secondaryGrid),
                    ),
                    updateScrollPosition: pagingState.setOffset,
                    download: _download,
                    selectionGlue: GlueProvider.generateOf(context)(),
                    source: source,
                    search: RawSearchWidget(
                      (settingsButton, bottomWidget) => SliverAppBar(
                        leading: const BackButton(),
                        floating: true,
                        pinned: true,
                        snap: true,
                        stretch: true,
                        bottom: bottomWidget ??
                            const PreferredSize(
                              preferredSize: Size.zero,
                              child: SizedBox.shrink(),
                            ),
                        title: _AppBarText(key: _textKey, source: source),
                        actions: [
                          IconButton(
                            icon: pagingState.addToBookmarks
                                ? const Icon(Icons.bookmark_remove_rounded)
                                : const Icon(Icons.bookmark_add_rounded),
                            onPressed: () {
                              pagingState.addToBookmarks =
                                  !pagingState.addToBookmarks;

                              setState(() {});
                            },
                          ),
                          LaunchingSearchWidget(
                            state: search,
                            searchController: searchController,
                            hint: pagingState.api.booru.name,
                          ),
                          if (settingsButton != null) settingsButton,
                        ],
                      ),
                    ),
                    registerNotifiers: (child) => OnBooruTagPressed(
                      onPressed: _onTagPressed,
                      child: BooruAPINotifier(api: api, child: child),
                    ),
                  ),
                  description: GridDescription(
                    actions: [
                      actions.download(context, api.booru, widget.thenMoveTo),
                      actions.favorites(
                        context,
                        favoritePosts,
                        showDeleteSnackbar: true,
                      ),
                      actions.hide(context, hiddenBooruPost),
                    ],
                    showLoadingIndicator: false,
                    animationsOnSourceWatch: false,
                    keybindsDescription: l10n.booruGridPageName,
                    gridSeed: state.gridSeed,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class RestoredBooruPageState implements PagingEntry {
  RestoredBooruPageState(
    Booru booru,
    String tags,
    this.tagManager,
    this.secondaryGrid,
    HiddenBooruPostService hiddenBooruPosts,
    this.gridBookmarks,
    this.addToBookmarks,
  ) : client = BooruAPI.defaultClientForBooru(booru) {
    api = BooruAPI.fromEnum(booru, client, this);

    source = secondaryGrid.makeSource(
      api,
      tagManager.excluded,
      this,
      tags,
      hiddenBooruPosts,
    );
  }

  bool addToBookmarks;

  @override
  void updateTime() =>
      gridBookmarks.get(secondaryGrid.name)!.copy(time: DateTime.now()).save();

  final Dio client;
  final TagManager tagManager;
  late final BooruAPI api;

  final SecondaryGridService secondaryGrid;
  final GridBookmarkService gridBookmarks;
  late final GridPostSource source;

  int? currentSkipped;

  @override
  bool reachedEnd = false;

  late final state = GridSkeletonState<Post>();

  @override
  Future<void> dispose([bool closeGrid = true]) {
    client.close();
    source.destroy();
    state.dispose();

    if (closeGrid) {
      return secondaryGrid.close();
    } else {
      return secondaryGrid.destroy();
    }
  }

  SafeMode get safeMode => secondaryGrid.currentState.safeMode;
  set safeMode(SafeMode s) =>
      secondaryGrid.currentState.copy(safeMode: s).saveSecondary(secondaryGrid);

  @override
  double get offset => secondaryGrid.currentState.offset;

  @override
  int get page => secondaryGrid.page;

  @override
  set page(int p) => secondaryGrid.page = p;

  @override
  void setOffset(double o) =>
      secondaryGrid.currentState.copy(offset: o).saveSecondary(secondaryGrid);
}

class _AppBarText extends StatefulWidget {
  const _AppBarText({required super.key, required this.source});

  final GridPostSource source;

  @override
  State<_AppBarText> createState() => __AppBarTextState();
}

class __AppBarTextState extends State<_AppBarText> {
  @override
  Widget build(BuildContext context) {
    return Text(widget.source.tags);
  }
}
