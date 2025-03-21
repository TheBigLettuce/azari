// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/services/posts_source.dart";
import "package:azari/src/services/resource_source/basic.dart";
import "package:azari/src/services/resource_source/resource_source.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/booru/actions.dart" as actions;
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/pages/other/settings/settings_page.dart";
import "package:azari/src/ui/material/pages/search/booru/popular_random_buttons.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_aspect_ratio.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_column.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:dio/dio.dart";
import "package:flutter/widgets.dart";
import "package:flutter_animate/flutter_animate.dart";

mixin BooruPageMixin<W extends StatefulWidget> on State<W> {
  GridBookmarkService? get gridBookmarks;
  HiddenBooruPostsService? get hiddenBooruPosts;
  FavoritePostSourceService? get favoritePosts;
  TagManagerService? get tagManager;
  DownloadManager? get downloadManager;
  LocalTagsService? get localTags;
  GridDbService get gridDbs;

  SettingsData get settings;
  SettingsService get settingsService;

  PagingStateRegistry get pagingRegistry;
  SelectionController get selectionController;

  BooruChipsState get currentSubpage => pagingState.currentSubpage;

  final gridSettings = CancellableWatchableGridSettingsData.noPersist(
    hideName: true,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.two,
    layoutType: GridLayoutType.gridQuilted,
  );

  GridPostSource get source => pagingState.source;

  late final StreamSubscription<void>? favoritesWatcher;
  late final StreamSubscription<void>? hiddenPostWatcher;
  late final StreamSubscription<void> timeUpdater;
  late final StreamSubscription<BooruChipsState> chipsEvents;

  final menuController = MenuController();

  late final AppLifecycleListener lifecycleListener;

  late final _MainGridPagingState pagingState;

  bool inForeground = true;
  int? currentSkipped;

  void openSecondaryBooruPage(GridBookmark bookmark);

  @override
  void initState() {
    super.initState();

    pagingState = pagingRegistry.getOrRegister(
      settings.selectedBooru.string,
      () {
        final mainGrid = gridDbs.openMain(settings.selectedBooru);

        return _MainGridPagingState.prototype(
          settings.selectedBooru,
          mainGrid,
          gridBookmarks: gridBookmarks,
          tagManager: tagManager,
          hiddenBooruPosts: hiddenBooruPosts,
          settingsService: settingsService,
          selectionController: selectionController,
          actions: [
            if (downloadManager != null && localTags != null)
              actions.downloadPost(
                context,
                settings.selectedBooru,
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
            if (hiddenBooruPosts != null)
              actions.hide(context, hiddenBooruPosts!),
          ],
        );
      },
    );

    chipsEvents = pagingState._subpageEvents.stream.listen((e) {
      setState(() {});
    });

    lifecycleListener = AppLifecycleListener(
      onHide: () {
        inForeground = false;
      },
      onShow: () {
        inForeground = true;

        if (pagingState.api.wouldBecomeStale &&
            pagingState.needToRefresh(const Duration(hours: 1))) {
          source.clearRefresh();

          pagingState.updateTime();
        }
      },
    );

    timeUpdater = Stream<void>.periodic(5.seconds).listen((event) {
      if (inForeground) {
        StatisticsGeneralService.addTimeSpent(5.seconds.inMilliseconds);
      }
    });

    if (pagingState.api.wouldBecomeStale &&
        pagingState.needToRefresh(const Duration(hours: 1))) {
      source.clear();

      pagingState.updateTime();
    }

    favoritesWatcher = favoritePosts?.cache.countEvents.listen((event) {
      source.backingStorage.addAll([]);
    });

    hiddenPostWatcher = hiddenBooruPosts?.watch((_) {
      source.backingStorage.addAll(const []);
      pagingState.randomStatus.source.backingStorage.addAll(const []);
      pagingState.videosStatus.source.backingStorage.addAll(const []);
      pagingState.popularStatus.source.backingStorage.addAll(const []);
    });

    if (gridBookmarks != null && pagingState.restoreSecondaryGrid != null) {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        final e = gridBookmarks!.get(pagingState.restoreSecondaryGrid!)!;

        openSecondaryBooruPage(e);
      });
    }
  }

  @override
  void dispose() {
    chipsEvents.cancel();
    gridSettings.cancel();
    favoritesWatcher?.cancel();
    hiddenPostWatcher?.cancel();

    if (!isRestart) {
      pagingState.restoreSecondaryGrid = null;
    }

    timeUpdater.cancel();

    lifecycleListener.dispose();

    super.dispose();
  }

  // ignore: use_setters_to_change_properties
  void setSecondaryName(String? name) {
    pagingState.restoreSecondaryGrid = name;
  }
}

