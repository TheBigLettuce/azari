// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/db/schemas/booru/favorite_booru.dart';
import 'package:gallery/src/db/schemas/grid_settings/booru.dart';
import 'package:gallery/src/db/schemas/grid_state/grid_booru_paging.dart';
import 'package:gallery/src/db/schemas/grid_state/grid_state.dart';
import 'package:gallery/src/db/schemas/grid_state/grid_state_booru.dart';
import 'package:gallery/src/db/schemas/settings/hidden_booru_post.dart';
import 'package:gallery/src/db/schemas/statistics/statistics_booru.dart';
import 'package:gallery/src/db/schemas/statistics/statistics_general.dart';
import 'package:gallery/src/db/schemas/tags/tags.dart';
import 'package:gallery/src/db/tags/booru_tagging.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/interfaces/booru/booru_api.dart';
import 'package:gallery/src/interfaces/booru/safe_mode.dart';
import 'package:gallery/src/interfaces/booru_tagging.dart';
import 'package:gallery/src/pages/more/tags/single_post.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_back_button_behaviour.dart';
import 'package:gallery/src/interfaces/logging/logging.dart';
import 'package:gallery/src/pages/booru/booru_restored_page.dart';
import 'package:gallery/src/pages/booru/booru_search_page.dart';
import 'package:gallery/src/pages/booru/open_menu_button.dart';
import 'package:gallery/src/pages/home.dart';
import 'package:gallery/src/pages/more/favorite_booru_page.dart';
import 'package:gallery/src/pages/more/settings/settings_widget.dart';
import 'package:gallery/src/pages/more/tags/tags_widget.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_layout_behaviour.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_refreshing_status.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/image_view_description.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/page_description.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/page_switcher.dart';
import 'package:gallery/src/widgets/image_view/image_view.dart';
import 'package:gallery/src/pages/booru/bookmark_button.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/search_bar/autocomplete/autocomplete_widget.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';
import 'package:isar/isar.dart';

import 'booru_grid_actions.dart';
import '../../net/downloader.dart';
import '../../db/tags/post_tags.dart';
import '../../db/initalize_db.dart';
import '../../db/schemas/downloader/download_file.dart';
import '../../db/schemas/booru/post.dart';
import '../../db/schemas/settings/settings.dart';
import '../../widgets/search_bar/search_launch_grid_data.dart';
import '../../widgets/notifiers/booru_api.dart';
import '../../widgets/search_bar/search_launch_grid.dart';

import '../../widgets/skeletons/grid.dart';

import 'package:gallery/src/widgets/grid_frame/grid_frame.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/grid_frame/configuration/grid_frame_settings_button.dart';

class _MainGridPagingState implements PagingEntry, PageSaver {
  _MainGridPagingState(int initalCellCount, this.booru)
      : mainGrid = DbsOpen.primaryGrid(booru),
        tagManager = TagManager.fromEnum(booru),
        client = BooruAPI.defaultClientForBooru(booru) {
    refreshingStatus = GridRefreshingStatus(initalCellCount, () => reachedEnd);
  }

  final Booru booru;
  final Isar mainGrid;

  bool reachedEnd = false;

  late final BooruAPI api = BooruAPI.fromEnum(booru, client, this);
  final TagManager tagManager;
  final Dio client;

  int? currentSkipped;

  late final GridRefreshingStatus<Post> refreshingStatus;

  GridState get _currentState {
    GridState? state = mainGrid.gridStates.getByNameSync(mainGrid.name);
    if (state == null) {
      state = GridState(
        tags: "",
        name: mainGrid.name,
        safeMode: SafeMode.normal,
        time: DateTime.now(),
        scrollOffset: 0,
      );

      mainGrid.writeTxnSync(() => mainGrid.gridStates.putSync(state!));
    }

    return state;
  }

  bool needToRefresh(Duration microseconds) =>
      _currentState.time.isBefore(DateTime.now().subtract(microseconds));

  String? restoreSecondaryGrid;

  @override
  double get offset {
    final offset = _currentState.scrollOffset;
    if (offset.isNaN) {
      return 0;
    }

    return offset;
  }

  void updateTime() {
    final prev = _currentState;

    mainGrid.writeTxnSync(
        () => mainGrid.gridStates.putSync(prev.copy(time: DateTime.now())));
  }

  @override
  int get page => mainGrid.gridBooruPagings.getSync(0)?.page ?? 0;

