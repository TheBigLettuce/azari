// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/post_tags.dart";
import "package:azari/src/platform/gallery_api.dart";
import "package:azari/src/platform/platform_api.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/focus_notifier.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:azari/src/widgets/image_view/image_view.dart";
import "package:azari/src/widgets/image_view/mixins/page_type_mixin.dart";
import "package:azari/src/widgets/image_view/video/video_controls_controller.dart";
import "package:flutter/material.dart";

class ImageViewNotifiers extends StatefulWidget {
  const ImageViewNotifiers({
    super.key,
    required this.hardRefresh,
    required this.currentPage,
    required this.page,
    required this.tags,
    required this.watchTags,
    required this.mainFocus,
    required this.controller,
    required this.gridContext,
    required this.videoControls,
    required this.wrapNotifiers,
    required this.pauseVideoState,
    required this.child,
  });

  final ImageViewPageTypeMixin page;
  final Stream<int> currentPage;
  final FocusNode mainFocus;
  final BuildContext? gridContext;
  final AnimationController controller;
  final PauseVideoState pauseVideoState;
  final VideoControlsController videoControls;

  final WatchTagsCallback? watchTags;
  final NotifierWrapper? wrapNotifiers;

  final VoidCallback hardRefresh;
  final List<ImageTag> Function(Contentable)? tags;

  final Widget child;

  @override
  State<ImageViewNotifiers> createState() => ImageViewNotifiersState();
}

class ImageViewNotifiersState extends State<ImageViewNotifiers> {
  final _bottomSheetKey = GlobalKey<_AppBarShownHolderState>();

  StreamSubscription<List<ImageTag>>? tagWatcher;
  final tags = ImageViewTags();

  late final StreamSubscription<int> subscr;
  late Contentable content;
  late int currentCell;

  late final _cellStream = StreamController<Contentable>.broadcast();

  double? _loadingProgress = 1;

  late final _searchData =
      FilterNotifierData(TextEditingController(), FocusNode());

  void toggle() => _bottomSheetKey.currentState?.toggle(null);

  @override
  void initState() {
    super.initState();
    final (c, cc) = widget.page.currentCell();
    content = c;
    currentCell = cc;

    _watchTags(content);

    subscr = widget.currentPage.listen((i) {
      final (c, cc) = widget.page.currentCell();
      content = c;
      currentCell = cc;

      _cellStream.add(c);
      _watchTags(content);

      setState(() {});
    });
  }

  @override
  void dispose() {
    _cellStream.close();
    tags.dispose();
    tagWatcher?.cancel();
    subscr.cancel();
    _searchData.dispose();

    super.dispose();
  }

  void _watchTags(Contentable content) {
    tagWatcher?.cancel();
    tagWatcher = widget.watchTags?.call(content, (t) {
      final newTags = <ImageTag>[];

      newTags.addAll(t.where((element) => element.favorite));
      newTags.addAll(t.where((element) => !element.favorite));

      tags.update(newTags, null);
    });

    final t = widget.tags?.call(content);
    tags.update(
      t == null
          ? const []
          : t
              .where((element) => element.favorite)
              .followedBy(t.where((element) => !element.favorite))
              .toList(),
      content.widgets.alias(true),
    );
  }

