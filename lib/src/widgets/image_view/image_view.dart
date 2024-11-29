// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/init_main/restart_widget.dart";
import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/platform/gallery_api.dart";
import "package:azari/src/platform/platform_api.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/gesture_dead_zones.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/widgets/image_view/image_view_skeleton.dart";
import "package:azari/src/widgets/image_view/image_view_theme.dart";
import "package:azari/src/widgets/image_view/mixins/loading_builder.dart";
import "package:azari/src/widgets/image_view/mixins/page_type_mixin.dart";
import "package:azari/src/widgets/image_view/mixins/palette.dart";
import "package:azari/src/widgets/image_view/video/video_controls_controller.dart";
import "package:azari/src/widgets/load_tags.dart";
import "package:azari/src/widgets/selection_actions.dart";
import "package:azari/src/widgets/wrap_future_restartable.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:logging/logging.dart";
import "package:photo_view/photo_view_gallery.dart";

part "image_view_body.dart";
part "video/video_controls.dart";

typedef NotifierWrapper = Widget Function(Widget child);
typedef ContentGetter = Contentable? Function(int i);
typedef ContentIdxCallback = void Function(int i);

class ImageViewStatistics {
  const ImageViewStatistics({
    required this.swiped,
    required this.viewed,
  });

  final VoidCallback swiped;
  final VoidCallback viewed;

  ImageViewStatistics operator +(ImageViewStatistics other) {
    return ImageViewStatistics(
      swiped: () {
        other.swiped();
        swiped();
      },
      viewed: () {
        other.viewed();
        viewed();
      },
    );
  }
}

abstract interface class ImageViewContentable {
  Contentable content();
}

@immutable
class ImageViewDescription<T extends ContentableCell> {
  const ImageViewDescription({
    this.pageChange,
    this.beforeRestore,
    this.onExit,
    this.statistics,
    this.ignoreOnNearEnd = true,
  });

  final bool ignoreOnNearEnd;

  final ImageViewStatistics? statistics;

  final VoidCallback? onExit;
  final VoidCallback? beforeRestore;

  final void Function(ImageViewState state)? pageChange;
}

abstract interface class ContentableCell
    implements ImageViewContentable, CellBase {}

class ImageView extends StatefulWidget {
  const ImageView({
    super.key,
    required this.scrollUntill,
    required this.startingCell,
    this.onExit,
    this.statistics,
    this.tags,
    this.updates,
    this.watchTags,
    this.ignoreLoadingBuilder = false,
    required this.getContent,
    required this.onNearEnd,
    this.pageChange,
    this.download,
    this.onRightSwitchPageEnd,
    this.onLeftSwitchPageEnd,
    this.gridContext,
    this.preloadNextPictures = false,
    this.wrapNotifiers,
    required this.cellCount,
  });

  const ImageView.simple({
    super.key,
    required this.getContent,
    required this.cellCount,
    this.ignoreLoadingBuilder = false,
    this.preloadNextPictures = false,
    this.startingCell = 0,
    this.scrollUntill = _nothingScroll,
    this.onExit,
    this.statistics,
    this.tags,
    this.updates,
    this.watchTags,
    this.onNearEnd,
    this.pageChange,
    this.download,
    this.onRightSwitchPageEnd,
    this.onLeftSwitchPageEnd,
    this.gridContext,
    this.wrapNotifiers,
  });

  final bool ignoreLoadingBuilder;
  final bool preloadNextPictures;

  final int startingCell;
  final int cellCount;

  final BuildContext? gridContext;

  final ContentGetter getContent;

  final ContentIdxCallback scrollUntill;
  final ContentIdxCallback? download;

  final ImageViewStatistics? statistics;

  final VoidCallback? onExit;

  final VoidCallback? onRightSwitchPageEnd;
  final VoidCallback? onLeftSwitchPageEnd;

  final NotifierWrapper? wrapNotifiers;

  final WatchTagsCallback? watchTags;

  final void Function(ImageViewState state)? pageChange;
  final Future<int> Function()? onNearEnd;
  final List<ImageTag> Function(Contentable)? tags;

  final StreamSubscription<int> Function(void Function(int) f)? updates;

  static void _nothingScroll(int _) {}

