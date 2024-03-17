// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:developer';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_action_button.dart';
import 'package:gallery/src/widgets/image_view/mixins/loading_builder.dart';
import 'package:gallery/src/widgets/image_view/make_image_view_bindings.dart';
import 'package:gallery/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart';
import 'package:gallery/src/widgets/image_view/wrappers/wrap_image_view_skeleton.dart';
import 'package:gallery/src/widgets/image_view/wrappers/wrap_image_view_theme.dart';
import 'package:gallery/src/plugs/platform_fullscreens.dart';
import 'package:gallery/src/widgets/grid_frame/grid_frame.dart';
import 'package:gallery/src/widgets/notifiers/focus.dart';
import 'package:gallery/src/widgets/notifiers/image_view_info_tiles_refresh_notifier.dart';
import 'package:logging/logging.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../keybinds/keybind_description.dart';
import '../../interfaces/cell/cell.dart';
import '../keybinds/describe_keys.dart';
import 'body.dart';
import 'bottom_bar.dart';
import 'app_bar/end_drawer.dart';
import 'mixins/page_type.dart';
import 'mixins/palette.dart';

final Color kListTileColorInInfo = Colors.white60.withOpacity(0.8);

class ImageViewStatistics {
  final void Function() swiped;
  final void Function() viewed;

  const ImageViewStatistics({required this.swiped, required this.viewed});
}

class ImageView<T extends Cell> extends StatefulWidget {
  final int startingCell;
  final T? Function(int i) getCell;
  final int cellCount;
  final void Function(int post) scrollUntill;
  final void Function(double? pos, int? selectedCell) updateTagScrollPos;
  final Future<int> Function()? onNearEnd;
  final List<GridAction<T>> Function(T)? addIcons;
  final void Function(int i)? download;
  final double? infoScrollOffset;
  final Color systemOverlayRestoreColor;
  final void Function(ImageViewState<T> state)? pageChange;
  final void Function() onExit;
  final void Function() focusMain;

  final List<int>? predefinedIndexes;

  final InheritedWidget Function(Widget child)? registerNotifiers;

  final void Function()? onEmptyNotes;

  final ImageViewStatistics? statistics;

  final bool ignoreEndDrawer;

  final BuildContext? gridContext;

  final bool ignoreLoadingBuilder;
  final bool switchPageOnTapEdges;

  final List<Widget> appBarItems;
  final void Function()? onRightSwitchPageEnd;
  final void Function()? onLeftSwitchPageEnd;

  final String? overrideDrawerLabel;

  const ImageView({
    super.key,
    required this.updateTagScrollPos,
    required this.cellCount,
    required this.scrollUntill,
    required this.startingCell,
    required this.onExit,
    this.predefinedIndexes,
    this.appBarItems = const [],
    this.statistics,
    this.ignoreLoadingBuilder = false,
    required this.getCell,
    required this.onNearEnd,
    required this.focusMain,
    required this.systemOverlayRestoreColor,
    this.pageChange,
    this.overrideDrawerLabel,
    this.onEmptyNotes,
    this.infoScrollOffset,
    this.download,
    this.switchPageOnTapEdges = false,
    this.ignoreEndDrawer = false,
    this.registerNotifiers,
    this.addIcons,
    this.onRightSwitchPageEnd,
    this.onLeftSwitchPageEnd,
    this.gridContext,
  });

  @override
  State<ImageView<T>> createState() => ImageViewState<T>();
}