  void setLoadingProgress(double? progress) {
    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      try {
        setState(() => _loadingProgress = progress);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = OriginalGridContext(
      gridContext: widget.gridContext ?? context,
      child: ImageTagsNotifier(
        tags: tags,
        child: ReloadImageNotifier(
          reload: widget.hardRefresh,
          child: PauseVideoNotifierHolder(
            state: widget.pauseVideoState,
            child: VideoControlsNotifier(
              controller: widget.videoControls,
              child: TagFilterValueNotifier(
                notifier: _searchData.searchController,
                child: TagFilterNotifier(
                  data: _searchData,
                  child: FocusNotifier(
                    notifier: _searchData.searchFocus,
                    child: CurrentContentNotifier(
                      stream: _cellStream.stream,
                      content: content,
                      child: LoadingProgressNotifier(
                        progress: _loadingProgress,
                        child: _AppBarShownHolder(
                          key: _bottomSheetKey,
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

    if (widget.wrapNotifiers != null) {
      return widget.wrapNotifiers!(child);
    }

    return child;
  }
}

class PauseVideoNotifierHolder extends StatefulWidget {
  const PauseVideoNotifierHolder({
    super.key,
    required this.state,
    required this.child,
  });

  final PauseVideoState state;

  final Widget child;

  @override
  State<PauseVideoNotifierHolder> createState() =>
      _PauseVideoNotifierHolderState();
}

class _PauseVideoNotifierHolderState extends State<PauseVideoNotifierHolder> {
  late final StreamSubscription<void> _events;

  @override
  void initState() {
    super.initState();

    _events = widget.state.events.listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _events.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PauseVideoNotifier(
      pause: widget.state.isPaused,
      setPause: widget.state.setIsPaused,
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

class ImageViewTags {
  ImageViewTags();

  List<ImageTag> _list = const [];
  ParsedFilenameResult? _res;

  final _stream = StreamController<void>.broadcast();
  Stream<void> get stream => _stream.stream;

  List<ImageTag> get list => _list;
  ParsedFilenameResult? get res => _res;

  void update(List<ImageTag> list, String? filename) {
    if (filename != null) {
      _res = ParsedFilenameResult.fromFilename(filename).maybeValue();
    }
    _list = list;

    _stream.add(null);
  }

  void dispose() => _stream.close();
}

class ImageTagsNotifier extends InheritedWidget {
  const ImageTagsNotifier({
    super.key,
    required this.tags,
    required super.child,
  });

  final ImageViewTags tags;

  static ImageViewTags of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<ImageTagsNotifier>();

    return widget!.tags;
  }

  @override
  bool updateShouldNotify(ImageTagsNotifier oldWidget) =>
      tags != oldWidget.tags;
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

class _AppBarShownHolder extends StatefulWidget {
  const _AppBarShownHolder({
    required super.key,
    required this.animationController,
    required this.child,
  });

  final AnimationController animationController;

  final Widget child;

  @override
  State<_AppBarShownHolder> createState() => _AppBarShownHolderState();
}

class _AppBarShownHolderState extends State<_AppBarShownHolder> {
  late final StreamSubscription<void>? subscription;

  bool ignorePointer = false;

  bool _isAppbarShown = true;

  void toggle(bool? setTo) {
    final platformApi = PlatformApi();

    setState(() => _isAppbarShown = setTo ?? !_isAppbarShown);

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
    subscription = GalleryApi().events.tapDown?.listen((_) {
      toggle(null);
    });
  }

  @override
  void dispose() {
    subscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBarVisibilityNotifier(
      toggle: toggle,
      isShown: _isAppbarShown,
      child: widget.child,
    );
  }
}

class ReloadImageNotifier extends InheritedWidget {
  const ReloadImageNotifier({
    super.key,
    required this.reload,
    required super.child,
  });

  final VoidCallback reload;

  @override
  bool updateShouldNotify(ReloadImageNotifier oldWidget) {
    return reload != oldWidget.reload;
  }

  static void of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<ReloadImageNotifier>();

    widget!.reload();
  }
}

class PauseVideoNotifier extends InheritedWidget {
  const PauseVideoNotifier({
    super.key,
    required this.pause,
    required this.setPause,
    required super.child,
  });

  final bool pause;

  final void Function(bool) setPause;

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

  final int count;

  final VoidCallback incr;

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
  const FilterNotifierData(
    this.searchController,
    this.searchFocus,
  );

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
    required this.stream,
    required this.content,
    required super.child,
  });

  final Contentable content;
  final Stream<Contentable> stream;

  static Contentable? maybeOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<CurrentContentNotifier>();

    return widget?.content;
  }

  static Contentable of(BuildContext context) => maybeOf(context)!;

  static Stream<Contentable> streamOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<CurrentContentNotifier>();

    return widget!.stream;
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

  final void Function(bool? setTo) toggle;

  static void maybeToggleOf(BuildContext context, [bool? setTo]) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<AppBarVisibilityNotifier>();

    widget?.toggle(setTo);
  }

  static bool? maybeOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<AppBarVisibilityNotifier>();

    return widget?.isShown;
  }

  static bool of(BuildContext context) => maybeOf(context)!;

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