  static Future<void> launchWrapped(
    BuildContext context,
    int cellCount,
    ContentGetter getContent, {
    int startingCell = 0,
    ContentIdxCallback? download,
    void Function(Contentable)? addToVisited,
    List<ImageTag> Function(Contentable)? tags,
    ImageViewDescription? imageDesctipion,
    WatchTagsCallback? watchTags,
    NotifierWrapper? wrapNotifiers,
    Key? key,
  }) {
    addToVisited?.call(getContent(startingCell)!);

    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => ImageView(
          key: key,
          statistics: imageDesctipion?.statistics,
          cellCount: cellCount,
          download: download,
          scrollUntill: (_) {},
          pageChange: (state) {
            imageDesctipion?.pageChange?.call(state);
            addToVisited?.call(getContent(state.currentPage)!);
          },
          startingCell: startingCell,
          onExit: imageDesctipion?.onExit,
          getContent: getContent,
          watchTags: watchTags,
          tags: tags,
          onNearEnd: null,
          wrapNotifiers: wrapNotifiers,
        ),
      ),
    );
  }

  static Future<void> launchWrappedAsyncSingle(
    BuildContext context,
    Future<Contentable Function()> Function() cell, {
    ContentIdxCallback? download,
    Key? key,
    List<ImageTag> Function(Contentable)? tags,
    WatchTagsCallback? watchTags,
    NotifierWrapper? wrapNotifiers,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => WrapFutureRestartable(
          newStatus: cell,
          builder: (context, value) => ImageView(
            key: key,
            cellCount: 1,
            download: download,
            tags: tags,
            watchTags: watchTags,
            scrollUntill: (_) {},
            startingCell: 0,
            onExit: () {},
            getContent: (_) => value(),
            onNearEnd: null,
            wrapNotifiers: wrapNotifiers,
          ),
        ),
      ),
    );
  }

  static Future<void> defaultForGrid<T extends ContentableCell>(
    BuildContext gridContext,
    GridFunctionality<T> functionality,
    ImageViewDescription<T> imageDesctipion,
    int startingCell,
    List<ImageTag> Function(Contentable)? tags,
    WatchTagsCallback? watchTags,
    void Function(T)? addToVisited,
  ) {
    final selection = SelectionActions.of(gridContext);
    selection.controller.setVisibility(false);

    final getCell = CellProvider.of<T>(gridContext);

    addToVisited?.call(getCell(startingCell));

    return Navigator.of(gridContext, rootNavigator: true)
        .push(
      MaterialPageRoute<void>(
        builder: (context) => ImageView(
          updates: functionality.source.backingStorage.watch,
          gridContext: gridContext,
          statistics: imageDesctipion.statistics,
          scrollUntill: (i) =>
              GridScrollNotifier.maybeScrollToOf<T>(gridContext, i),
          pageChange: (state) {
            imageDesctipion.pageChange?.call(state);
            addToVisited?.call(getCell(state.currentPage));
          },
          watchTags: watchTags,
          onExit: imageDesctipion.onExit,
          getContent: (idx) => getCell(idx).content(),
          cellCount: functionality.source.count,
          download: functionality.download,
          startingCell: startingCell,
          tags: tags,
          onNearEnd:
              imageDesctipion.ignoreOnNearEnd || !functionality.source.hasNext
                  ? null
                  : functionality.source.next,
          wrapNotifiers: functionality.registerNotifiers,
        ),
      ),
    )
        .then((value) {
      selection.controller.setVisibility(true);

      return value;
    });
  }

  static final log = Logger("ImageView");

  @override
  State<ImageView> createState() => ImageViewState();
}