class _MainGridPagingState implements PagingEntry {
  _MainGridPagingState(
    HiddenBooruPostsService? hiddenBooruPosts,
    this.booru,
    this.tagManager,
    this.mainGrid,
    this.gridBookmarks,
    this.settingsService,
    this.actions,
    this.selectionController,
  ) : client = BooruAPI.defaultClientForBooru(booru) {
    source = mainGrid.makeSource(
      api,
      this,
      hiddenBooruPosts: hiddenBooruPosts,
      excluded: tagManager?.excluded,
    );

    status = SourceShellElementState(
      onEmpty: const OnEmptyInterface.empty(),
      source: source,
      selectionController: selectionController,
      actions: actions,
    );

    stackInjector = BooruStackInjector(
      _subpageEvents,
      BooruChipsState.latest,
      status,
      videosStatus,
      popularStatus,
      randomStatus,
      selectionController,
    );
  }

  factory _MainGridPagingState.prototype(
    Booru booru,
    MainGridHandle mainGrid, {
    required TagManagerService? tagManager,
    required HiddenBooruPostsService? hiddenBooruPosts,
    required GridBookmarkService? gridBookmarks,
    required SettingsService settingsService,
    required SelectionController selectionController,
    required List<SelectionBarAction> actions,
  }) =>
      _MainGridPagingState(
        hiddenBooruPosts,
        booru,
        tagManager,
        mainGrid,
        gridBookmarks,
        settingsService,
        actions,
        selectionController,
      );

  final Booru booru;

  @override
  bool reachedEnd = false;

  late final BooruAPI api = BooruAPI.fromEnum(booru, client);
  final TagManagerService? tagManager;
  final Dio client;
  late final GridPostSource source;
  final MainGridHandle mainGrid;
  final GridBookmarkService? gridBookmarks;
  final SelectionController selectionController;
  final List<SelectionBarAction> actions;
  late final BooruStackInjector stackInjector;

  final SettingsService settingsService;

  final popularPageSaver = PageSaver.noPersist();
  final videosPageSaver = PageSaver.noPersist();
  final randomPageSaver = PageSaver.noPersist();

  final _subpageEvents = StreamController<BooruChipsState>.broadcast();

  BooruChipsState get currentSubpage => stackInjector.chipsState;
  set currentSubpage(BooruChipsState s) {
    stackInjector.updateChipsState(s);
  }

  late final SourceShellElementState<Post> status;

  late final popularStatus = SourceShellElementState<Post>(
    onEmpty: const OnEmptyInterface.empty(),
    source: GenericListSource<Post>(
      () async {
        popularPageSaver.page = 0;

        final ret = await api.page(
          popularPageSaver.page,
          "",
          tagManager?.excluded,
          settingsService.current.safeMode,
          order: BooruPostsOrder.score,
          pageSaver: popularPageSaver,
        );

        return ret.$1;
      },
      next: () async {
        final ret = await api.page(
          popularPageSaver.page + 1,
          "",
          tagManager?.excluded,
          settingsService.current.safeMode,
          order: BooruPostsOrder.score,
          pageSaver: popularPageSaver,
        );

        return ret.$1;
      },
    ),
    selectionController: selectionController,
    actions: actions,
  );

  late final videosStatus = SourceShellElementState<Post>(
    onEmpty: const OnEmptyInterface.empty(),
    source: GenericListSource<Post>(
      () async {
        videosPageSaver.page = 0;

        final ret = await api.randomPosts(
          tagManager?.excluded,
          settingsService.current.safeMode,
          true,
          // order: RandomPostsOrder.random,
          addTags: settingsService.current.randomVideosAddTags,
          page: videosPageSaver.page,
        );

        return ret;
      },
      next: () async {
        final ret = await api.randomPosts(
          tagManager?.excluded,
          settingsService.current.safeMode,
          true,
          // order: RandomPostsOrder.random,
          addTags: settingsService.current.randomVideosAddTags,
          page: videosPageSaver.page + 1,
        );

        videosPageSaver.page += 1;

        return ret;
      },
    ),
    selectionController: selectionController,
    actions: actions,
  );