  @override
  void setOffset(double o) {
    final prev = _currentState;

    mainGrid.writeTxnSync(
      () => mainGrid.gridStates.putSync(
        prev.copy(scrollOffset: o),
      ),
    );
  }

  @override
  void setPage(int p) {
    mainGrid.writeTxnSync(
      () => mainGrid.gridBooruPagings.putSync(GridBooruPaging(p)),
    );
  }

  @override
  void save(int page) => setPage(page);

  @override
  int get current => page;

  @override
  void dispose() {
    client.close();
    refreshingStatus.dispose();
  }

  static PagingEntry prototype() {
    final settings = Settings.fromDb();
    final mainGrid = DbsOpen.primaryGrid(settings.selectedBooru);

    return _MainGridPagingState(
      mainGrid.posts.countSync(),
      settings.selectedBooru,
    );
  }
}

class BooruPage extends StatefulWidget {
  final PagingStateRegistry pagingRegistry;

  final void Function(bool) procPop;

  const BooruPage({
    super.key,
    required this.procPop,
    required this.pagingRegistry,
  });

  @override
  State<BooruPage> createState() => _BooruPageState();
}

class _BooruPageState extends State<BooruPage> {
  static const _log = LogTarget.booru;

  late final StreamSubscription<Settings?> settingsWatcher;
  late final StreamSubscription favoritesWatcher;
  late final StreamSubscription timeUpdater;
  late final StreamSubscription bookmarksWatcher;

  bool inForeground = true;

  late final AppLifecycleListener lifecycleListener;

  late final SearchLaunchGrid<Post> search;

  int? currentSkipped;

  late final _MainGridPagingState pagingState;

  late final state = GridSkeletonState<Post>();

  final menuController = MenuController();

  final _tagsWidgetKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    pagingState = widget.pagingRegistry.getOrRegister(
      state.settings.selectedBooru.string,
      _MainGridPagingState.prototype,
    ) as _MainGridPagingState;

    bookmarksWatcher = Dbs.g.main.gridStateBoorus.watchLazy().listen((_) {
      setState(() {});
    });

    lifecycleListener = AppLifecycleListener(onHide: () {
      inForeground = false;
    }, onShow: () {
      inForeground = true;

      if (pagingState.api.wouldBecomeStale &&
          state.settings.autoRefresh &&
          state.settings.autoRefreshMicroseconds != 0 &&
          pagingState.needToRefresh(
              state.settings.autoRefreshMicroseconds.microseconds)) {
        final gridState = state.gridKey.currentState;
        if (gridState != null) {
          gridState.controller.jumpTo(0);
          pagingState.refreshingStatus.refresh(gridState.widget.functionality);
        }

        pagingState.updateTime();
      }
    });

    timeUpdater = Stream.periodic(5.seconds).listen((event) {
      if (inForeground) {
        StatisticsGeneral.addTimeSpent(5.seconds.inMilliseconds);
      }
    });

    search = SearchLaunchGrid(SearchLaunchGridData(
      completeTag: pagingState.api.completeTag,
      mainFocus: state.mainFocus,
      header: _LatestAndExcluded(
        key: _tagsWidgetKey,
        api: pagingState.api,
        tagManager: pagingState.tagManager,
        onPressed: (tag, safeMode) {
          _onBooruTagPressed(context, pagingState.api.booru, tag.tag, safeMode);
        },
      ),
      searchText: "",
      swapSearchIconWithAddItems: false,
      addItems: (context) => [
        OpenMenuButton(
          context: context,
          controller: search.searchController,
          launchGrid: (context, tag, [safeMode]) {
            _onBooruTagPressed(context, pagingState.api.booru, tag, safeMode);
          },
          booru: pagingState.api.booru,
        )
      ],
      onSubmit: (context, tag) =>
          _onBooruTagPressed(context, pagingState.api.booru, tag, null),
    ));

    if (pagingState.api.wouldBecomeStale &&
        state.settings.autoRefresh &&
        state.settings.autoRefreshMicroseconds != 0 &&
        pagingState.needToRefresh(
            state.settings.autoRefreshMicroseconds.microseconds)) {
      pagingState.mainGrid
          .writeTxnSync(() => pagingState.mainGrid.posts.clearSync());
      pagingState.refreshingStatus.mutation.cellCount = 0;

      pagingState.updateTime();
    }

    settingsWatcher = Settings.watch((s) {
      state.settings = s!;

      setState(() {});
    });

    favoritesWatcher = Dbs.g.main.favoriteBoorus
        .watchLazy(fireImmediately: false)
        .listen((event) {
      state.imageViewKey.currentState?.setState(() {});
      setState(() {});
    });