class ImageViewState extends State<ImageView>
    with
        ImageViewPageTypeMixin,
        ImageViewPaletteMixin,
        ImageViewLoadingBuilderMixin,
        TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> key = GlobalKey();
  final GlobalKey<ImageViewNotifiersState> wrapNotifiersKey = GlobalKey();
  final GlobalKey<ImageViewThemeState> wrapThemeKey = GlobalKey();
  final bodyKey = GlobalKey();

  late final AnimationController animationController;
  late final AnimationController slideAnimationLeft;
  late final AnimationController slideAnimationRight;
  late final DraggableScrollableController bottomSheetController;

  final scrollController = ScrollController();
  final mainFocus = FocusNode();
  final pauseVideoState = PauseVideoState();

  final videoControls = VideoControlsControllerImpl();

  late PageController controller =
      PageController(initialPage: widget.startingCell);

  StreamSubscription<int>? _updates;

  late final StreamSubscription<GalleryPageChangeEvent>? _pageChangeEvent;

  late int currentPage = widget.startingCell;
  late int cellCount = widget.cellCount;

  bool refreshing = false;

  int _incr = 0;

  GlobalProgressTab? globalProgressTab;

  final currentPageStream = StreamController<int>.broadcast();

  bool popd = false;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(vsync: this);
    bottomSheetController = DraggableScrollableController();
    slideAnimationLeft = AnimationController(vsync: this);
    slideAnimationRight = AnimationController(vsync: this);

    _pageChangeEvent = GalleryApi().events.pageChange?.listen((e) {
      switch (e) {
        case GalleryPageChangeEvent.left:
          _onPressedLeft();
        case GalleryPageChangeEvent.right:
          _onPressedRight();
      }
    });

    _updates = widget.updates?.call((c) {
      if (c <= 0) {
        if (!popd) {
          popd = true;
          Navigator.of(context).pop();
        }

        return;
      }

      final shiftCurrentPage = c - cellCount;

      cellCount = c;
      if (widget.onNearEnd != null) {
        setState(() {});
        return;
      }

      final prev = currentPage;
      currentPage = (prev +
              (shiftCurrentPage.isNegative || prev == 0 ? 0 : shiftCurrentPage))
          .clamp(0, cellCount - 1);

      if (currentPage != prev && prev != 0) {
        controller.jumpToPage(currentPage);
      } else {
        if (cellCount != c) {
          widget.statistics?.viewed();
        }

        loadCells(currentPage, cellCount);
        refreshPalette();

        currentPageStream.add(currentPage);

        setState(() {});
      }
    });

    widget.statistics?.viewed();

    loadCells(currentPage, cellCount);

    WidgetsBinding.instance.scheduleFrameCallback((_) {
      PlatformApi().window.setTitle(drawCell(currentPage).widgets.alias(false));
      _loadNext(widget.startingCell);
    });

    refreshPalette();
    PlatformApi().setWakelock(true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (globalProgressTab != null) {
      globalProgressTab = GlobalProgressTab.maybeOf(context);
      globalProgressTab?.loadTags().addListener(_onTagRefresh);
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);

    pauseVideoState.dispose();
    _pageChangeEvent?.cancel();
    currentPageStream.close();
    animationController.dispose();
    slideAnimationLeft.dispose();
    slideAnimationRight.dispose();
    bottomSheetController.dispose();
    _updates?.cancel();

    videoControls.dispose();

    PlatformApi()
      ..setFullscreen(false)
      ..setWakelock(false);

    controller.dispose();

    widget.onExit?.call();

    scrollController.dispose();
    mainFocus.dispose();

    globalProgressTab?.loadTags().removeListener(_onTagRefresh);

    super.dispose();
  }

  void refreshPalette() {
    extractPalette(
      drawCell(currentPage, true),
      key,
      scrollController,
      currentPage,
      _resetAnimation,
    );
  }

  void _resetAnimation() {
    wrapThemeKey.currentState?.resetAnimation();
  }

  void _loadNext(int index) {
    if (index >= cellCount - 3 && !refreshing && widget.onNearEnd != null) {
      setState(() {
        refreshing = true;
      });
      widget.onNearEnd!().then((value) {
        if (context.mounted) {
          setState(() {
            cellCount = value;
          });
        }
      }).onError((e, trace) {
        ImageView.log.warning("_loadNext", e, trace);
      }).then((value) {
        refreshing = false;
      });
    }
  }

  void refreshImage([bool refreshPalette = false]) {
    loadCells(currentPage, cellCount);

    final c = drawCell(currentPage, true);
    if (c is NetImage) {
      c.provider.evict();
    } else if (c is NetGif) {
      c.provider.evict();
    }

    if (refreshPalette) {
      this.refreshPalette();
    }

    setState(() {});
  }

  void _onTap() {
    wrapNotifiersKey.currentState?.toggle();
  }

  void _onTagRefresh() {
    setState(() {});
  }

  void _onPageChanged(int index) {
    widget.statistics?.viewed();
    widget.statistics?.swiped();

    refreshTries = 0;

    currentPage = index;
    widget.pageChange?.call(this);
    _loadNext(index);

    widget.scrollUntill(index);

    loadCells(index, cellCount);

    final c = drawCell(index);

    PlatformApi().window.setTitle(c.widgets.alias(false));

    refreshPalette();

    currentPageStream.add(currentPage);

    setState(() {});
  }

  void _onLongPress() {
    if (widget.download == null) {
      return;
    }

    HapticFeedback.vibrate();
    widget.download!(currentPage);
  }

  void _incrTiles() {
    _incr += 1;

    setState(() {});
  }

  void _onPressedRight() {
    if (currentPage + 1 != cellCount && cellCount != 1) {
      controller.nextPage(duration: 200.ms, curve: Easing.standard);
    } else {
      if (widget.onRightSwitchPageEnd != null) {
        widget.onRightSwitchPageEnd?.call();
      } else {
        slideAnimationRight
            .reverse()
            .then((e) => slideAnimationRight.forward());
      }
    }
  }

  void _onPressedLeft() {
    if (currentPage != 0 && cellCount != 1) {
      controller.previousPage(duration: 200.ms, curve: Easing.standard);
    } else {
      if (widget.onLeftSwitchPageEnd != null) {
        widget.onLeftSwitchPageEnd?.call();
      } else {
        slideAnimationLeft.reverse().then((e) => slideAnimationLeft.forward());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ImageViewInfoTilesRefreshNotifier(
      count: _incr,
      incr: _incrTiles,
      child: ImageViewNotifiers(
        hardRefresh: refreshImage,
        wrapNotifiers: widget.wrapNotifiers,
        tags: widget.tags,
        watchTags: widget.watchTags,
        bottomSheetController: bottomSheetController,
        mainFocus: mainFocus,
        controller: animationController,
        gridContext: widget.gridContext,
        key: wrapNotifiersKey,
        page: this,
        currentPage: currentPageStream.stream,
        videoControls: videoControls,
        pauseVideoState: pauseVideoState,
        child: ImageViewTheme(
          key: wrapThemeKey,
          currentPalette: currentPalette,
          previousPallete: previousPallete,
          child: ImageViewSkeleton(
            scaffoldKey: key,
            videoControls: videoControls,
            bottomSheetController: bottomSheetController,
            controller: animationController,
            next: _onPressedRight,
            prev: _onPressedLeft,
            pauseVideoState: pauseVideoState,
            wrapNotifiers: widget.wrapNotifiers,
            child: Animate(
              controller: slideAnimationLeft,
              autoPlay: false,
              value: 1,
              effects: const [
                SlideEffect(
                  delay: Durations.short1,
                  duration: Durations.medium1,
                  curve: Easing.emphasizedAccelerate,
                  begin: Offset(0.1, 0),
                  end: Offset.zero,
                ),
              ],
              child: Animate(
                controller: slideAnimationRight,
                autoPlay: false,
                value: 1,
                effects: const [
                  SlideEffect(
                    delay: Durations.short1,
                    duration: Durations.medium1,
                    curve: Easing.emphasizedAccelerate,
                    begin: Offset(-0.1, 0),
                    end: Offset.zero,
                  ),
                ],
                child: ImageViewBody(
                  key: bodyKey,
                  onPressedLeft: _onPressedLeft,
                  onPressedRight: _onPressedRight,
                  onPageChanged: _onPageChanged,
                  onLongPress: _onLongPress,
                  pageController: controller,
                  loadingBuilder: widget.ignoreLoadingBuilder
                      ? null
                      : (context, event, idx) => loadingBuilder(
                            context,
                            event,
                            idx,
                            currentPage,
                            wrapNotifiersKey,
                            drawCell,
                          ),
                  itemCount: cellCount,
                  onTap: _onTap,
                  builder: galleryBuilder,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VideoControlsControllerImpl implements VideoControlsController {
  VideoControlsControllerImpl();

  final _events = StreamController<VideoControlsEvent>.broadcast();
  final _playerEvents = StreamController<PlayerUpdate>.broadcast();

  Duration? duration;
  Duration? progress;
  PlayState? playState;

  @override
  Stream<VideoControlsEvent> get events => _events.stream;

  void dispose() {
    _events.close();
    _playerEvents.close();
  }

  @override
  void clear() {
    duration = null;
    progress = null;
    playState = null;

    _playerEvents.add(const ClearUpdate());
  }

  @override
  void setDuration(Duration d) {
    if (d != duration) {
      duration = d;
      _playerEvents.add(DurationUpdate(d));
    }
  }

  @override
  void setPlayState(PlayState p) {
    if (p != playState) {
      playState = p;
      _playerEvents.add(PlayStateUpdate(p));
    }
  }

  @override
  void setProgress(Duration p) {
    if (p != progress) {
      progress = p;
      _playerEvents.add(ProgressUpdate(p));
    }
  }
}

class PauseVideoState {
  PauseVideoState();

  bool _isPaused = false;

  bool get isPaused => _isPaused;
  void setIsPaused(bool p) {
    _isPaused = p;
    _events.add(p);
  }

  final _events = StreamController<bool>.broadcast();

  Stream<bool> get events => _events.stream;

  void dispose() {
    _events.close();
  }
}
