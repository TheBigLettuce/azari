// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/cell/contentable.dart';
import 'package:gallery/src/plugs/platform_fullscreens.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart';
import 'package:gallery/src/widgets/notifiers/app_bar_visibility.dart';
import 'package:gallery/src/widgets/notifiers/current_content.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/notifiers/loading_progress.dart';
import 'package:gallery/src/widgets/notifiers/pause_video.dart';
import 'package:gallery/src/widgets/notifiers/reload_image.dart';

import '../../notifiers/filter.dart';
import '../../notifiers/filter_value.dart';
import '../../notifiers/focus.dart';
import '../../notifiers/tag_refresh.dart';

class WrapImageViewNotifiers extends StatefulWidget {
  final void Function() onTagRefresh;
  final Contentable currentCell;
  final FocusNode mainFocus;
  final InheritedWidget Function(Widget child)? registerNotifiers;
  final void Function([bool refreshPalette]) hardRefresh;
  final BuildContext? gridContext;
  final AnimationController controller;
  final DraggableScrollableController bottomSheetController;

  final Widget child;

  const WrapImageViewNotifiers({
    super.key,
    required this.registerNotifiers,
    required this.onTagRefresh,
    required this.hardRefresh,
    required this.currentCell,
    required this.mainFocus,
    required this.controller,
    required this.bottomSheetController,
    required this.gridContext,
    required this.child,
  });

  @override
  State<WrapImageViewNotifiers> createState() => WrapImageViewNotifiersState();
}

class WrapImageViewNotifiersState extends State<WrapImageViewNotifiers> {
  bool _isAppbarShown = true;
  bool _isPaused = false;
  double? _loadingProgress = 1.0;

  bool _isTagsRefreshing = false;

  late final _searchData =
      FilterNotifierData(TextEditingController(), FocusNode());

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
                                      : widget
                                          .registerNotifiers!(widget.child)),
                            )),
                      )),
                )),
          )),
    );
  }
}

class OriginalGridContext extends InheritedWidget {
  final BuildContext gridContext;
  final SelectionGlue Function() generate;

  const OriginalGridContext({
    super.key,
    required this.gridContext,
    required this.generate,
    required super.child,
  });

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
