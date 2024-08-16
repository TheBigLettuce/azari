// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/init_main/restart_widget.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/pages/anime/info_base/always_loading_anime_mixin.dart";
import "package:azari/src/plugs/platform_functions.dart";
import "package:azari/src/widgets/gesture_dead_zones.dart";
import "package:azari/src/widgets/glue_provider.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/image_view/mixins/loading_builder.dart";
import "package:azari/src/widgets/image_view/mixins/page_type_mixin.dart";
import "package:azari/src/widgets/image_view/mixins/palette.dart";
import "package:azari/src/widgets/image_view/video_controls_controller.dart";
import "package:azari/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:azari/src/widgets/image_view/wrappers/wrap_image_view_skeleton.dart";
import "package:azari/src/widgets/image_view/wrappers/wrap_image_view_theme.dart";
import "package:azari/src/widgets/load_tags.dart";
import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:logging/logging.dart";
import "package:photo_view/photo_view_gallery.dart";
import "package:wakelock_plus/wakelock_plus.dart";

part "body.dart";
part "video_controls.dart";

class ImageViewStatistics {
  const ImageViewStatistics({required this.swiped, required this.viewed});
  final void Function() swiped;
  final void Function() viewed;

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

  final void Function()? onExit;

  final void Function()? beforeRestore;

  final ImageViewStatistics? statistics;

  final void Function(ImageViewState state)? pageChange;
}

abstract interface class ContentableCell
    implements ImageViewContentable, CellBase {}

class ImageView extends StatefulWidget {
  const ImageView({
    super.key,
    required this.cellCount,
    required this.scrollUntill,
    required this.startingCell,
    this.onExit,
    this.statistics,
    this.tags,
    this.updates,
    this.watchTags,
    this.ignoreLoadingBuilder = false,
    required this.getCell,
    required this.onNearEnd,
    this.pageChange,
    this.download,
    this.onRightSwitchPageEnd,
    this.onLeftSwitchPageEnd,
    this.gridContext,
    this.preloadNextPictures = false,
  });

  final int startingCell;
  final Contentable? Function(int i) getCell;
  final int cellCount;
  final void Function(int post) scrollUntill;
  final Future<int> Function()? onNearEnd;
  final void Function(int i)? download;
  final void Function(ImageViewState state)? pageChange;
  final void Function()? onExit;

  final ImageViewStatistics? statistics;

  final BuildContext? gridContext;

  final bool ignoreLoadingBuilder;
  final bool preloadNextPictures;

  final void Function()? onRightSwitchPageEnd;
  final void Function()? onLeftSwitchPageEnd;

  final StreamSubscription<int> Function(void Function(int) f)? updates;

  final List<ImageTag> Function(Contentable)? tags;
  final StreamSubscription<List<ImageTag>> Function(
    Contentable,
    void Function(List<ImageTag> l),
  )? watchTags;

