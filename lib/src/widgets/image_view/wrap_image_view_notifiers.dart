// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/grid/selection_glue.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/notifiers/app_bar_visibility.dart';
import 'package:gallery/src/widgets/notifiers/current_cell.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/notifiers/loading_progress.dart';
import 'package:gallery/src/widgets/notifiers/pause_video.dart';
import 'package:gallery/src/widgets/notifiers/reload_image.dart';

import '../../interfaces/cell/cell.dart';
import '../notifiers/filter.dart';
import '../notifiers/filter_value.dart';
import '../notifiers/focus.dart';
import '../notifiers/tag_refresh.dart';

class WrapImageViewNotifiers<T extends Cell> extends StatefulWidget {
  final void Function() onTagRefresh;
  final T currentCell;
  final FocusNode mainFocus;
  final InheritedWidget Function(Widget child)? registerNotifiers;
  final void Function() hardRefresh;
  final Widget child;
  final BuildContext? gridContext;

  const WrapImageViewNotifiers({
    super.key,
    required this.registerNotifiers,
    required this.onTagRefresh,
    required this.hardRefresh,
    required this.currentCell,
    required this.mainFocus,
    required this.gridContext,
    required this.child,
  });

  @override
  State<WrapImageViewNotifiers<T>> createState() =>
      WrapImageViewNotifiersState<T>();
}

class WrapImageViewNotifiersState<T extends Cell>
    extends State<WrapImageViewNotifiers<T>> {
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

  void toggle() {
    setState(() => _isAppbarShown = !_isAppbarShown);
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

  SelectionGlue<J> _generate<J extends Cell>() =>
      GlueProvider.generateOf<T, J>(widget.gridContext ?? context);

  @override
  Widget build(BuildContext context) {
    return OriginalGridContext(
      generate: _generate,
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
                        child: CurrentCellNotifier(
                            cell: widget.currentCell,
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
  final SelectionGlue<J> Function<J extends Cell>() generate;

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

  static SelectionGlue<T> Function<T extends Cell>()? generateOf(
      BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<OriginalGridContext>();

    return widget?.generate;
  }

  @override
  bool updateShouldNotify(OriginalGridContext oldWidget) =>
      oldWidget.gridContext != gridContext;
}