  late final randomStatus = SourceShellElementState<Post>(
    onEmpty: const OnEmptyInterface.empty(),
    source: GenericListSource<Post>(
      () async {
        randomPageSaver.page = 0;

        final ret = await api.randomPosts(
          tagManager?.excluded,
          settingsService.current.safeMode,
          false,
          page: randomPageSaver.page,
        );

        return ret;
      },
      next: () async {
        final ret = await api.randomPosts(
          tagManager?.excluded,
          settingsService.current.safeMode,
          false,
          page: randomPageSaver.page + 1,
        );

        randomPageSaver.page += 1;

        return ret;
      },
    ),
    selectionController: selectionController,
    actions: actions,
  );

  @override
  void updateTime() => mainGrid.time = DateTime.now();

  bool needToRefresh(Duration microseconds) =>
      mainGrid.time.isBefore(DateTime.now().subtract(microseconds));

  String? restoreSecondaryGrid;

  @override
  double get offset => mainGrid.currentState.offset;

  @override
  int get page => mainGrid.page;

  @override
  set page(int p) => mainGrid.page = p;

  @override
  void setOffset(double o) {
    mainGrid.currentState.copy(offset: o).save(mainGrid);
  }

  @override
  void dispose() {
    client.close();
    source.destroy();
    status.destroy();

    _subpageEvents.close();

    popularStatus.source.destroy();
    popularStatus.destroy();

    videosStatus.source.destroy();
    videosStatus.destroy();

    randomStatus.source.destroy();
    randomStatus.destroy();
  }
}

class BooruStackInjector implements ShellScopeOverlayInjector {
  BooruStackInjector(
    this._stream,
    this._chipsState,
    this.latest,
    this.video,
    this.popular,
    this.random,
    this.selectionController,
  );

  final SelectionController selectionController;

  final StreamController<BooruChipsState> _stream;
  BooruChipsState _chipsState;

  Stream<BooruChipsState> get stream => _stream.stream;
  BooruChipsState get chipsState => _chipsState;

  void updateChipsState(BooruChipsState c) {
    _chipsState = c;
    _stream.sink.add(c);
  }

  final SourceShellElementState<Post> latest;
  final SourceShellElementState<Post> video;
  final SourceShellElementState<Post> popular;
  final SourceShellElementState<Post> random;

  @override
  List<Widget> injectStack(BuildContext context) {
    return const [];
  }

  @override
  OnEmptyInterface get onEmpty => const OnEmptyInterface.empty();

  @override
  Widget wrapChild(Widget child) {
    return ShellSelectionCountHolder(
      key: null,
      selection: latest.selection,
      controller: selectionController,
      child: _CurrentPageRefreshIndicator(
        initialValue: chipsState,
        latest: latest,
        popular: popular,
        random: random,
        video: video,
        stream: stream,
        child: child,
      ),
    );
  }

  @override
  double tryCalculateScrollSizeToItem(
    double contentSize,
    int idx,
    GridLayoutType layoutType,
    GridColumn columns,
  ) {
    final source = switch (chipsState) {
      BooruChipsState.latest => latest.source,
      BooruChipsState.popular => popular.source,
      BooruChipsState.random => random.source,
      BooruChipsState.videos => video.source,
    };

    if (layoutType == GridLayoutType.list) {
      return contentSize * idx / source.count;
    } else {
      return contentSize *
          (idx / columns.number - 1) /
          (source.count / columns.number);
    }
  }
}

class _CurrentPageRefreshIndicator extends StatefulWidget {
  const _CurrentPageRefreshIndicator({
    super.key,
    required this.initialValue,
    required this.stream,
    required this.latest,
    required this.video,
    required this.popular,
    required this.random,
    required this.child,
  });

  final Stream<BooruChipsState> stream;
  final BooruChipsState initialValue;

  final SourceShellElementState<Post> latest;
  final SourceShellElementState<Post> video;
  final SourceShellElementState<Post> popular;
  final SourceShellElementState<Post> random;

  final Widget child;

  @override
  State<_CurrentPageRefreshIndicator> createState() =>
      __CurrentPageRefreshIndicatorState();
}

class __CurrentPageRefreshIndicatorState
    extends State<_CurrentPageRefreshIndicator> {
  late final StreamSubscription<BooruChipsState> _events;
  late BooruChipsState value;

  @override
  void initState() {
    super.initState();

    value = widget.initialValue;

    _events = widget.stream.listen((e) {
      if (e == value) {
        return;
      }

      setState(() {
        value = e;
      });
    });
  }

  @override
  void dispose() {
    _events.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = switch (value) {
      BooruChipsState.latest => widget.latest,
      BooruChipsState.popular => widget.popular,
      BooruChipsState.random => widget.random,
      BooruChipsState.videos => widget.video,
    };

    return SourceShellRefreshIndicator(
      selection: status.selection,
      source: status.source,
      child: widget.child,
    );
  }
}