  static Future<void> launchWrapped(
    BuildContext context,
    int cellCount,
    Contentable Function(int) cell, {
    int startingCell = 0,
    void Function(int)? download,
    Key? key,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) {
          return GlueProvider.empty(
            context,
            child: ImageView(
              key: key,
              cellCount: cellCount,
              download: download,
              scrollUntill: (_) {},
              startingCell: startingCell,
              onExit: () {},
              getCell: cell,
              onNearEnd: null,
            ),
          );
        },
      ),
    );
  }

  static Future<void> launchWrappedAsyncSingle(
    BuildContext context,
    Future<Contentable Function()> Function() cell, {
    void Function(int)? download,
    Key? key,
    List<ImageTag> Function(Contentable)? tags,
    StreamSubscription<List<ImageTag>> Function(
      Contentable,
      void Function(List<ImageTag> l),
    )? watchTags,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) {
          return WrapFutureRestartable(
            newStatus: cell,
            builder: (context, value) => GlueProvider.empty(
              context,
              child: ImageView(
                key: key,
                cellCount: 1,
                download: download,
                tags: tags,
                watchTags: watchTags,
                scrollUntill: (_) {},
                startingCell: 0,
                onExit: () {},
                getCell: (_) => value(),
                onNearEnd: null,
              ),
            ),
          );
        },
      ),
    );
  }

  static Future<void> defaultForGrid<T extends ContentableCell>(
    BuildContext gridContext,
    GridFunctionality<T> functionality,
    ImageViewDescription<T> imageDesctipion,
    int startingCell,
    List<ImageTag> Function(Contentable)? tags,
    StreamSubscription<List<ImageTag>> Function(
      Contentable,
      void Function(List<ImageTag> l),
    )? watchTags,
    void Function(T)? addToVisited,
  ) {
    functionality.selectionGlue.hideNavBar(true);

    final getCell = CellProvider.of<T>(gridContext);

    addToVisited?.call(getCell(startingCell));

    return Navigator.of(gridContext, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (context) {
          final r = functionality.registerNotifiers;

          final c = ImageView(
            updates: functionality.source.backingStorage.watch,
            gridContext: gridContext,
            statistics: imageDesctipion.statistics,
            scrollUntill: (i) =>
                GridScrollNotifier.scrollToOf<T>(gridContext, i),
            pageChange: (state) {
              imageDesctipion.pageChange?.call(state);
              addToVisited?.call(getCell(state.currentPage));
            },
            watchTags: watchTags,
            onExit: imageDesctipion.onExit,
            getCell: (idx) => getCell(idx).content(),
            cellCount: functionality.source.count,
            download: functionality.download,
            startingCell: startingCell,
            tags: tags,
            onNearEnd:
                imageDesctipion.ignoreOnNearEnd || !functionality.source.hasNext
                    ? null
                    : functionality.source.next,
          );

          return r != null ? r(c) : c;
        },
      ),
    ).then((value) {
      functionality.selectionGlue.hideNavBar(false);

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
  final GlobalKey<WrapImageViewNotifiersState> wrapNotifiersKey = GlobalKey();
  final GlobalKey<WrapImageViewThemeState> wrapThemeKey = GlobalKey();
  // final _k = GlobalKey();

  late final AnimationController animationController;
  late final AnimationController slideAnimationLeft;
  late final AnimationController slideAnimationRight;
  late final DraggableScrollableController bottomSheetController;

  final scrollController = ScrollController();
  final mainFocus = FocusNode();

  final videoControls = VideoControlsControllerImpl();

  late PageController controller =
      PageController(initialPage: widget.startingCell);

  StreamSubscription<int>? _updates;

  late int currentPage = widget.startingCell;
  late int cellCount = widget.cellCount;

  bool refreshing = false;

  int _incr = 0;

  GlobalProgressTab? globalProgressTab;

  final currentPageStream = StreamController<int>.broadcast();

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(vsync: this);
    bottomSheetController = DraggableScrollableController();
    slideAnimationLeft = AnimationController(vsync: this);
    slideAnimationRight = AnimationController(vsync: this);

    _updates = widget.updates?.call((c) {
      if (c <= 0) {
        Navigator.of(context).pop();

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

    WakelockPlus.enable();

    loadCells(currentPage, cellCount);

    WidgetsBinding.instance.scheduleFrameCallback((_) {
      PlatformApi.current()
          .setTitle(drawCell(currentPage).widgets.alias(false));
      _loadNext(widget.startingCell);
    });

    refreshPalette();
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
    currentPageStream.close();
    animationController.dispose();
    slideAnimationLeft.dispose();
    slideAnimationRight.dispose();
    bottomSheetController.dispose();
    _updates?.cancel();

    videoControls.dispose();

    PlatformApi.current().setFullscreen(false);

    WakelockPlus.disable();
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

    PlatformApi.current().setTitle(c.widgets.alias(false));

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
      child: WrapImageViewNotifiers(
        hardRefresh: refreshImage,
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
        child: WrapImageViewTheme(
          key: wrapThemeKey,
          currentPalette: currentPalette,
          previousPallete: previousPallete,
          child: WrapImageViewSkeleton(
            scaffoldKey: key,
            videoControls: videoControls,
            bottomSheetController: bottomSheetController,
            controller: animationController,
            next: _onPressedRight,
            prev: _onPressedLeft,
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