    if (pagingState.restoreSecondaryGrid != null) {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        final e = Dbs.g.main.gridStateBoorus
            .getByNameSync(pagingState.restoreSecondaryGrid!)!;

        Dbs.g.main.writeTxnSync(() => Dbs.g.main.gridStateBoorus
            .putByNameSync(e.copy(time: DateTime.now())));

        Navigator.push(context, MaterialPageRoute(
          builder: (context) {
            return BooruRestoredPage(
              pagingRegistry: widget.pagingRegistry,
              onDispose: () {
                if (!isRestart) {
                  pagingState.restoreSecondaryGrid = null;
                  widget.pagingRegistry.remove(e.name);
                }
              },
              state: e,
              generateGlue: GlueProvider.generateOf(context),
            );
          },
        ));
      });
    }
  }

  @override
  void dispose() {
    settingsWatcher.cancel();
    favoritesWatcher.cancel();
    bookmarksWatcher.cancel();

    if (!isRestart) {
      pagingState.restoreSecondaryGrid = null;
    }

    search.dispose();

    state.dispose();

    timeUpdater.cancel();

    lifecycleListener.dispose();
    scrollController.dispose();

    super.dispose();
  }

  Future<int> _clearAndRefresh() async {
    final mainGrid = pagingState.mainGrid;
    final api = pagingState.api;

    try {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        state.gridKey.currentState?.selection.reset();
      });
      mainGrid.writeTxnSync(() => mainGrid.posts.clearSync());

      StatisticsGeneral.addRefreshes();

      pagingState.updateTime();

      final list = await api.page(0, "", pagingState.tagManager.excluded);
      pagingState.setOffset(0);
      currentSkipped = list.$2;
      mainGrid.writeTxnSync(() {
        mainGrid.posts.clearSync();
        return mainGrid.posts.putAllByIdBooruSync(
          list.$1
              .where(
                  (element) => !HiddenBooruPost.isHidden(element.id, api.booru))
              .toList(),
        );
      });

      pagingState.reachedEnd = false;
    } catch (e) {
      rethrow;
    }

    return mainGrid.posts.count();
  }

  Future<void> _download(int i) async {
    final p = pagingState.mainGrid.posts.getSync(i + 1);
    if (p == null) {
      return Future.value();
    }

    PostTags.g.addTagsPost(p.filename(), p.tags, true);

    return Downloader.g.add(
      DownloadFile.d(
          url: p.fileDownloadUrl(),
          site: pagingState.api.booru.url,
          name: p.filename(),
          thumbUrl: p.previewUrl),
      state.settings,
    );
  }

  Future<int> _addLast([int repeatCount = 0]) async {
    final mainGrid = pagingState.mainGrid;
    final api = pagingState.api;

    if (repeatCount >= 3) {
      return mainGrid.posts.countSync();
    }

    if (pagingState.reachedEnd) {
      return mainGrid.posts.countSync();
    }
    final p = mainGrid.posts.getSync(mainGrid.posts.countSync());
    if (p == null) {
      return mainGrid.posts.countSync();
    }

    try {
      final list = await api.fromPost(
        currentSkipped != null && currentSkipped! < p.id
            ? currentSkipped!
            : p.id,
        "",
        pagingState.tagManager.excluded,
      );

      if (list.$1.isEmpty && currentSkipped == null) {
        pagingState.reachedEnd = true;
      } else {
        currentSkipped = list.$2;
        final oldCount = mainGrid.posts.countSync();
        mainGrid.writeTxnSync(() => mainGrid.posts.putAllByIdBooruSync(
              list.$1
                  .where((element) =>
                      !HiddenBooruPost.isHidden(element.id, api.booru))
                  .toList(),
            ));

        pagingState.updateTime();

        if (mainGrid.posts.countSync() - oldCount < 3) {
          return await _addLast(repeatCount + 1);
        }
      }
    } catch (e, trace) {
      _log.logDefaultImportant(
          "_addLast on grid ${state.settings.selectedBooru.string}"
              .errorMessage(e),
          trace);
    }

    return mainGrid.posts.count();
  }

  final scrollController = ScrollController();

  void _onBooruTagPressed(
      BuildContext _, Booru booru, String tag, SafeMode? safeMode) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return BooruSearchPage(
        booru: booru,
        tags: tag,
        generateGlue: GlueProvider.generateOf(context),
        overrideSafeMode: safeMode,
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return FavoriteBooruStateHolder(
      build: (context, favoriteBooruState) {
        return BooruAPINotifier(
          api: pagingState.api,
          child: GridSkeleton(
            state,
            (context) => GridFrame<Post>(
              key: state.gridKey,
              layout:
                  const GridSettingsLayoutBehaviour(GridSettingsBooru.current),
              overrideController: scrollController,
              functionality: GridFunctionality(
                selectionGlue: GlueProvider.generateOf(context)(),
                loadNext: _addLast,
                backButton: const EmptyGridBackButton(inherit: true),
                watchLayoutSettings: GridSettingsBooru.watch,
                refresh: AsyncGridRefresh(_clearAndRefresh),
                refreshingStatus: pagingState.refreshingStatus,
                imageViewDescription: ImageViewDescription(
                  imageViewKey: state.imageViewKey,
                  statistics: const ImageViewStatistics(
                    swiped: StatisticsBooru.addSwiped,
                    viewed: StatisticsBooru.addViewed,
                  ),
                  addIconsImage: (post) => [
                    BooruGridActions.favorites(context, post),
                    BooruGridActions.download(context, pagingState.api.booru),
                    BooruGridActions.hide(context, () {
                      setState(() {});

                      final imgState = state.imageViewKey.currentState;
                      if (imgState == null) {
                        return;
                      }

                      imgState.loadCells(
                          imgState.currentPage, imgState.cellCount);
                      imgState.setState(() {});
                    }, post: post),
                  ],
                ),
                download: _download,
                search: OverrideGridSearchWidget(
                  SearchAndFocus(
                      search.searchWidget(context,
                          hint: pagingState.api.booru.name),
                      search.searchFocus),
                ),
                updateScrollPosition: pagingState.setOffset,
                onError: (error) {
                  return OutlinedButton.icon(
                    onPressed: () {
                      launchUrl(Uri.https(pagingState.api.booru.url),
                          mode: LaunchMode.externalApplication);
                    },
                    label: Text(AppLocalizations.of(context)!.openInBrowser),
                    icon: const Icon(Icons.public),
                  );
                },
                registerNotifiers: (child) => OnBooruTagPressed(
                  onPressed: _onBooruTagPressed,
                  child: BooruAPINotifier(
                    api: pagingState.api,
                    child: child,
                  ),
                ),
              ),
              description: GridDescription(
                risingAnimation: true,
                actions: [
                  BooruGridActions.download(context, pagingState.api.booru),
                  BooruGridActions.favorites(context, null,
                      showDeleteSnackbar: true),
                  BooruGridActions.hide(context, () => setState(() {})),
                ],
                pages: PageSwitcher(
                    [
                      PageIcon(
                        Icons.favorite_rounded,
                        count: FavoriteBooru.count,
                      ),
                      PageIcon(
                        Icons.bookmarks_rounded,
                        count: Dbs.g.main.gridStateBoorus.countSync(),
                      ),
                    ],
                    (i) => switch (i) {
                          0 => PageDescription(
                                search: SearchAndFocus(
                                  favoriteBooruState.search.searchWidget(
                                      favoriteBooruState.context,
                                      count: favoriteBooruState.loader.count()),
                                  favoriteBooruState.search.searchFocus,
                                ),
                                settingsButton:
                                    favoriteBooruState.gridSettingsButton(),
                                slivers: [
                                  GlueProvider(
                                    generate: GlueProvider.generateOf(context),
                                    child: FavoriteBooruPage(
                                      conroller: scrollController,
                                      state: favoriteBooruState,
                                    ),
                                  ),
                                ]),
                          1 => PageDescription(slivers: [
                              BookmarkPage(
                                scrollUp: () {
                                  state.gridKey.currentState?.controller
                                      .animateTo(
                                    0,
                                    duration: const Duration(milliseconds: 180),
                                    curve: Easing.standardAccelerate,
                                  );
                                },
                                pagingRegistry: widget.pagingRegistry,
                                generateGlue: GlueProvider.generateOf(context),
                                saveSelectedPage: (s) =>
                                    pagingState.restoreSecondaryGrid = s,
                              ),
                            ]),
                          int() => const PageDescription(slivers: []),
                        }),
                inlineMenuButtonItems: true,
                settingsButton: GridFrameSettingsButton(
                  selectSafeMode: (safeMode, _) =>
                      state.settings.copy(safeMode: safeMode).save(),
                  safeMode: state.settings.safeMode,
                  selectGridColumn: (columns, settings) =>
                      (settings as GridSettingsBooru)
                          .copy(columns: columns)
                          .save(),
                  selectGridLayout: (layoutType, settings) =>
                      (settings as GridSettingsBooru)
                          .copy(layoutType: layoutType)
                          .save(),
                  selectRatio: (ratio, settings) =>
                      (settings as GridSettingsBooru)
                          .copy(aspectRatio: ratio)
                          .save(),
                ),
                pageName: AppLocalizations.of(context)!.booruLabel,
                keybindsDescription:
                    AppLocalizations.of(context)!.booruGridPageName,
                gridSeed: state.gridSeed,
              ),
              mainFocus: state.mainFocus,
              getCell: (i) => pagingState.mainGrid.posts.getSync(i + 1)!,
              initalScrollPosition: pagingState.offset,
            ),
            canPop: false,
            secondarySelectionHide: () {
              favoriteBooruState.state.gridKey.currentState?.selection.reset();
            },
            onPop: (pop) {
              final gridState = state.gridKey.currentState;
              if (gridState != null && gridState.currentPage == 1) {
                if (favoriteBooruState
                    .search.searchTextController.text.isNotEmpty) {
                  favoriteBooruState.search.performSearch("");
                  return;
                }
              }

              final s = state.gridKey.currentState;
              if (s != null && s.currentPage != 0) {
                s.onSubpageSwitched(0, s.selection, s.controller);
                return;
              }

              widget.procPop(pop);
            },
          ),
        );
      },
    );
  }
}

