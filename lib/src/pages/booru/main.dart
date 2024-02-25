// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/db/schemas/booru/favorite_booru.dart';
import 'package:gallery/src/db/schemas/grid_state/grid_state_booru.dart';
import 'package:gallery/src/db/schemas/settings/hidden_booru_post.dart';
import 'package:gallery/src/db/schemas/booru/note_booru.dart';
import 'package:gallery/src/db/schemas/statistics/statistics_booru.dart';
import 'package:gallery/src/db/schemas/statistics/statistics_general.dart';
import 'package:gallery/src/db/schemas/tags/tags.dart';
import 'package:gallery/src/interfaces/booru/booru_api_state.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/grid/selection_glue.dart';
import 'package:gallery/src/interfaces/refreshing_status_interface.dart';
import 'package:gallery/src/interfaces/logging/logging.dart';
import 'package:gallery/src/pages/booru/add_to_bookmarks_button.dart';
import 'package:gallery/src/pages/booru/open_menu_button.dart';
import 'package:gallery/src/pages/booru/random.dart';
import 'package:gallery/src/pages/more/favorite_booru_page.dart';
import 'package:gallery/src/pages/more/settings/settings_widget.dart';
import 'package:gallery/src/pages/more/tags/tags_page.dart';
import 'package:gallery/src/widgets/grid/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid/configuration/grid_refresh_behaviour.dart';
import 'package:gallery/src/widgets/grid/configuration/grid_search_widget.dart';
import 'package:gallery/src/widgets/grid/configuration/image_view_description.dart';
import 'package:gallery/src/widgets/grid/configuration/page_description.dart';
import 'package:gallery/src/widgets/grid/configuration/page_switcher.dart';
import 'package:gallery/src/widgets/image_view/image_view.dart';
import 'package:gallery/src/pages/booru/bookmark_button.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:isar/isar.dart';

import '../../widgets/grid/actions/booru_grid.dart';
import '../../net/downloader.dart';
import '../../db/tags/post_tags.dart';
import '../../db/initalize_db.dart';
import '../../db/state_restoration.dart';
import '../../db/schemas/downloader/download_file.dart';
import '../../db/schemas/booru/post.dart';
import '../../db/schemas/settings/settings.dart';
import '../../widgets/search_bar/search_launch_grid_data.dart';
import '../../widgets/skeletons/grid_skeleton_state.dart';
import '../../widgets/notifiers/booru_api.dart';
import '../../widgets/notifiers/tag_manager.dart';
import '../../widgets/search_bar/search_launch_grid.dart';

import '../../widgets/skeletons/grid_skeleton.dart';

import 'package:gallery/src/widgets/grid/grid_frame.dart';
import 'package:url_launcher/url_launcher.dart';

import 'grid_button.dart';
import 'main_grid_settings_mixin.dart';
import 'secondary.dart';

class MainBooruGrid extends StatefulWidget {
  final Isar mainGrid;
  final void Function(bool) procPop;
  final RefreshingStatusInterface refreshingInterface;

  final EdgeInsets viewPadding;

  final SelectionGlue<J> Function<J extends Cell>() generateGlue;

  final void Function(String? e) saveSelectedPage;
  final String? restoreSelectedPage;

  const MainBooruGrid({
    super.key,
    required this.mainGrid,
    required this.refreshingInterface,
    required this.procPop,
    required this.viewPadding,
    required this.generateGlue,
    required this.restoreSelectedPage,
    required this.saveSelectedPage,
  });

  @override
  State<MainBooruGrid> createState() => _MainBooruGridState();
}

