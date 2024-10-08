// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/post_tags.dart";
import "package:azari/src/plugs/gallery.dart";
import "package:azari/src/plugs/platform_functions.dart";
import "package:azari/src/widgets/focus_notifier.dart";
import "package:azari/src/widgets/glue_provider.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:azari/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:azari/src/widgets/image_view/mixins/page_type_mixin.dart";
import "package:azari/src/widgets/image_view/video_controls_controller.dart";
import "package:flutter/material.dart";

class WrapImageViewNotifiers extends StatefulWidget {
  const WrapImageViewNotifiers({
    super.key,
    required this.hardRefresh,
    required this.currentPage,
    required this.page,
    required this.tags,
    required this.watchTags,
    required this.mainFocus,
    required this.controller,
    required this.bottomSheetController,
    required this.gridContext,
    required this.videoControls,
    required this.child,
  });

  final ImageViewPageTypeMixin page;
  final Stream<int> currentPage;
  final FocusNode mainFocus;
  final void Function([bool refreshPalette]) hardRefresh;
  final BuildContext? gridContext;
  final AnimationController controller;
  final DraggableScrollableController bottomSheetController;
  final List<ImageTag> Function(Contentable)? tags;
  final StreamSubscription<List<ImageTag>> Function(
    Contentable,
    void Function(List<ImageTag> l),
  )? watchTags;

  final VideoControlsController videoControls;
  final Widget child;

  @override
  State<WrapImageViewNotifiers> createState() => WrapImageViewNotifiersState();
}

class WrapImageViewNotifiersState extends State<WrapImageViewNotifiers> {
  final _bottomSheetKey = GlobalKey<__BottomSheetPopScopeState>();

  late final StreamSubscription<int> subscr;
  late Contentable content;
  late int currentCell;

  bool _isPaused = false;
  double? _loadingProgress = 1;

  late final _searchData =
      FilterNotifierData(TextEditingController(), FocusNode());

  void toggle() => _bottomSheetKey.currentState?.toggle();

  @override
  void initState() {
    super.initState();
    final (c, cc) = widget.page.currentCell();
    content = c;
    currentCell = cc;

    subscr = widget.currentPage.listen((i) {
      final (c, cc) = widget.page.currentCell();
      content = c;
      currentCell = cc;

      setState(() {});
    });
  }

  @override
  void dispose() {
    subscr.cancel();
    _searchData.dispose();

    super.dispose();
  }

  void pauseVideo() {
    _isPaused = true;

    setState(() {});
  }

  void unpauseVideo() {
    _isPaused = false;

    setState(() {});
  }