class _LatestAndExcluded extends StatefulWidget {
  final TagManager tagManager;
  final BooruAPI api;
  final void Function(Tag, SafeMode?) onPressed;

  const _LatestAndExcluded({
    super.key,
    required this.onPressed,
    required this.tagManager,
    required this.api,
  });

  @override
  State<_LatestAndExcluded> createState() => __LatestAndExcludedState();
}

class __LatestAndExcludedState extends State<_LatestAndExcluded> {
  BooruTagging get excluded => widget.tagManager.excluded;
  BooruTagging get latest => widget.tagManager.latest;

  bool showExcluded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(padding: EdgeInsets.only(top: 8)),
        TagsWidget(
          tagging: latest,
          onPress: widget.onPressed,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: IconButton.filled(
              onPressed: () {
                Navigator.push(
                    context,
                    DialogRoute(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(
                              AppLocalizations.of(context)!.searchSinglePost),
                          content: SinglePost(tagManager: widget.tagManager),
                        );
                      },
                    ));
              },
              icon: const Icon(Icons.search),
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.only(bottom: 6)),
        showExcluded
            ? TagsWidget(
                tagging: excluded,
                onPress: null,
                redBackground: true,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8),
                  child: IconButton.filled(
                    onPressed: () {
                      Navigator.push(
                          context,
                          DialogRoute(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text(AppLocalizations.of(context)!
                                    .addToExcluded),
                                content: AutocompleteWidget(
                                  null,
                                  (s) {},
                                  swapSearchIcon: false,
                                  (s) {
                                    widget.tagManager.excluded
                                        .add(Tag.string(tag: s));

                                    Navigator.pop(context);
                                  },
                                  () {},
                                  widget.api.completeTag,
                                  null,
                                  submitOnPress: true,
                                  roundBorders: true,
                                  plainSearchBar: true,
                                  showSearch: true,
                                ),
                              );
                            },
                          ));
                    },
                    icon: const Icon(Icons.add),
                  ),
                ),
              )
            : TextButton(
                onPressed: () {
                  showExcluded = !showExcluded;

                  setState(() {});
                },
                child: Text(AppLocalizations.of(context)!.showExcludedTags),
              )
      ],
    );
  }
}

typedef OnBooruTagPressedFunc = void Function(
    BuildContext context, Booru booru, String tag, SafeMode? overrideSafeMode);

class OnBooruTagPressed extends InheritedWidget {
  final OnBooruTagPressedFunc onPressed;

  const OnBooruTagPressed({
    super.key,
    required this.onPressed,
    required super.child,
  });

  static void pressOf(
    BuildContext context,
    String tag,
    Booru booru, {
    SafeMode? overrideSafeMode,
  }) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<OnBooruTagPressed>();

    widget!.onPressed(context, booru, tag, overrideSafeMode);
  }

  @override
  bool updateShouldNotify(OnBooruTagPressed oldWidget) =>
      oldWidget.onPressed != onPressed;
}
