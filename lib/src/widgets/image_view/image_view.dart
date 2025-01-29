// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/init_main/restart_widget.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/platform/gallery_api.dart";
import "package:azari/src/platform/platform_api.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/gesture_dead_zones.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/sticker.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/image_view/default_state_controller.dart";
import "package:azari/src/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/widgets/image_view/image_view_skeleton.dart";
import "package:azari/src/widgets/image_view/image_view_theme.dart";
import "package:azari/src/widgets/image_view/video/video_controls_controller.dart";
import "package:azari/src/widgets/load_tags.dart";
import "package:azari/src/widgets/selection_actions.dart";
import "package:azari/src/widgets/wrap_future_restartable.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:logging/logging.dart";
import "package:photo_view/photo_view.dart";
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

  final void Function(ImageViewStateController state)? pageChange;
}

abstract interface class ContentableCell
    implements ImageViewContentable, CellBase {}

abstract class ImageViewStateController {
  int get currentIndex;

  int get count;

  void bind(
    BuildContext context, {
    required int startingIndex,
    required VoidCallback playAnimationLeft,
    required VoidCallback playAnimationRight,
    required VoidCallback flipShowAppBar,
  });
  void unbind();

  void refreshImage();

  void seekTo(int i);

  Widget buildBody(BuildContext context);
  Widget injectMetadataProvider(Widget child);

  Stream<int> get indexEvents;
  Stream<int> get countEvents;
}

abstract class CurrentIndexMetadata {
  static CurrentIndexMetadata? maybeOf(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<CurrentIndexMetadataNotifier>();

    return widget?.metadata;
  }

  static ImageProvider? Function(int idx) thumbnailsOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<ThumbnailsNotifier>();

    return widget!.provider;
  }

  static CurrentIndexMetadata of(BuildContext context) => maybeOf(context)!;

  bool get isVideo;
  int get index;
  int get count;
  Key get uniqueKey;

  List<ImageViewAction> actions(BuildContext context);

  List<NavigationAction> appBarButtons(BuildContext context);

  Widget? openMenuButton(BuildContext context);

  List<Sticker> stickers(BuildContext context);
}

class CurrentIndexMetadataNotifier extends InheritedWidget {
  const CurrentIndexMetadataNotifier({
    super.key,
    required this.metadata,
    required super.child,
    required int refreshTimes,
  }) : _refreshTimes = refreshTimes;

  final CurrentIndexMetadata metadata;
  final int _refreshTimes;

  @override
  bool updateShouldNotify(CurrentIndexMetadataNotifier oldWidget) =>
      metadata != oldWidget.metadata ||
      _refreshTimes != oldWidget._refreshTimes;
}

class ThumbnailsNotifier extends InheritedWidget {
  const ThumbnailsNotifier({
    super.key,
    required this.provider,
    required super.child,
  });

  final ImageProvider? Function(int idx) provider;

  @override
  bool updateShouldNotify(ThumbnailsNotifier oldWidget) =>
      provider != oldWidget.provider;
}

class ImageView extends StatefulWidget {
  const ImageView({
    super.key,
    this.onExit,
    this.startingIndex = 0,
    required this.stateController,
  });

  final VoidCallback? onExit;

  final int startingIndex;

  final ImageViewStateController stateController;