class _MainBooruGridState extends State<MainBooruGrid>
    with SearchLaunchGrid<Post>, MainGridSettingsMixin {
  static const _log = LogTarget.booru;

  late final StreamSubscription<Settings?> settingsWatcher;
  late final StreamSubscription favoritesWatcher;
  late final StreamSubscription timeUpdater;
  late final StreamSubscription bookmarksWatcher;

  bool inForeground = true;

  late final AppLifecycleListener lifecycleListener;

  late final BooruAPIState api;
  late final StateRestoration restore;
  late final TagManager<Restorable> tagManager;

  int? currentSkipped;

  bool reachedEnd = false;

  final state = GridSkeletonState<Post>();

  @override
  void initState() {
    super.initState();

    gridSettingsHook();

    bookmarksWatcher = Dbs.g.main.gridStateBoorus.watchLazy().listen((_) {
      setState(() {});
    });

    lifecycleListener = AppLifecycleListener(onHide: () {
      inForeground = false;
    }, onShow: () {
      inForeground = true;
    });

    timeUpdater = Stream.periodic(5.seconds).listen((event) {
      if (inForeground) {
        StatisticsGeneral.addTimeSpent(5.seconds.inMilliseconds);
      }
    });

    // main grid safe mode only from Settings
    restore = StateRestoration(widget.mainGrid,
        state.settings.selectedBooru.string, state.settings.safeMode);
    api = BooruAPIState.fromSettings(page: restore.copy.page);

    tagManager = TagManager.restorable(restore, (fire, f) {
      return widget.mainGrid.tags
          .watchLazy(fireImmediately: fire)
          .listen((event) {
        f();
      });
    });

    searchHook(SearchLaunchGridData(
      mainFocus: state.mainFocus,
      searchText: "",
      swapSearchIconWithAddItems: false,
      addItems: [
        OpenMenuButton(
            generateGlue: widget.generateGlue,
            context: context,
            controller: searchTextController,
            tagManager: tagManager,
            booru: api.booru)
      ],
      onSubmit: (context, tag) =>
          TagManagerNotifier.ofRestorable(context).onTagPressed(
        context,
        tag,
        BooruAPINotifier.of(context).booru,
        true,
        generateGlue: widget.generateGlue,
      ),
    ));

    if (api.wouldBecomeStale &&
        state.settings.autoRefresh &&
        state.settings.autoRefreshMicroseconds != 0 &&
        restore.copy.time.isBefore(DateTime.now()
            .subtract(state.settings.autoRefreshMicroseconds.microseconds))) {
      widget.mainGrid.writeTxnSync(() => widget.mainGrid.posts.clearSync());
      restore.updateTime();
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

    if (widget.restoreSelectedPage != null) {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        final e = Dbs.g.main.gridStateBoorus
            .getByNameSync(widget.restoreSelectedPage!)!;

        Dbs.g.main.writeTxnSync(() => Dbs.g.main.gridStateBoorus
            .putByNameSync(e.copy(false, time: DateTime.now())));

        widget.saveSelectedPage(widget.restoreSelectedPage);

        Navigator.push(context, MaterialPageRoute(
          builder: (context) {
            final tagManager = TagManager.fromEnum(e.booru);

            return RandomBooruGrid(
              api: BooruAPIState.fromEnum(e.booru, page: e.page),
              tagManager: tagManager,
              onDispose: () {
                if (!isRestart) {
                  widget.saveSelectedPage(null);
                }
              },
              tags: e.tags,
              state: e,
              generateGlue: widget.generateGlue,
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
      widget.saveSelectedPage(null);
    }

    disposeGridSettings();
    disposeSearch();

    state.dispose();

    timeUpdater.cancel();

    lifecycleListener.dispose();
    scrollController.dispose();

    super.dispose();
  }

  Future<int> _clearAndRefresh() async {
    try {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        state.gridKey.currentState?.selection.reset();
      });
      widget.mainGrid.writeTxnSync(() => widget.mainGrid.posts.clearSync());

      StatisticsGeneral.addRefreshes();

      restore.updateTime();

      final list = await api.page(0, "", tagManager.excluded);
      restore.updateScrollPosition(0, page: api.currentPage);
      currentSkipped = list.$2;
      widget.mainGrid.writeTxnSync(() {
        widget.mainGrid.posts.clearSync();
        return widget.mainGrid.posts.putAllByFileUrlSync(list.$1
            .where(
                (element) => !HiddenBooruPost.isHidden(element.id, api.booru))
            .toList());
      });

      reachedEnd = false;
    } catch (e) {
      rethrow;
    }

    return widget.mainGrid.posts.count();
  }

  Future<void> _download(int i) async {
    final p = widget.mainGrid.posts.getSync(i + 1);
    if (p == null) {
      return Future.value();
    }

    PostTags.g.addTagsPost(p.filename(), p.tags, true);

    return Downloader.g.add(
        DownloadFile.d(
            url: p.fileDownloadUrl(),
            site: api.booru.url,
            name: p.filename(),
            thumbUrl: p.previewUrl),
        state.settings);
  }

  Future<int> _addLast() async {
    if (reachedEnd) {
      return widget.mainGrid.posts.countSync();
    }
    final p = widget.mainGrid.posts.getSync(widget.mainGrid.posts.countSync());
    if (p == null) {
      return widget.mainGrid.posts.countSync();
    }

    try {
      final list = await api.fromPost(
          currentSkipped != null && currentSkipped! < p.id
              ? currentSkipped!
              : p.id,
          "",
          tagManager.excluded);
      if (list.$1.isEmpty && currentSkipped == null) {
        reachedEnd = true;
      } else {
        currentSkipped = list.$2;
        final oldCount = widget.mainGrid.posts.countSync();
        widget.mainGrid.writeTxnSync(() => widget.mainGrid.posts
            .putAllByFileUrlSync(list.$1
                .where((element) =>
                    !HiddenBooruPost.isHidden(element.id, api.booru))
                .toList()));
        restore.updateTime();
        restore.updatePage(api.currentPage);
        if (widget.mainGrid.posts.countSync() - oldCount < 3) {
          return await _addLast();
        }
      }
    } catch (e, trace) {
      _log.logDefaultImportant(
          "_addLast on grid ${state.settings.selectedBooru.string}"
              .errorMessage(e),
          trace);
    }

    return widget.mainGrid.posts.count();
  }

  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final glue = GlueProvider.of<Post>(context);

    return FavoriteBooruStateHolder(
      build: (context, favoriteBooruState) {
        return BooruAPINotifier(
          api: api,
          child: TagManagerNotifier.restorable(
              tagManager,
              GridSkeleton(
                state,
                (context) => GridFrame<Post>(
                  key: state.gridKey,
                  overrideController: scrollController,
                  imageViewDescription: ImageViewDescription(
                    pageViewScrollingOffset: restore.copy.scrollPositionTags,
                    initalCell: restore.copy.selectedPost,
                    imageViewKey: state.imageViewKey,
                    beforeImageViewRestore: () {
                      final last = restore.last();

                      if (last != null) {
                        final db = DbsOpen.secondaryGridName(last.copy.name);

                        WidgetsBinding.instance
                            .scheduleFrameCallback((timeStamp) {
                          Navigator.of(context, rootNavigator: false)
                              .push(MaterialPageRoute(
                            builder: (context) {
                              return SecondaryBooruGrid(
                                restore: last,
                                noRestoreOnBack: false,
                                api: BooruAPIState.fromEnum(api.booru,
                                    page: last.copy.page),
                                tagManager: tagManager,
                                instance: db,
                                generateGlue: widget.generateGlue,
                              );
                            },
                          ));
                        });
                      }
                    },
                    statistics: const ImageViewStatistics(
                      swiped: StatisticsBooru.addSwiped,
                      viewed: StatisticsBooru.addViewed,
                    ),
                    onExitImageView: () =>
                        restore.removeScrollTagsSelectedPost(),
                    addIconsImage: (post) => [
                      BooruGridActions.favorites(context, post),
                      BooruGridActions.download(context, api),
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
                  functionality: GridFunctionality(
                    selectionGlue: glue,
                    loadNext: _addLast,
                    refresh: AsyncGridRefresh(_clearAndRefresh),
                    download: _download,
                    search: OverrideGridSearchWidget(
                      SearchAndFocus(
                          searchWidget(context, hint: api.booru.name),
                          searchFocus, onPressed: () {
                        if (currentlyHighlightedTag != "") {
                          state.mainFocus.unfocus();
                          tagManager.onTagPressed(
                            context,
                            Tag.string(tag: currentlyHighlightedTag),
                            api.booru,
                            true,
                            generateGlue: widget.generateGlue,
                          );
                        }
                      }),
                    ),
                    refreshBehaviour: RetainedGridRefreshBehaviour(
                      widget.refreshingInterface,
                    ),
                    updateScrollPosition: (pos, {infoPos, selectedCell}) =>
                        restore.updateScrollPosition(pos,
                            infoPos: infoPos,
                            selectedCell: selectedCell,
                            page: api.currentPage),
                    onError: (error) {
                      return OutlinedButton(
                        onPressed: () {
                          launchUrl(Uri.https(api.booru.url),
                              mode: LaunchMode.externalApplication);
                        },
                        child:
                            Text(AppLocalizations.of(context)!.openInBrowser),
                      );
                    },
                    registerNotifiers: (child) => TagManagerNotifier.restorable(
                        tagManager, BooruAPINotifier(api: api, child: child)),
                  ),
                  systemNavigationInsets: widget.viewPadding,
                  description: GridDescription(
                    [
                      BooruGridActions.download(context, api),
                      BooruGridActions.favorites(context, null,
                          showDeleteSnackbar: true),
                      BooruGridActions.hide(context, () => setState(() {})),
                    ],
                    hideTitle: true,
                    pages: PageSwitcher(
                        [
                          _IconWithCount(
                            count: FavoriteBooru.count,
                            icon: const Icon(Icons.favorite_rounded),
                          ),
                          _IconWithCount(
                            count: Dbs.g.main.gridStateBoorus.countSync(),
                            icon: const Icon(Icons.bookmarks_rounded),
                          ),
                          const Icon(Icons.tag_rounded),
                        ],
                        (i) => switch (i) {
                              0 => PageDescription(
                                    search: SearchAndFocus(
                                      favoriteBooruState.searchWidget(
                                          favoriteBooruState.context,
                                          count: favoriteBooruState.loader
                                              .count()),
                                      favoriteBooruState.searchFocus,
                                    ),
                                    appIcons:
                                        favoriteBooruState.appBarButtons(),
                                    slivers: [
                                      GlueProvider<FavoriteBooru>(
                                        glue: widget.generateGlue(),
                                        generate: widget.generateGlue,
                                        child: FavoriteBooruPage(
                                          conroller: scrollController,
                                          state: favoriteBooruState,
                                        ),
                                      ),
                                    ]),
                              2 => PageDescription(slivers: [
                                  TagsPage(
                                    tagManager: TagManager.unrestorable(
                                        restore, tagManager.watch),
                                    booru: api,
                                    generateGlue: widget.generateGlue,
                                  )
                                ]),
                              1 => PageDescription(slivers: [
                                  BookmarkPage(
                                    generateGlue: widget.generateGlue,
                                    restoreSelectedPage:
                                        widget.restoreSelectedPage,
                                    saveSelectedPage: widget.saveSelectedPage,
                                  ),
                                ]),
                              int() => const PageDescription(slivers: []),
                            }),
                    inlineMenuButtonItems: true,
                    menuButtonItems: [
                      gridButton(state.settings, gridSettings),
                    ],
                    pageName: AppLocalizations.of(context)!.booruLabel,
                    keybindsDescription:
                        AppLocalizations.of(context)!.booruGridPageName,
                    layout: gridSettings.layoutType.layout(
                      gridSettings,
                      gridSeed: state.gridSeed,
                    ),
                  ),
                  hasReachedEnd: () => reachedEnd,
                  mainFocus: state.mainFocus,
                  getCell: (i) => widget.mainGrid.posts.getSync(i + 1)!,
                  initalScrollPosition: restore.copy.scrollPositionGrid,
                  initalCellCount: widget.mainGrid.posts.countSync(),
                ),
                overrideBooru: api.booru,
                canPop: false,
                overrideOnPop: (pop, hideAppBar) {
                  if (hideAppBar()) {
                    setState(() {});
                    return;
                  }

                  final s = state.gridKey.currentState;
                  if (s != null && s.currentPage != 0) {
                    s.currentPage = 0;
                    s.setState(() {});
                    return;
                  }

                  widget.procPop(pop);
                },
              )),
        );
      },
    );
  }
}

class _IconWithCount extends StatelessWidget {
  final Icon icon;
  final int count;

  const _IconWithCount({
    super.key,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        icon,
        const Padding(padding: EdgeInsets.only(left: 2)),
        Badge.count(
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          textColor: Theme.of(context).colorScheme.onSurfaceVariant,
          alignment: Alignment.bottomCenter,
          count: count,
        )
      ],
    );
  }
}
