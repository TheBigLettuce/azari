// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/interfaces/cell/contentable.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_action_button.dart';
import 'package:gallery/src/widgets/image_view/mixins/loading_builder.dart';
import 'package:gallery/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart';
import 'package:gallery/src/widgets/image_view/wrappers/wrap_image_view_skeleton.dart';
import 'package:gallery/src/widgets/image_view/wrappers/wrap_image_view_theme.dart';
import 'package:gallery/src/plugs/platform_fullscreens.dart';
import 'package:gallery/src/widgets/grid_frame/grid_frame.dart';
import 'package:gallery/src/widgets/notifiers/focus.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/notifiers/image_view_info_tiles_refresh_notifier.dart';
import 'package:logging/logging.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../interfaces/cell/cell.dart';
import 'body.dart';
import 'bottom_bar.dart';
import 'app_bar/end_drawer.dart';
import 'mixins/page_type_mixin.dart';
import 'mixins/palette.dart';

final Color kListTileColorInInfo = Colors.white60.withOpacity(0.8);

class ImageViewStatistics {
  final void Function() swiped;
  final void Function() viewed;

  const ImageViewStatistics({required this.swiped, required this.viewed});
}

abstract interface class ImageViewContentable {
  Contentable content(BuildContext context);
}

class ImageViewDescription<T extends ContentableCell> {
  const ImageViewDescription({
    this.pageChangeImage,
    this.beforeImageViewRestore,
    this.onExitImageView,
    this.statistics,
    this.overrideDrawerLabel,
  });

  final void Function()? onExitImageView;

  final void Function()? beforeImageViewRestore;

  final ImageViewStatistics? statistics;

  /// Supplied to [ImageView.pageChange].
  final void Function(ImageViewState state)? pageChangeImage;

  final String? overrideDrawerLabel;
}

abstract interface class ContentableCell
    implements ImageViewContentable, CellBase {}

class ImageView extends StatefulWidget {
  final int startingCell;
  final Contentable? Function(BuildContext context, int i) getCell;
  final int cellCount;
  final void Function(int post) scrollUntill;
  final Future<int> Function()? onNearEnd;
  // final List<GridAction> Function(T)? addIcons;
  final void Function(int i)? download;
  // final double? infoScrollOffset;
  final Color systemOverlayRestoreColor;
  final void Function(ImageViewState state)? pageChange;
  final void Function() onExit;

  final InheritedWidget Function(Widget child)? registerNotifiers;

  final ImageViewStatistics? statistics;

  // final bool ignoreEndDrawer;

  final BuildContext? gridContext;

  final bool ignoreLoadingBuilder;

  // final List<Widget> appBarItems;
  final void Function()? onRightSwitchPageEnd;
  final void Function()? onLeftSwitchPageEnd;

  static Future<void> launchWrapped(
    BuildContext context,
    int cellCount,
    Contentable Function(BuildContext, int) cell,
    Color overlayColor, {
    int startingCell = 0,
    void Function(int)? download,
    Key? key,
  }) {
    return Navigator.push(context, MaterialPageRoute(
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
            systemOverlayRestoreColor: overlayColor,
          ),
        );
      },
    ));
  }

  static Future<void> defaultForGrid<T extends ContentableCell>(
    BuildContext gridContext,
    GridFunctionality<T> functionality,
    ImageViewDescription<T> imageDesctipion,
    int startingCell,
  ) {
    // state.widget.mainFocus.requestFocus();

    final overlayColor =
        Theme.of(gridContext).colorScheme.background.withOpacity(0.5);

    functionality.selectionGlue.hideNavBar(true);

    final getCell = CellProvider.of<T>(gridContext);

    return Navigator.of(gridContext, rootNavigator: true)
        .push(MaterialPageRoute(builder: (context) {
      return ImageView(
        gridContext: gridContext,
        statistics: imageDesctipion.statistics,
        registerNotifiers: functionality.registerNotifiers,
        systemOverlayRestoreColor: overlayColor,
        // overrideDrawerLabel: imageDesctipion.overrideDrawerLabel,
        scrollUntill: (_) {}, // TODO: change this
        pageChange: imageDesctipion.pageChangeImage,
        onExit: () {
          imageDesctipion.onExitImageView?.call();
        },
        getCell: (context, idx) => getCell(idx).content(context),
        cellCount: functionality.refreshingStatus.mutation.cellCount,
        download: functionality.download,
        startingCell: startingCell,
        onNearEnd: () =>
            functionality.refreshingStatus.onNearEnd(functionality),
      );
    })).then((value) {
      functionality.selectionGlue.hideNavBar(false);

      return value;
    });
  }

  const ImageView({
    super.key,
    required this.cellCount,
    required this.scrollUntill,
    required this.startingCell,
    required this.onExit,
    // this.appBarItems = const [],
    this.statistics,
    this.ignoreLoadingBuilder = false,
    required this.getCell,
    required this.onNearEnd,
    required this.systemOverlayRestoreColor,
    this.pageChange,
    // this.infoScrollOffset,
    this.download,
    // this.ignoreEndDrawer = false,
    this.registerNotifiers,
    this.onRightSwitchPageEnd,
    this.onLeftSwitchPageEnd,
    this.gridContext,
  });

  @override
  State<ImageView> createState() => ImageViewState();
}