  void setLoadingProgress(double? progress) {
    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      try {
        setState(() => _loadingProgress = progress);
      } catch (_) {}
    });
  }

  void _setPause(bool pause) {
    _isPaused = pause;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return OriginalGridContext(
      gridContext: widget.gridContext ?? context,
      child: ImageViewTagWatcher(
        key: ValueKey((currentCell, content.widgets.uniqueKey())),
        tags: widget.tags,
        watchTags: widget.watchTags,
        currentCell: content,
        child: ReloadImageNotifier(
          reload: widget.hardRefresh,
          child: PauseVideoNotifier(
            pause: _isPaused,
            setPause: _setPause,
            child: VideoControlsNotifier(
              controller: widget.videoControls,
              child: TagFilterValueNotifier(
                notifier: _searchData.searchController,
                child: TagFilterNotifier(
                  data: _searchData,
                  child: FocusNotifier(
                    notifier: _searchData.searchFocus,
                    child: CurrentContentNotifier(
                      content: content,
                      child: LoadingProgressNotifier(
                        progress: _loadingProgress,
                        child: _BottomSheetPopScope(
                          key: _bottomSheetKey,
                          controller: widget.bottomSheetController,
                          animationController: widget.controller,
                          child: widget.child,
                        ),
                      ),
                    ),
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

class ImageViewTagWatcher extends StatefulWidget {
  const ImageViewTagWatcher({
    super.key,
    required this.tags,
    required this.watchTags,
    required this.currentCell,
    required this.child,
  });

  final List<ImageTag> Function(Contentable)? tags;
  final StreamSubscription<List<ImageTag>> Function(
    Contentable,
    void Function(List<ImageTag> l),
  )? watchTags;

  final Contentable currentCell;

  final Widget child;

  @override
  State<ImageViewTagWatcher> createState() => _ImageViewTagWatcherState();
}

class _ImageViewTagWatcherState extends State<ImageViewTagWatcher> {
  late final StreamSubscription<List<ImageTag>>? tagWatcher;
  late final ParsedFilenameResult? res;

  List<ImageTag> tags = [];

  @override
  void initState() {
    super.initState();

    res = ParsedFilenameResult.fromFilename(
            widget.currentCell.widgets.alias(true))
        .maybeValue();

    tagWatcher = widget.watchTags?.call(widget.currentCell, (t) {
      final newTags = <ImageTag>[];

      newTags.addAll(t.where((element) => element.favorite));
      newTags.addAll(t.where((element) => !element.favorite));

      setState(() {
        tags = newTags;
      });
    });

    final t = widget.tags?.call(widget.currentCell);
    if (t != null) {
      tags.addAll(t.where((element) => element.favorite));
      tags.addAll(t.where((element) => !element.favorite));
    }
  }

  @override
  void dispose() {
    tagWatcher?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ImageTagsNotifier(
      tags: tags,
      res: res,
      child: widget.child,
    );
  }
}

class OriginalGridContext extends InheritedWidget {
  const OriginalGridContext({
    super.key,
    required this.gridContext,
    required super.child,
  });

  final BuildContext gridContext;

  static BuildContext? maybeOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<OriginalGridContext>();

    return widget?.gridContext;
  }

  @override
  bool updateShouldNotify(OriginalGridContext oldWidget) =>
      oldWidget.gridContext != gridContext;
}

class ImageTagsNotifier extends InheritedWidget {
  const ImageTagsNotifier({
    super.key,
    required this.tags,
    required this.res,
    required super.child,
  });

  final List<ImageTag> tags;
  final ParsedFilenameResult? res;

  static List<ImageTag> of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<ImageTagsNotifier>();

    return widget!.tags;
  }

  static ParsedFilenameResult? resOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<ImageTagsNotifier>();

    return widget!.res;
  }

  @override
  bool updateShouldNotify(ImageTagsNotifier oldWidget) =>
      tags != oldWidget.tags || res != oldWidget.res;
}

class ImageTag {
  const ImageTag(
    this.tag, {
    required this.favorite,
    required this.excluded,
  });

  final String tag;
  final bool favorite;
  final bool excluded;
}

class _BottomSheetPopScope extends StatefulWidget {
  const _BottomSheetPopScope({
    required super.key,
    required this.controller,
    required this.animationController,
    required this.child,
  });

  final AnimationController animationController;
  final DraggableScrollableController controller;
  final Widget child;

  @override
  State<_BottomSheetPopScope> createState() => __BottomSheetPopScopeState();
}

class __BottomSheetPopScopeState extends State<_BottomSheetPopScope> {
  late final StreamSubscription<void>? subscription;

  bool ignorePointer = false;
  double currentPixels = -1;

  bool _isAppbarShown = true;

  void toggle() {
    final platformApi = PlatformApi.current();

    setState(() => _isAppbarShown = !_isAppbarShown);

    if (_isAppbarShown) {
      platformApi.setFullscreen(false);
      widget.animationController.reverse();
    } else {
      widget.animationController
          .forward()
          .then((value) => platformApi.setFullscreen(true));
    }
  }

  @override
  void initState() {
    super.initState();
    subscription = chooseGalleryPlug().galleryTapDownEvents?.listen((_) {
      toggle();
    });

    widget.controller.addListener(listener);
  }

  @override
  void dispose() {
    subscription?.cancel();
    widget.controller.removeListener(listener);

    super.dispose();
  }

  void listener() {
    if (widget.controller.pixels == currentPixels) {
      return;
    }

    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      try {
        setState(() {
          currentPixels = widget.controller.pixels;
        });
      } catch (_) {}
    });
  }

  void tryScroll(bool _, Object? __) {
    if (!_isAppbarShown) {
      toggle();
      return;
    }

    setState(() {
      ignorePointer = true;
    });

    widget.controller
        .animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Easing.emphasizedAccelerate,
        )
        .then(
          (value) => setState(() {
            ignorePointer = false;
            widget.controller.reset();
          }),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.isAttached) {
      return AppBarVisibilityNotifier(
        toggle: toggle,
        isShown: _isAppbarShown,
        child: widget.child,
      );
    }

    return PopScope(
      canPop: _isAppbarShown &&
          (currentPixels.isNegative || 0 == currentPixels.floorToDouble()),
      onPopInvokedWithResult: tryScroll,
      child: IgnorePointer(
        ignoring: ignorePointer,
        child: AppBarVisibilityNotifier(
          toggle: toggle,
          isShown: _isAppbarShown,
          child: widget.child,
        ),
      ),
    );
  }
}

class ReloadImageNotifier extends InheritedWidget {
  const ReloadImageNotifier({
    super.key,
    required this.reload,
    required super.child,
  });
  final void Function([bool refreshPalette]) reload;

  @override
  bool updateShouldNotify(ReloadImageNotifier oldWidget) {
    return reload != oldWidget.reload;
  }

  static void of(BuildContext context, [bool refreshPalette = false]) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<ReloadImageNotifier>();

    widget!.reload(refreshPalette);
  }
}

class PauseVideoNotifier extends InheritedWidget {
  const PauseVideoNotifier({
    super.key,
    required this.pause,
    required this.setPause,
    required super.child,
  });
  final void Function(bool) setPause;
  final bool pause;

  static bool of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<PauseVideoNotifier>();

    return widget!.pause;
  }

  static void maybePauseOf(BuildContext context, bool pause) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<PauseVideoNotifier>();

    widget?.setPause(pause);
  }

  @override
  bool updateShouldNotify(PauseVideoNotifier oldWidget) =>
      pause != oldWidget.pause;
}

