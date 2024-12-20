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
import "package:azari/src/widgets/image_view/video/video_controls_controller.dart";
import "package:flutter/material.dart";

class ImageViewNotifiers extends StatefulWidget {
  const ImageViewNotifiers({
    super.key,
    required this.stateController,
    required this.controller,
    required this.videoControls,
    required this.pauseVideoState,
    required this.flipShowAppBar,
    required this.child,
  });

  final Stream<void> flipShowAppBar;

  final AnimationController controller;
  final PauseVideoState pauseVideoState;
  final VideoControlsController videoControls;
  final ImageViewStateController stateController;

  final Widget child;

  @override
  State<ImageViewNotifiers> createState() => _ImageViewNotifiersState();
}

class _ImageViewNotifiersState extends State<ImageViewNotifiers> {
  ImageViewStateController get stateController => widget.stateController;
  int get currentIndex => stateController.currentIndex;

  late final _searchData =
      FilterNotifierData(TextEditingController(), FocusNode());

  @override
  void dispose() {
    _searchData.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return stateController.injectMetadataProvider(
      ReloadImageNotifier(
        reload: stateController.refreshImage,
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
                  child: _AppBarShownHolder(
                    flipShowAppBar: widget.flipShowAppBar,
                    animationController: widget.controller,
                    child: widget.child,
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

class ImageViewTagsProvider extends StatefulWidget {
  const ImageViewTagsProvider({
    super.key,
    required this.currentPage,
    required this.watchTags,
    required this.tags,
    required this.currentCell,
    required this.child,
  });

  final Stream<int> currentPage;

  final WatchTagsCallback? watchTags;

  final List<ImageTag> Function(ContentWidgets)? tags;
  final (ContentWidgets, int) Function() currentCell;

  final Widget child;

  @override
  State<ImageViewTagsProvider> createState() => _ImageViewTagsProviderState();
}

class _ImageViewTagsProviderState extends State<ImageViewTagsProvider> {
  StreamSubscription<List<ImageTag>>? tagWatcher;
  final tags = ImageViewTags();

  late final StreamSubscription<int> subscr;
  late ContentWidgets content;
  late int currentCell;

  // late final _cellStream = StreamController<ContentWidgets>.broadcast();

  @override
  void initState() {
    super.initState();
    final (c, cc) = widget.currentCell();
    content = c;
    currentCell = cc;

    _watchTags(content);

    subscr = widget.currentPage.listen((i) {
      final (c, cc) = widget.currentCell();
      content = c;
      currentCell = cc;

      // _cellStream.add(c);
      _watchTags(content);

      setState(() {});
    });
  }

  @override
  void dispose() {
    tags.dispose();
    subscr.cancel();
    tagWatcher?.cancel();

    super.dispose();
  }

  void _watchTags(ContentWidgets content) {
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
      content.alias(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ImageTagsNotifier(
      tags: tags,
      child: widget.child,
    );
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
      state: widget.state,
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
    // super.key,
    required this.animationController,
    required this.flipShowAppBar,
    required this.child,
  });

  final Stream<void> flipShowAppBar;

  final AnimationController animationController;

  final Widget child;

  @override
  State<_AppBarShownHolder> createState() => _AppBarShownHolderState();
}

class _AppBarShownHolderState extends State<_AppBarShownHolder> {
  late final StreamSubscription<void>? subscription;
  late final StreamSubscription<void> _flipShowAppBar;

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

    _flipShowAppBar = widget.flipShowAppBar.listen((_) {
      toggle(null);
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    _flipShowAppBar.cancel();

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
    required this.state,
    required this.pause,
    required this.setPause,
    required super.child,
  });

  final PauseVideoState state;

  final bool pause;

  final void Function(bool) setPause;

  static PauseVideoState stateOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<PauseVideoNotifier>();

    return widget!.state;
  }

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
      pause != oldWidget.pause || state != oldWidget.state;
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