class ImageViewState extends State<ImageView>
    with
        ImageViewPageTypeMixin,
        ImageViewPaletteMixin,
        ImageViewLoadingBuilderMixin {
  final mainFocus = FocusNode();
  final GlobalKey<ScaffoldState> key = GlobalKey();
  final GlobalKey<WrapImageViewNotifiersState> wrapNotifiersKey = GlobalKey();
  final GlobalKey<WrapImageViewThemeState> wrapThemeKey = GlobalKey();

  final scrollController = ScrollController();

  late final PageController controller =
      PageController(initialPage: widget.startingCell);

  late final PlatformFullscreensPlug fullscreenPlug =
      choosePlatformFullscreenPlug(widget.systemOverlayRestoreColor);

  late int currentPage = widget.startingCell;
  late int cellCount = widget.cellCount;

  final noteTextController = TextEditingController();

  bool refreshing = false;

  int _incr = 0;

  @override
  void initState() {
    super.initState();

    widget.statistics?.viewed();

    WakelockPlus.enable();

    loadCells(currentPage, cellCount);

    WidgetsBinding.instance.scheduleFrameCallback((_) {
      fullscreenPlug.setTitle(drawCell(currentPage).widgets.title(context));
      _loadNext(widget.startingCell);
    });

    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      refreshPalette();
    });
  }

  @override
  void dispose() {
    fullscreenPlug.unfullscreen();

    WakelockPlus.disable();
    controller.dispose();

    widget.onExit();

    scrollController.dispose();
    mainFocus.dispose();

    super.dispose();
  }

  void refreshPalette() {
    extractPalette(
      context,
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

  void update(BuildContext? context, int count) {
    if (count <= 0) {
      key.currentState?.closeEndDrawer();
      Navigator.pop(context ?? this.context);

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

  void refreshImage([bool refreshPalette = false]) {
    refreshTries += 1;

    if (refreshPalette) {
      this.refreshPalette();
    }

    setState(() {});
  }

  void _onTap() {
    wrapNotifiersKey.currentState?.toggle();
    fullscreenPlug.fullscreen();
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

    widget.scrollUntill(index);

    loadCells(index, cellCount);

    final c = drawCell(index);

    fullscreenPlug.setTitle(c.widgets.title(context));

    refreshPalette();

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
      child: WrapImageViewNotifiers(
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
          child: WrapImageViewSkeleton(
              scaffoldKey: key,
              // addAppBarActions:
              // drawCell(currentPage).widgets.appBarButtons(context),
              currentPalette: currentPalette,
              endDrawer: Builder(builder: (context) {
                FocusNotifier.of(context);
                ImageViewInfoTilesRefreshNotifier.of(context);

                final widgets = drawCell(currentPage).widgets;
                final info = widgets.info(context);
                // final icons = widgets.appBarButtons(context);

                return info == null
                    ? const Drawer(child: EmptyWidget(gridSeed: 0))
                    : ImageViewEndDrawer(
                        scrollController: scrollController,
                        sliver: info,
                      );
              }),
              bottomAppBar: ImageViewBottomAppBar(
                textController: noteTextController,
                children: drawCell(currentPage)
                    .widgets
                    .actions(context)
                    .map(
                      (e) => WrapGridActionButton(
                        e.icon,
                        () {
                          e.onPress(drawCell(currentPage));
                        },
                        false,
                        play: e.play,
                        color: e.color,
                        onLongPress: null,
                        animate: e.animate,
                        showOnlyWhenSingle: false,
                      ),
                    )
                    .toList(),
              ),
              mainFocus: mainFocus,
              child: ImageViewBody(
                onPressedLeft: _onPressedLeft,
                onPressedRight: _onPressedRight,
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
                          drawCell,
                        ),
                itemCount: cellCount,
                onTap: _onTap,
                builder: galleryBuilder,
              )),
        ),
      ),
    );
  }
}