class ImageViewInfoTilesRefreshNotifier extends InheritedWidget {
  const ImageViewInfoTilesRefreshNotifier({
    super.key,
    required this.count,
    required this.incr,
    required super.child,
  });

  final void Function() incr;
  final int count;

  static void refreshOf(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<
        ImageViewInfoTilesRefreshNotifier>();

    widget?.incr();
  }

  static int of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<
        ImageViewInfoTilesRefreshNotifier>();

    return widget!.count;
  }

  @override
  bool updateShouldNotify(ImageViewInfoTilesRefreshNotifier oldWidget) =>
      count != oldWidget.count;
}

class LoadingProgressNotifier extends InheritedWidget {
  const LoadingProgressNotifier({
    super.key,
    required this.progress,
    required super.child,
  });
  final double? progress;

  static double? of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<LoadingProgressNotifier>();

    return widget!.progress;
  }

  @override
  bool updateShouldNotify(LoadingProgressNotifier oldWidget) =>
      progress != oldWidget.progress;
}

class TagFilterNotifier extends InheritedWidget {
  const TagFilterNotifier({
    super.key,
    required this.data,
    required super.child,
  });
  final FilterNotifierData data;

  static FilterNotifierData? maybeOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<TagFilterNotifier>();

    return widget?.data;
  }

  @override
  bool updateShouldNotify(TagFilterNotifier oldWidget) =>
      data != oldWidget.data;
}

class FilterNotifierData {
  const FilterNotifierData(this.searchController, this.searchFocus);
  final TextEditingController searchController;
  final FocusNode searchFocus;

  void dispose() {
    searchController.dispose();
    searchFocus.dispose();
  }
}

class TagFilterValueNotifier extends InheritedNotifier<TextEditingController> {
  const TagFilterValueNotifier({
    super.key,
    required super.notifier,
    required super.child,
  });

  static String maybeOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<TagFilterValueNotifier>();
    return widget?.notifier?.value.text ?? "";
  }
}

class CurrentContentNotifier extends InheritedWidget {
  const CurrentContentNotifier({
    super.key,
    required this.content,
    required super.child,
  });

  final Contentable content;

  static Contentable of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<CurrentContentNotifier>();

    return widget!.content;
  }

  @override
  bool updateShouldNotify(CurrentContentNotifier oldWidget) =>
      content != oldWidget.content;
}

class AppBarVisibilityNotifier extends InheritedWidget {
  const AppBarVisibilityNotifier({
    super.key,
    required this.isShown,
    required this.toggle,
    required super.child,
  });

  final bool isShown;
  final void Function() toggle;

  static void toggleOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<AppBarVisibilityNotifier>();

    widget!.toggle();
  }

  static bool of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<AppBarVisibilityNotifier>();

    return widget!.isShown;
  }

  @override
  bool updateShouldNotify(AppBarVisibilityNotifier oldWidget) =>
      isShown != oldWidget.isShown || toggle != oldWidget.toggle;
}

class VideoControlsNotifier extends InheritedWidget {
  const VideoControlsNotifier({
    super.key,
    required this.controller,
    required super.child,
  });

  final VideoControlsController controller;

  static VideoControlsController of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<VideoControlsNotifier>();

    return widget!.controller;
  }

  @override
  bool updateShouldNotify(VideoControlsNotifier oldWidget) =>
      controller != oldWidget.controller;
}