class ImageViewState<T extends Cell> extends State<ImageView<T>>
    with
        ImageViewPageTypeMixin<T>,
        ImageViewPaletteMixin<T>,
        ImageViewLoadingBuilderMixin<T> {
  final mainFocus = FocusNode();
  final GlobalKey<ScaffoldState> key = GlobalKey();
  final GlobalKey<WrapImageViewNotifiersState> wrapNotifiersKey = GlobalKey();
  final GlobalKey<WrapImageViewThemeState> wrapThemeKey = GlobalKey();

  late final ScrollController scrollController =
      ScrollController(initialScrollOffset: widget.infoScrollOffset ?? 0);

  late final PageController controller =
      PageController(initialPage: widget.startingCell);

  late final PlatformFullscreensPlug fullscreenPlug =
      choosePlatformFullscreenPlug(widget.systemOverlayRestoreColor);

  late int currentPage = widget.startingCell;
  late int cellCount = widget.cellCount;

  final noteTextController = TextEditingController();

  bool refreshing = false;

  Map<ShortcutActivator, void Function()>? bindings;

  int _incr = 0;

  @override
  void initState() {
    super.initState();

    widget.statistics?.viewed();

    WakelockPlus.enable();

    loadCells(currentPage, cellCount);

    WidgetsBinding.instance.scheduleFrameCallback((_) {
      if (widget.infoScrollOffset != null) {
        key.currentState?.openEndDrawer();
      }

      fullscreenPlug.setTitle(drawCell(currentPage).alias(true));
      _loadNext(widget.startingCell);
    });

    widget.updateTagScrollPos(null, widget.startingCell);

    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      final b = makeImageViewBindings(context, key, controller,
          download: widget.download == null
              ? null
              : () => widget.download!(currentPage),
          onTap: _onTap);
      bindings = {
        ...b,
        ...keybindDescription(context, describeKeys(b),
            AppLocalizations.of(context)!.imageViewPageName, widget.focusMain)
      };

      setState(() {});

      refreshPalette();
    });
  }

  @override
  void dispose() {
    fullscreenPlug.unfullscreen();

    WakelockPlus.disable();
    widget.updateTagScrollPos(null, null);
    controller.dispose();

    widget.onExit();

    scrollController.dispose();
    mainFocus.dispose();

    super.dispose();
  }

  void refreshPalette() {
    extractPalette(context, widget.getCell(currentPage)!, key, scrollController,
        currentPage, _resetAnimation);
  }

  void _resetAnimation() {
    wrapThemeKey.currentState?.resetAnimation();
  }

  void update(BuildContext? context, int count, {bool pop = true}) {
    if (count == 0) {
      if (pop) {
        key.currentState?.closeEndDrawer();
        Navigator.pop(context ?? this.context);
      }
      return;
    }

    cellCount = count;
    final prv = currentPage;
    currentPage = prv.clamp(0, count - 1);
    loadCells(currentPage, cellCount);
    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      refreshPalette();
    });

    setState(() {});
  }

  void _loadNext(int index) {
    if (index >= cellCount - 3 && !refreshing && widget.onNearEnd != null) {
      setState(() {
        refreshing = true;
      });
      widget.onNearEnd!().then((value) {
        if (context.mounted) {
          setState(() {
            refreshing = false;
            cellCount = value;
          });
        }
      }).onError((error, stackTrace) {
        log("loading next in the image view page",
            level: Level.WARNING.value, error: error, stackTrace: stackTrace);
      });
    }
  }

  void refreshImage() {
    refreshTries += 1;

    setState(() {});
  }

  void _onTap() {
    fullscreenPlug.fullscreen();
    wrapNotifiersKey.currentState?.toggle();
  }

  void _onTagRefresh() {
    try {
      setState(() {});
    } catch (_) {}
  }

  void _onPageChanged(int index) {
    widget.statistics?.viewed();
    widget.statistics?.swiped();

    refreshTries = 0;

    currentPage = index;
    widget.pageChange?.call(this);
    _loadNext(index);
    widget.updateTagScrollPos(null, index);

    widget.scrollUntill(index);

    loadCells(index, cellCount);

    final c = drawCell(index);

    fullscreenPlug.setTitle(c.alias(true));

    setState(() {
      extractPalette(context, widget.getCell(currentPage)!, key,
          scrollController, currentPage, _resetAnimation);
    });
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
      widget.onRightSwitchPageEnd?.call();
    }
  }

  void _onPressedLeft() {
    if (currentPage != 0 && cellCount != 1) {
      controller.previousPage(duration: 200.ms, curve: Easing.standard);
    } else {
      widget.onLeftSwitchPageEnd?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ImageViewInfoTilesRefreshNotifier(
      count: _incr,
      incr: _incrTiles,
      child: WrapImageViewNotifiers<T>(
        hardRefresh: refreshImage,
        mainFocus: mainFocus,
        gridContext: widget.gridContext,
        key: wrapNotifiersKey,
        onTagRefresh: _onTagRefresh,
        currentCell: drawCell(currentPage),
        registerNotifiers: widget.registerNotifiers,
        child: WrapImageViewTheme(
          key: wrapThemeKey,
          currentPalette: currentPalette,
          previousPallete: previousPallete,
          child: WrapImageViewSkeleton<T>(
              scaffoldKey: key,
              addAppBarActions: widget.appBarItems,
              bindings: bindings ?? {},
              currentPalette: currentPalette,
              endDrawer: widget.ignoreEndDrawer
                  ? null
                  : Builder(builder: (context) {
                      FocusNotifier.of(context);
                      ImageViewInfoTilesRefreshNotifier.of(context);

                      final addInfo =
                          drawCell(currentPage).contentInfo(context);

                      return addInfo == null
                          ? const Drawer(child: EmptyWidget(gridSeed: 0))
                          : ImageViewEndDrawer(
                              overrideDrawerLabel: widget.overrideDrawerLabel,
                              scrollController: scrollController,
                              sliver: addInfo,
                            );
                    }),
              bottomAppBar: widget.addIcons == null
                  ? null
                  : ImageViewBottomAppBar(
                      textController: noteTextController,
                      children: widget.addIcons
                              ?.call(drawCell(currentPage))
                              .map(
                                (e) => WrapGridActionButton(e.icon, () {
                                  e.onPress([drawCell(currentPage)]);
                                }, false,
                                    color: e.color,
                                    play: e.play,
                                    onLongPress: e.onLongPress == null
                                        ? null
                                        : () => e.onLongPress!(
                                            [drawCell(currentPage)]),
                                    backgroundColor: e.backgroundColor,
                                    animate: e.animate,
                                    showOnlyWhenSingle: false),
                              )
                              .toList() ??
                          const []),
              mainFocus: mainFocus,
              child: ImageViewBody(
                onPressedLeft:
                    widget.switchPageOnTapEdges ? _onPressedLeft : null,
                onPressedRight:
                    widget.switchPageOnTapEdges ? _onPressedRight : null,
                onPageChanged: _onPageChanged,
                onLongPress: _onLongPress,
                pageController: controller,
                notes: null,
                loadingBuilder: widget.ignoreLoadingBuilder
                    ? null
                    : (context, event, idx) => loadingBuilder(
                        context,
                        event,
                        idx,
                        currentPage,
                        wrapNotifiersKey,
                        currentPalette,
                        drawCell),
                itemCount: cellCount,
                onTap: _onTap,
                builder: galleryBuilder,
                decoration: BoxDecoration(
                  color: currentPalette?.mutedColor?.color
                      .harmonizeWith(Theme.of(context).colorScheme.primary)
                      .withOpacity(0.7),
                ),
              )),
        ),
      ),
    );
  }
}
