// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view.dart";
import "package:azari/src/ui/material/widgets/image_view/video/player_widget_controller.dart";
import "package:flutter/material.dart";

class ImageViewNotifiers extends StatelessWidget {
  const ImageViewNotifiers({
    super.key,
    required this.stateController,
    required this.controller,
    required this.videoControls,
    required this.pauseVideoState,
    required this.flipShowAppBar,
    required this.loader,
    required this.child,
  });

  final Stream<void> flipShowAppBar;

  final ImageViewLoader loader;

  final AnimationController controller;
  final PauseVideoState pauseVideoState;
  final PlayerWidgetController videoControls;
  final ImageViewStateController stateController;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ImageViewWidgetsHolder(
      loader: loader,
      child: ImageViewLoaderProvider(
        loader: loader,
        child: ImageViewTagsProvider(
          loader: loader,
          child: PauseVideoNotifierHolder(
            state: pauseVideoState,
            child: PlayerWidgetControllerNotifier(
              controller: videoControls,
              child: _AppBarShownHolder(
                flipShowAppBar: flipShowAppBar,
                animationController: controller,
                child: child,
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
    required this.loader,
    required this.child,
  });

  final ImageViewLoader loader;

  final Widget child;

  @override
  State<ImageViewTagsProvider> createState() => _ImageViewTagsProviderState();
}

class _ImageViewTagsProviderState extends State<ImageViewTagsProvider>
    with ImageViewLoaderWatcher {
  @override
  ImageViewLoader get loader => widget.loader;

  @override
  void onNewCount(int newCount) {
    _watchTags(_index);

    setState(() {});
  }

  @override
  void onNewIndex(int newIndex) {
    if (_index == newIndex) {
      return;
    }

    _index = newIndex;

    _watchTags(_index);

    setState(() {});
  }

  StreamSubscription<void>? tagWatcher;
  final tags = ImageViewTags();

  late int _index;

  @override
  void initState() {
    super.initState();

    _index = widget.loader.index;

    _watchTags(_index);
  }

  @override
  void dispose() {
    tags.dispose();
    tagWatcher?.cancel();

    super.dispose();
  }

  void _watchTags(int idx) {
    tagWatcher?.cancel();
    tagWatcher = widget.loader.tagsEventsFor(idx).listen((_) {
      final newTags = <ImageTag>[];
      final tags = widget.loader.tagsFor(idx);

      newTags.addAll(
        tags.where((element) => element.type == ImageTagType.favorite),
      );
      newTags.addAll(
        tags.where((element) => element.type != ImageTagType.favorite),
      );

      this.tags.update(newTags);
    });

    final t = widget.loader.tagsFor(idx);
    tags.update(
      t
          .where((element) => element.type == ImageTagType.favorite)
          .followedBy(
            t.where((element) => element.type != ImageTagType.favorite),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ImageTagsNotifier(tags: tags, child: widget.child);
  }
}

class ImageViewWidgetsHolder extends StatefulWidget {
  const ImageViewWidgetsHolder({
    super.key,
    required this.loader,
    required this.child,
  });

  final ImageViewLoader loader;

  final Widget child;

  @override
  State<ImageViewWidgetsHolder> createState() => _ImageViewWidgetsHolderState();
}

class _ImageViewWidgetsHolderState extends State<ImageViewWidgetsHolder>
    with ImageViewLoaderWatcher {
  @override
  ImageViewLoader get loader => widget.loader;

  @override
  Widget build(BuildContext context) {
    return ImageViewWidgetsNotifier(
      widgets: loader.get(loader.index),
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

class ImageViewLoaderProvider extends InheritedWidget {
  const ImageViewLoaderProvider({
    super.key,
    required this.loader,
    required super.child,
  });

  final ImageViewLoader loader;

  static ImageViewLoader of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<ImageViewLoaderProvider>();

    return widget!.loader;
  }

  @override
  bool updateShouldNotify(ImageViewLoaderProvider oldWidget) =>
      oldWidget.loader != loader;
}

class ImageViewTags {
  ImageViewTags();

  List<ImageTag> _list = const [];

  final _stream = StreamController<void>.broadcast();
  Stream<void> get stream => _stream.stream;

  List<ImageTag> get list => _list;

  void update(List<ImageTag> list) {
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
    final widget = context
        .dependOnInheritedWidgetOfExactType<ImageTagsNotifier>();

    return widget!.tags;
  }

  @override
  bool updateShouldNotify(ImageTagsNotifier oldWidget) =>
      tags != oldWidget.tags;
}

enum ImageTagType { favorite, excluded, normal }

class ImageTag {
  const ImageTag(
    this.tag, {
    required this.type,
    required this.onTap,
    required this.onLongTap,
  });

  final String tag;

  final ImageTagType type;
  final ContextCallback? onTap;
  final ContextCallback? onLongTap;
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
    setState(() => _isAppbarShown = setTo ?? !_isAppbarShown);

    if (_isAppbarShown) {
      const WindowApi().setFullscreen(false);
      widget.animationController.reverse();
    } else {
      widget.animationController.forward().then(
        (value) => const WindowApi().setFullscreen(true),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    subscription = GalleryApi.safe()?.events.tapDown?.listen((_) {
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

// class ReloadImageNotifier extends InheritedWidget {
//   const ReloadImageNotifier({
//     super.key,
//     required this.reload,
//     required super.child,
//   });

//   final VoidCallback reload;

//   @override
//   bool updateShouldNotify(ReloadImageNotifier oldWidget) {
//     return reload != oldWidget.reload;
//   }

//   static void of(BuildContext context) {
//     final widget =
//         context.dependOnInheritedWidgetOfExactType<ReloadImageNotifier>();

//     widget!.reload();
//   }
// }

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
    final widget = context
        .dependOnInheritedWidgetOfExactType<PauseVideoNotifier>();

    return widget!.state;
  }

  static bool of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<PauseVideoNotifier>();

    return widget!.pause;
  }

  static void maybePauseOf(BuildContext context, bool pause) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<PauseVideoNotifier>();

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
    final widget = context
        .dependOnInheritedWidgetOfExactType<
          ImageViewInfoTilesRefreshNotifier
        >();

    widget?.incr();
  }

  static int of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<
          ImageViewInfoTilesRefreshNotifier
        >();

    return widget!.count;
  }

  @override
  bool updateShouldNotify(ImageViewInfoTilesRefreshNotifier oldWidget) =>
      count != oldWidget.count;
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
    final widget = context
        .dependOnInheritedWidgetOfExactType<AppBarVisibilityNotifier>();

    widget?.toggle(setTo);
  }

  static bool? maybeOf(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<AppBarVisibilityNotifier>();

    return widget?.isShown;
  }

  static bool of(BuildContext context) => maybeOf(context)!;

  @override
  bool updateShouldNotify(AppBarVisibilityNotifier oldWidget) =>
      isShown != oldWidget.isShown || toggle != oldWidget.toggle;
}

class PlayerWidgetControllerNotifier extends InheritedWidget {
  const PlayerWidgetControllerNotifier({
    super.key,
    required this.controller,
    required super.child,
  });

  final PlayerWidgetController controller;

  static PlayerWidgetController of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<PlayerWidgetControllerNotifier>();

    return widget!.controller;
  }

  @override
  bool updateShouldNotify(PlayerWidgetControllerNotifier oldWidget) =>
      controller != oldWidget.controller;
}

class ImageViewWidgetsNotifier extends InheritedWidget {
  const ImageViewWidgetsNotifier({
    super.key,
    required this.widgets,
    required super.child,
  });

  final ImageViewWidgets? widgets;

  static ImageViewWidgets? of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<ImageViewWidgetsNotifier>();

    return widget?.widgets;
  }

  @override
  bool updateShouldNotify(ImageViewWidgetsNotifier oldWidget) =>
      widgets != oldWidget.widgets;
}
