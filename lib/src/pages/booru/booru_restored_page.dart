// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/db/schemas/grid_settings/booru.dart';
import 'package:gallery/src/db/schemas/grid_state/grid_booru_paging.dart';
import 'package:gallery/src/db/schemas/grid_state/grid_state_booru.dart';
import 'package:gallery/src/db/tags/booru_tagging.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/interfaces/booru/booru_api.dart';
import 'package:gallery/src/interfaces/booru/safe_mode.dart';
import 'package:gallery/src/db/schemas/booru/favorite_booru.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/pages/booru/booru_page.dart';
import 'package:gallery/src/pages/booru/booru_search_page.dart';
import 'package:gallery/src/pages/home.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart';
import 'package:gallery/src/interfaces/logging/logging.dart';
import 'package:gallery/src/pages/more/tags/tags_widget.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_layout_behaviour.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/image_view_description.dart';
import 'package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/search_bar/search_launch_grid.dart';
import 'package:gallery/src/widgets/search_bar/search_launch_grid_data.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';
import 'package:isar/isar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../db/schemas/statistics/statistics_booru.dart';
import '../../db/schemas/statistics/statistics_general.dart';
import 'booru_grid_actions.dart';
import '../../net/downloader.dart';
import '../../db/tags/post_tags.dart';
import '../../db/initalize_db.dart';
import '../../db/schemas/downloader/download_file.dart';
import '../../db/schemas/booru/post.dart';
import '../../db/schemas/settings/settings.dart';
import '../../widgets/skeletons/grid.dart';
import '../../widgets/notifiers/booru_api.dart';
import '../../widgets/grid_frame/grid_frame.dart';
import '../../widgets/image_view/image_view.dart';
import '../../widgets/grid_frame/configuration/grid_frame_settings_button.dart';

class _IsarPageSaver implements PageSaver {
  const _IsarPageSaver(this.instance);

  final Isar instance;

  @override
  int get current => instance.gridBooruPagings.getSync(0)?.page ?? 0;

  @override
  void save(int page) {
    instance.writeTxnSync(
      () => instance.gridBooruPagings.putSync(GridBooruPaging(page)),
    );
  }
}

class BooruRestoredPage extends StatefulWidget {
  final GridStateBooru state;
  final PagingStateRegistry pagingRegistry;
  final SafeMode? overrideSafeMode;
  final void Function()? onDispose;
  final SelectionGlue<J> Function<J extends Cell>()? generateGlue;

  const BooruRestoredPage({
    super.key,
    required this.state,
    this.generateGlue,
    required this.pagingRegistry,
    this.overrideSafeMode,
    this.onDispose,
  });

  @override
  State<BooruRestoredPage> createState() => _BooruRestoredPageState();
}

class RestoredBooruPageState implements PagingEntry {
  RestoredBooruPageState(
    Booru booru,
    String name,
  )   : tagManager = TagManager.fromEnum(booru),
        instance = DbsOpen.secondaryGridName(name),
        client = BooruAPI.defaultClientForBooru(booru) {
    api = BooruAPI.fromEnum(booru, client, _IsarPageSaver(instance));
  }

  final Dio client;
  final TagManager tagManager;
  late final BooruAPI api;

  int? currentSkipped;

  bool reachedEnd = false;

  final Isar instance;

  late final state = GridSkeletonState<Post>(
    initalCellCount: instance.posts.countSync(),
    reachedEnd: () => reachedEnd,
  );

  @override
  void dispose() {
    client.close();

    state.dispose();

    instance.close(deleteFromDisk: false);
  }

  @override
  double get offset {
    final o =
        Dbs.g.main.gridStateBoorus.getByNameSync(instance.name)!.scrollOffset;
    if (o.isNaN) {
      return 0;
    }

    return o;
  }

  @override
  int get page => instance.gridBooruPagings.getSync(0)?.page ?? 0;

  @override
  void setOffset(double o) {
    final prev = Dbs.g.main.gridStateBoorus.getByNameSync(instance.name)!;

    Dbs.g.main.writeTxnSync(
      () => Dbs.g.main.gridStateBoorus.putByNameSync(prev.copy(
        scrollOffset: o,
      )),
    );
  }

  @override
  void setPage(int p) {
    instance.writeTxnSync(
      () => instance.gridBooruPagings.putSync(GridBooruPaging(page)),
    );
  }
}

class _BooruRestoredPageState extends State<BooruRestoredPage> {
  static const _log = LogTarget.booru;

  late final StreamSubscription<Settings?> settingsWatcher;
  late final StreamSubscription favoritesWatcher;

  late final SearchLaunchGrid search;

  late final RestoredBooruPageState pagingState;

  BooruAPI get api => pagingState.api;
  GridSkeletonState<Post> get state => pagingState.state;
  TagManager get tagManager => pagingState.tagManager;
  Isar get instance => pagingState.instance;

  @override
  void initState() {
    super.initState();

    pagingState = widget.pagingRegistry.getOrRegister(widget.state.name, () {
      return RestoredBooruPageState(widget.state.booru, widget.state.name);
    }) as RestoredBooruPageState;

    search = SearchLaunchGrid(SearchLaunchGridData(
      completeTag: api.completeTag,
      mainFocus: state.mainFocus,
      header: TagsWidget(
        tagging: tagManager.latest,
        onPress: (tag, safeMode) {},
      ),
      searchText: widget.state.tags,
      addItems: (_) => const [],
      disabled: true,
      onSubmit: (context, tag) {},
    ));

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
  }

  @override
  void dispose() {
    settingsWatcher.cancel();
    favoritesWatcher.cancel();

    widget.onDispose?.call();

    search.dispose();

    super.dispose();
  }

