// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/logic/cancellable_grid_settings_data.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/posts_source.dart";
import "package:azari/src/logic/resource_source/basic.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/services/impl/obj/post_impl.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/base/home.dart";
import "package:azari/src/ui/material/pages/search/booru/popular_random_buttons.dart";
import "package:azari/src/ui/material/pages/settings/settings_page.dart";
import "package:azari/src/ui/material/widgets/adaptive_page.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_aspect_ratio.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_column.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

mixin BooruPageMixin<W extends StatefulWidget> on State<W> {
  SettingsData get settings;

  PagingStateRegistry get pagingRegistry;
  SelectionController get selectionController;

  BooruChipsState get currentSubpage => pagingState.currentSubpage;

  final gridSettings = CancellableGridSettingsData.noPersist(
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
        final mainGrid = const GridDbService().openMain(settings.selectedBooru);

        return _MainGridPagingState.prototype(
          settings.selectedBooru,
          mainGrid,
          gridSettings: gridSettings,
          selectionController: selectionController,
          actions: makePostActions(context, settings.selectedBooru),
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

    favoritesWatcher = FavoritePostSourceService.safe()?.cache.countEvents
        .listen((event) {
          source.backingStorage.addAll(const []);
        });

    hiddenPostWatcher = HiddenBooruPostsService.safe()?.watch((_) {
      source.backingStorage.addAll(const []);
      pagingState.randomStatus.source.backingStorage.addAll(const []);
      pagingState.videosStatus.source.backingStorage.addAll(const []);
      pagingState.popularStatus.source.backingStorage.addAll(const []);
    });

    if (GridBookmarkService.available &&
        pagingState.restoreSecondaryGrid != null) {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        final e = const GridBookmarkService().get(
          pagingState.restoreSecondaryGrid!,
        )!;

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

    if (!SettingsPage.isRestart) {
      pagingState.restoreSecondaryGrid = null;
    }

    timeUpdater.cancel();

    lifecycleListener.dispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newColumnCount = switch (AdaptivePage.size(context)) {
      AdaptivePageSize.extraSmall || AdaptivePageSize.small => GridColumn.two,
      AdaptivePageSize.medium => GridColumn.three,
      AdaptivePageSize.large => GridColumn.four,
      AdaptivePageSize.extraLarge => GridColumn.five,
    };

    if (gridSettings.current.columns != newColumnCount) {
      gridSettings.current = gridSettings.current.copy(columns: newColumnCount);
    }
  }

  // ignore: use_setters_to_change_properties
  void setSecondaryName(String? name) {
    pagingState.restoreSecondaryGrid = name;
  }
}

List<SelectionBarAction> makePostActions(
  BuildContext context,
  Booru booru, {
  bool showHideButton = true,
}) => [
  if (HiddenBooruPostsService.available && showHideButton)
    SelectionBarAction(Icons.hide_image_rounded, (selected) {
      if (selected.isEmpty || !HiddenBooruPostsService.available) {
        return;
      }

      final toDelete = <(int, Booru)>[];
      final toAdd = <HiddenBooruPostData>[];

      final booru = (selected.first as PostImpl).booru;

      for (final (cell as PostImpl) in selected) {
        if (const HiddenBooruPostsService().isHidden(cell.id, booru)) {
          toDelete.add((cell.id, booru));
        } else {
          toAdd.add(
            HiddenBooruPostData(
              thumbUrl: cell.previewUrl,
              postId: cell.id,
              booru: booru,
            ),
          );
        }
      }

      const HiddenBooruPostsService()
        ..addAll(toAdd)
        ..removeAll(toDelete);
    }, true),
  if (DownloadManager.available && LocalTagsService.available)
    SelectionBarAction(
      Icons.download,
      (selected) => selected.cast<PostImpl>().downloadAll(),
      true,
      animate: true,
    ),
  if (FavoritePostSourceService.available)
    SelectionBarAction(
      Icons.favorite_border_rounded,
      (selected) =>
          FavoritePostSourceService.safe()?.addRemove(selected.cast()),
      true,
    ),
];

class _MainGridPagingState implements PagingEntry {
  _MainGridPagingState(
    this.gridSettings,
    this.booru,
    this.mainGrid,
    this.actions,
    this.selectionController,
  ) {
    source = mainGrid.makeSource(api, this);

    status = SourceShellElementState(
      source: source,
      gridSettings: gridSettings,
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
      gridSettings,
    );
  }

  factory _MainGridPagingState.prototype(
    Booru booru,
    MainGridHandle mainGrid, {
    required GridSettingsData gridSettings,
    required SelectionController selectionController,
    required List<SelectionBarAction> actions,
  }) => _MainGridPagingState(
    gridSettings,
    booru,
    mainGrid,
    actions,
    selectionController,
  );

  final Booru booru;

  @override
  bool reachedEnd = false;

  late final BooruAPI api = BooruAPI.fromEnum(booru);
  late final GridPostSource source;
  final MainGridHandle mainGrid;
  final SelectionController selectionController;
  final List<SelectionBarAction> actions;
  late final BooruStackInjector stackInjector;

  final GridSettingsData gridSettings;

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
    gridSettings: gridSettings,
    source: GenericListSource<Post>(
      () async {
        popularPageSaver.page = 0;

        final ret = await api.page(
          popularPageSaver.page,
          "",
          const SettingsService().current.safeMode,
          order: BooruPostsOrder.score,
          pageSaver: popularPageSaver,
        );

        return ret.$1;
      },
      next: () async {
        final ret = await api.page(
          popularPageSaver.page + 1,
          "",
          const SettingsService().current.safeMode,
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
    gridSettings: gridSettings,
    source: GenericListSource<Post>(
      () async {
        videosPageSaver.page = 0;

        final ret = await api.randomPosts(
          const SettingsService().current.safeMode,
          true,
          // order: RandomPostsOrder.random,
          addTags: const SettingsService().current.randomVideosAddTags,
          page: videosPageSaver.page,
        );

        return ret;
      },
      next: () async {
        final ret = await api.randomPosts(
          const SettingsService().current.safeMode,
          true,
          // order: RandomPostsOrder.random,
          addTags: const SettingsService().current.randomVideosAddTags,
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
    gridSettings: gridSettings,
    source: GenericListSource<Post>(
      () async {
        randomPageSaver.page = 0;

        final ret = await api.randomPosts(
          const SettingsService().current.safeMode,
          false,
          page: randomPageSaver.page,
        );

        return ret;
      },
      next: () async {
        final ret = await api.randomPosts(
          const SettingsService().current.safeMode,
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
    api.destroy();
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
    this.gridSettings,
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

  final GridSettingsData gridSettings;

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
  double tryCalculateScrollSizeToItem(double contentSize, int idx) {
    final source = switch (chipsState) {
      BooruChipsState.latest => latest.source,
      BooruChipsState.popular => popular.source,
      BooruChipsState.random => random.source,
      BooruChipsState.videos => video.source,
    };

    final conf = gridSettings.current;

    if (conf.layoutType == GridLayoutType.list) {
      return contentSize * idx / source.count;
    } else {
      return contentSize *
          (idx / conf.columns.number - 1) /
          (source.count / conf.columns.number);
    }
  }
}

class _CurrentPageRefreshIndicator extends StatefulWidget {
  const _CurrentPageRefreshIndicator({
    // super.key,
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
