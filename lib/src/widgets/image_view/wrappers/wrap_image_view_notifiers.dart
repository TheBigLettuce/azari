// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:gallery/src/db/tags/post_tags.dart";
import "package:gallery/src/interfaces/cell/contentable.dart";
import "package:gallery/src/plugs/platform_fullscreens.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/notifiers/app_bar_visibility.dart";
import "package:gallery/src/widgets/notifiers/current_content.dart";
import "package:gallery/src/widgets/notifiers/filter.dart";
import "package:gallery/src/widgets/notifiers/filter_value.dart";
import "package:gallery/src/widgets/notifiers/focus.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:gallery/src/widgets/notifiers/loading_progress.dart";
import "package:gallery/src/widgets/notifiers/pause_video.dart";
import "package:gallery/src/widgets/notifiers/reload_image.dart";
import "package:gallery/src/widgets/notifiers/tag_refresh.dart";

class WrapImageViewNotifiers extends StatefulWidget {
  const WrapImageViewNotifiers({
    super.key,
    required this.registerNotifiers,
    required this.onTagRefresh,
    required this.hardRefresh,
    required this.currentCell,
    required this.tags,
    required this.watchTags,
    required this.mainFocus,
    required this.controller,
    required this.bottomSheetController,
    required this.gridContext,
    required this.child,
  });
  final void Function() onTagRefresh;
  final Contentable currentCell;
  final FocusNode mainFocus;
  final InheritedWidget Function(Widget child)? registerNotifiers;
  final void Function([bool refreshPalette]) hardRefresh;
  final BuildContext? gridContext;
  final AnimationController controller;
  final DraggableScrollableController bottomSheetController;
  final List<ImageTag> Function(Contentable)? tags;
  final StreamSubscription<List<ImageTag>> Function(
    Contentable,
    void Function(List<ImageTag> l),
  )? watchTags;

  final Widget child;

  @override
  State<WrapImageViewNotifiers> createState() => WrapImageViewNotifiersState();
}

class WrapImageViewNotifiersState extends State<WrapImageViewNotifiers> {
  bool _isAppbarShown = true;
  bool _isPaused = false;
  double? _loadingProgress = 1;

  bool _isTagsRefreshing = false;

  late final _searchData =
      FilterNotifierData(TextEditingController(), FocusNode());

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchData.dispose();

    super.dispose();
  }

  void toggle(PlatformFullscreensPlug plug) {
    setState(() => _isAppbarShown = !_isAppbarShown);

    if (_isAppbarShown) {
      plug.unfullscreen();
      widget.controller.reverse();
    } else {
      widget.controller.forward().then((value) => plug.fullscreen());
    }
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
      generate: GlueProvider.generateOf(widget.gridContext ?? context),
      gridContext: widget.gridContext ?? context,
      child: _TagWatchers(
        key: ValueKey(widget.currentCell),
        tags: widget.tags,
        watchTags: widget.watchTags,
        currentCell: widget.currentCell,
        child: ReloadImageNotifier(
          reload: widget.hardRefresh,
          child: PauseVideoNotifier(
            setPause: _setPause,
            pause: _isPaused,
            child: TagRefreshNotifier(
              isRefreshing: _isTagsRefreshing,
              setIsRefreshing: (b) {
                _isTagsRefreshing = b;

                try {
                  setState(() {});
                } catch (_) {}
              },
              notify: widget.onTagRefresh,
              child: FilterValueNotifier(
                notifier: _searchData.searchController,
                child: FilterNotifier(
                  data: _searchData,
                  child: FocusNotifier(
                    notifier: _searchData.searchFocus,
                    focusMain: widget.mainFocus.requestFocus,
                    child: CurrentContentNotifier(
                      content: widget.currentCell,
                      child: LoadingProgressNotifier(
                        progress: _loadingProgress,
                        child: AppBarVisibilityNotifier(
                          isShown: _isAppbarShown,
                          child: widget.registerNotifiers == null
                              ? widget.child
                              : widget.registerNotifiers!(
                                  widget.child,
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
      ),
    );
  }
}

class _TagWatchers extends StatefulWidget {
  const _TagWatchers({
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
  State<_TagWatchers> createState() => __TagWatchersState();
}

class __TagWatchersState extends State<_TagWatchers> {
  late final StreamSubscription<List<ImageTag>>? tagWatcher;
  late final DisassembleResult? res;

  List<ImageTag> tags = [];

  @override
  void initState() {
    super.initState();

    res = DisassembleResult.fromFilename(widget.currentCell.widgets.alias(true))
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
    required this.generate,
    required super.child,
  });
  final BuildContext gridContext;
  final SelectionGlue Function() generate;

  static BuildContext? maybeOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<OriginalGridContext>();

    return widget?.gridContext;
  }

  static SelectionGlue Function()? generateOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<OriginalGridContext>();

    return widget?.generate;
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
  final DisassembleResult? res;

  static List<ImageTag> of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<ImageTagsNotifier>();

    return widget!.tags;
  }

  static DisassembleResult? resOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<ImageTagsNotifier>();

    return widget!.res;
  }

  @override
  bool updateShouldNotify(ImageTagsNotifier oldWidget) =>
      tags != oldWidget.tags || res != oldWidget.res;
}

class ImageTag {
  const ImageTag(this.tag, this.favorite);

  final String tag;
  final bool favorite;
}