  SafeMode _safeMode() {
    final prev = Dbs.g.main.gridStateBoorus.getByNameSync(widget.state.name)!;

    return prev.safeMode;
  }

  Future<int> _clearAndRefresh() async {
    try {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        state.gridKey.currentState?.selection.reset();
      });
      StatisticsGeneral.addRefreshes();

      instance.writeTxnSync(() => instance.posts.clearSync());

      final list = await api.page(
        0,
        widget.state.tags,
        tagManager.excluded,
        overrideSafeMode: _safeMode(),
      );

      pagingState.currentSkipped = list.$2;
      await instance.writeTxn(() {
        instance.posts.clear();
        return instance.posts.putAllByFileUrl(list.$1);
      });

      pagingState.reachedEnd = false;
    } catch (e) {
      rethrow;
    }

    return instance.posts.count();
  }

  Future<void> _download(int i) async {
    final p = instance.posts.getSync(i + 1);
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
      state.settings,
    );
  }

  Future<int> _addLast([int repeatCount = 0]) async {
    if (pagingState.reachedEnd || repeatCount >= 3) {
      return instance.posts.countSync();
    }

    final p = instance.posts.getSync(instance.posts.countSync());
    if (p == null) {
      return instance.posts.countSync();
    }

    try {
      final list = await api.fromPost(
        pagingState.currentSkipped != null && pagingState.currentSkipped! < p.id
            ? pagingState.currentSkipped!
            : p.id,
        widget.state.tags,
        tagManager.excluded,
        overrideSafeMode: _safeMode(),
      );

      if (list.$1.isEmpty && pagingState.currentSkipped == null) {
        pagingState.reachedEnd = true;
      } else {
        pagingState.currentSkipped = list.$2;
        final oldCount = instance.posts.countSync();
        instance
            .writeTxnSync(() => instance.posts.putAllByFileUrlSync(list.$1));

        if (instance.posts.countSync() - oldCount < 3) {
          return await _addLast(repeatCount + 1);
        }
      }
    } catch (e, trace) {
      _log.logDefaultImportant(
          "_addLast on grid ${state.settings.selectedBooru.string}"
              .errorMessage(e),
          trace);
    }

    return instance.posts.count();
  }

  void _onTagPressed(
      BuildContext context, Booru booru, String tag, SafeMode? safeMode) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return BooruSearchPage(
          booru: booru,
          tags: tag,
          overrideSafeMode: safeMode,
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return WrapGridPage<Post>(
      provided: widget.generateGlue,
      scaffoldKey: state.scaffoldKey,
      child: Builder(
        builder: (context) {
          final glue = GlueProvider.of<Post>(context);

          return BooruAPINotifier(
            api: api,
            child: GridSkeleton(
              state,
              (context) => GridFrame<Post>(
                key: state.gridKey,
                refreshingStatus: state.refreshingStatus,
                layout: const GridSettingsLayoutBehaviour(
                    GridSettingsBooru.current),
                mainFocus: state.mainFocus,
                getCell: (i) => instance.posts.getSync(i + 1)!,
                initalScrollPosition: pagingState.offset,
                imageViewDescription: ImageViewDescription(
                  addIconsImage: (post) => [
                    BooruGridActions.favorites(context, post),
                    BooruGridActions.download(context, api.booru)
                  ],
                  imageViewKey: state.imageViewKey,
                  statistics: const ImageViewStatistics(
                    swiped: StatisticsBooru.addSwiped,
                    viewed: StatisticsBooru.addViewed,
                  ),
                ),
                functionality: GridFunctionality(
                  watchLayoutSettings: GridSettingsBooru.watch,
                  updateScrollPosition: pagingState.setOffset,
                  onError: (error) {
                    return OutlinedButton.icon(
                      onPressed: () {
                        launchUrl(Uri.https(api.booru.url),
                            mode: LaunchMode.externalApplication);
                      },
                      label: Text(AppLocalizations.of(context)!.openInBrowser),
                      icon: const Icon(Icons.public),
                    );
                  },
                  download: _download,
                  selectionGlue: glue,
                  search: OverrideGridSearchWidget(
                    SearchAndFocus(
                        search.searchWidget(context, hint: api.booru.name),
                        search.searchFocus),
                  ),
                  loadNext: _addLast,
                  refresh: AsyncGridRefresh(_clearAndRefresh),
                  registerNotifiers: (child) => OnBooruTagPressed(
                    onPressed: _onTagPressed,
                    child: BooruAPINotifier(api: api, child: child),
                  ),
                ),
                systemNavigationInsets: MediaQuery.of(context).viewPadding,
                description: GridDescription(
                  actions: [
                    BooruGridActions.download(context, api.booru),
                    BooruGridActions.favorites(context, null,
                        showDeleteSnackbar: true)
                  ],
                  settingsButton: GridFrameSettingsButton(
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
                      safeMode: _safeMode(),
                      selectSafeMode: (safeMode, _) {
                        if (safeMode == null) {
                          return;
                        }

                        final prev = Dbs.g.main.gridStateBoorus
                            .getByNameSync(widget.state.name)!;

                        Dbs.g.main.writeTxnSync(() => Dbs.g.main.gridStateBoorus
                            .putByNameSync(prev.copy(safeMode: safeMode)));

                        setState(() {});
                      }),
                  inlineMenuButtonItems: true,
                  keybindsDescription:
                      AppLocalizations.of(context)!.booruGridPageName,
                  gridSeed: state.gridSeed,
                ),
              ),
              canPop: true,
              overrideOnPop: (pop, hideAppBar) {
                if (hideAppBar()) {
                  setState(() {});
                  return;
                }
              },
            ),
          );
        },
      ),
    );
  }
}