  static Future<void> launchWrapped(
    BuildContext context,
    int cellCount,
    ContentGetter getContent, {
    int startingCell = 0,
    ContentIdxCallback? download,
    void Function(Contentable)? addToVisited,
    List<ImageTag> Function(ContentWidgets)? tags,
    ImageViewDescription? imageDesctipion,
    WatchTagsCallback? watchTags,
    NotifierWrapper? wrapNotifiers,
    Key? key,
  }) {
    addToVisited?.call(getContent(startingCell)!);

    final stateController = DefaultStateController(
      getContent: getContent,
      count: cellCount,
      statistics: imageDesctipion?.statistics,
      download: download,
      wrapNotifiers: wrapNotifiers,
      tags: tags,
      watchTags: watchTags,
      pageChange: (state) {
        imageDesctipion?.pageChange?.call(state);
        addToVisited?.call(getContent(state.currentIndex)!);
      },
    );

    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => ImageView(
          key: key,
          startingIndex: startingCell,
          onExit: imageDesctipion?.onExit,
          stateController: stateController,
        ),
      ),
    )..whenComplete(() {
        stateController.dispose();
      });
  }

  static Future<void> launchWrappedAsyncSingle(
    BuildContext context,
    Future<Contentable Function()> Function() cell, {
    ContentIdxCallback? download,
    Key? key,
    List<ImageTag> Function(ContentWidgets)? tags,
    WatchTagsCallback? watchTags,
    NotifierWrapper? wrapNotifiers,
  }) {
    DefaultStateController? stateController;

    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => WrapFutureRestartable(
          newStatus: () async {
            final cell_ = await cell();

            stateController?.dispose();
            stateController = DefaultStateController(
              getContent: (_) => cell_(),
              count: 1,
              wrapNotifiers: wrapNotifiers,
              tags: tags,
              watchTags: watchTags,
              download: download,
            );

            return stateController!;
          },
          builder: (context, value) => ImageView(
            key: key,
            stateController: value,
          ),
        ),
      ),
    )..whenComplete(() {
        stateController?.dispose();
      });
  }

  static Future<void> defaultForGrid<T extends ContentableCell>(
    BuildContext gridContext,
    GridFunctionality<T> functionality,
    ImageViewDescription<T> imageDesctipion,
    int startingCell,
    List<ImageTag> Function(ContentWidgets)? tags,
    WatchTagsCallback? watchTags,
    void Function(T)? addToVisited, {
    FlutterGalleryDataImpl? galleryImpl,
  }) {
    final selection = SelectionActions.of(gridContext);
    selection.controller.setVisibility(false);

    final getCell = CellProvider.of<T>(gridContext);

    addToVisited?.call(getCell(startingCell));

    final ImageViewStateController stateController = galleryImpl ??
        DefaultStateController(
          getContent: (idx) => getCell(idx).content(),
          count: functionality.source.count,
          countEvents: functionality.source.backingStorage.countEvents,
          statistics: imageDesctipion.statistics,
          download: functionality.download,
          watchTags: watchTags,
          tags: tags,
          wrapNotifiers: functionality.registerNotifiers,
          scrollUntill: (i) =>
              GridScrollNotifier.maybeScrollToOf<T>(gridContext, i),
          onNearEnd:
              imageDesctipion.ignoreOnNearEnd || !functionality.source.hasNext
                  ? null
                  : functionality.source.next,
          pageChange: (state) {
            imageDesctipion.pageChange?.call(state);
            addToVisited?.call(getCell(state.currentIndex));
          },
        );

    return Navigator.of(gridContext, rootNavigator: true)
        .push(
      MaterialPageRoute<void>(
        builder: (context) => ImageView(
          // watchTags: watchTags,
          onExit: imageDesctipion.onExit,
          startingIndex: startingCell,
          // tags: tags,
          stateController: stateController,
        ),
      ),
    )
        .then((value) {
      selection.controller.setVisibility(true);

      return value;
    })
      ..whenComplete(() {
        if (stateController is DefaultStateController) {
          stateController.dispose();
        }
      });
  }

  static final log = Logger("ImageView");

  @override
  State<ImageView> createState() => ImageViewState();
}

class ImageViewState extends State<ImageView> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> key = GlobalKey();
  final GlobalKey<ImageViewThemeState> wrapThemeKey = GlobalKey();

  late final AnimationController animationController;
  late final AnimationController slideAnimationLeft;
  late final AnimationController slideAnimationRight;

  final pauseVideoState = PauseVideoState();

  final videoControls = VideoControlsControllerImpl();

  late final StreamSubscription<int> _countEvents;
  final _appBarFlipController = StreamController<void>.broadcast();

  int _incr = 0;
  bool popd = false;

  GlobalProgressTab? globalProgressTab;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(vsync: this);
    slideAnimationLeft = AnimationController(vsync: this);
    slideAnimationRight = AnimationController(vsync: this);

    widget.stateController.bind(
      context,
      startingIndex: widget.startingIndex,
      playAnimationLeft: () => slideAnimationLeft
          .reverse()
          .then((e) => slideAnimationLeft.forward()),
      playAnimationRight: () => slideAnimationRight
          .reverse()
          .then((e) => slideAnimationRight.forward()),
      flipShowAppBar: () {
        _appBarFlipController.add(null);
      },
    );

    _countEvents = widget.stateController.countEvents.listen((newCount) {
      if (newCount <= 0) {
        if (!popd) {
          popd = true;
          if (context.mounted) {
            // ignore: use_build_context_synchronously
            Navigator.of(context).pop();
          }
        }

        return;
      }
    });

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
    widget.stateController.unbind();

    _appBarFlipController.close();
    pauseVideoState.dispose();
    _countEvents.cancel();
    animationController.dispose();
    slideAnimationLeft.dispose();
    slideAnimationRight.dispose();

    videoControls.dispose();

    PlatformApi()
      ..setFullscreen(false)
      ..setWakelock(false);

    widget.onExit?.call();

    globalProgressTab?.loadTags().removeListener(_onTagRefresh);

    super.dispose();
  }

  void _onTagRefresh() {
    setState(() {});
  }

  void _incrTiles() {
    _incr += 1;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ImageViewInfoTilesRefreshNotifier(
      count: _incr,
      incr: _incrTiles,
      child: ImageViewNotifiers(
        stateController: widget.stateController,
        controller: animationController,
        videoControls: videoControls,
        pauseVideoState: pauseVideoState,
        flipShowAppBar: _appBarFlipController.stream,
        child: ImageViewTheme(
          key: wrapThemeKey,
          child: ImageViewSkeleton(
            scaffoldKey: key,
            stateControler: widget.stateController,
            videoControls: videoControls,
            controller: animationController,
            pauseVideoState: pauseVideoState,
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
                child: Builder(
                  builder: widget.stateController.buildBody,
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
  double? volume;

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

  @override
  void setVolume(double v) {
    if (v != volume) {
      volume = v;
      _playerEvents.add(VolumeUpdate(v));
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
