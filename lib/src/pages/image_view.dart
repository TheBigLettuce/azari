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
import 'package:gallery/src/interfaces/note_interface.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/grid/wrap_grid_action_button.dart';
import 'package:gallery/src/widgets/image_view/loading_builder.dart';
import 'package:gallery/src/widgets/image_view/make_image_view_bindings.dart';
import 'package:gallery/src/widgets/image_view/wrap_image_view_notifiers.dart';
import 'package:gallery/src/widgets/image_view/wrap_image_view_skeleton.dart';
import 'package:gallery/src/widgets/image_view/wrap_image_view_theme.dart';
import 'package:gallery/src/plugs/platform_fullscreens.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/notifiers/focus.dart';
import 'package:gallery/src/widgets/notifiers/image_view_info_tiles_refresh_notifier.dart';
import 'package:logging/logging.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../widgets/keybinds/keybind_description.dart';
import '../interfaces/cell/cell.dart';
import '../interfaces/cell/contentable.dart';
import '../widgets/keybinds/describe_keys.dart';
import '../widgets/image_view/body.dart';
import '../widgets/image_view/bottom_bar.dart';
import '../widgets/image_view/end_drawer.dart';
import '../widgets/image_view/page_type_mixin.dart';
import '../widgets/image_view/palette_mixin.dart';
import '../widgets/image_view/note_list.dart';

final Color kListTileColorInInfo = Colors.white60.withOpacity(0.8);

class ImageViewStatistics {
  final void Function() swiped;
  final void Function() viewed;

  const ImageViewStatistics({required this.swiped, required this.viewed});
}

class ImageView<T extends Cell> extends StatefulWidget {
  final int startingCell;
  final T Function(int i) getCell;
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

  final NoteInterface<T>? noteInterface;
  final void Function()? onEmptyNotes;

  final ImageViewStatistics? statistics;

  final bool ignoreEndDrawer;

  const ImageView(
      {super.key,
      required this.updateTagScrollPos,
      required this.cellCount,
      required this.scrollUntill,
      required this.startingCell,
      required this.onExit,
      this.predefinedIndexes,
      this.statistics,
      required this.getCell,
      required this.onNearEnd,
      required this.focusMain,
      this.noteInterface,
      required this.systemOverlayRestoreColor,
      this.pageChange,
      this.onEmptyNotes,
      this.infoScrollOffset,
      this.download,
      this.ignoreEndDrawer = false,
      this.registerNotifiers,
      this.addIcons});

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
  final GlobalKey<NoteListState> noteListKey = GlobalKey();

  late final ScrollController scrollController =
      ScrollController(initialScrollOffset: widget.infoScrollOffset ?? 0);

  late final PageController controller =
      PageController(initialPage: widget.startingCell);

  late final PlatformFullscreensPlug fullscreenPlug =
      choosePlatformFullscreenPlug(widget.systemOverlayRestoreColor);

  late T currentCell;
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

    WidgetsBinding.instance.scheduleFrameCallback((_) {
      if (widget.infoScrollOffset != null) {
        key.currentState?.openEndDrawer();
      }

      fullscreenPlug.setTitle(currentCell.alias(true));
      _loadNext(widget.startingCell);
    });

    currentCell = widget.getCell(widget.startingCell);

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

      noteListKey.currentState?.loadNotes(currentCell);

      setState(() {});

      extractPalette(context, currentCell, key, scrollController, currentPage,
          _resetAnimation);
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
    extractPalette(context, currentCell, key, scrollController, currentPage,
        _resetAnimation);
  }

  void _resetAnimation() {
    wrapThemeKey.currentState?.resetAnimation();
  }

  void hardRefresh() {
    fakeProvider = MemoryImage(kTransparentImage);

    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        fakeProvider = null;
      });
    });
  }

  void refreshImage() {
    var i = currentCell.fileDisplay();
    if (i is NetImage) {
      PaintingBinding.instance.imageCache.evict(i.provider);

      hardRefresh();
    }
  }

  void update(BuildContext context, int count, {bool pop = true}) {
    if (count == 0) {
      if (pop) {
        key.currentState?.closeEndDrawer();
        Navigator.pop(context);
      }
      return;
    }

    cellCount = count;

    if (cellCount == 1) {
      final newCell = widget.getCell(0);
      if (newCell.isarId == currentCell.isarId) {
        return;
      }
      controller.previousPage(duration: 200.ms, curve: Easing.standard);

      currentCell = newCell;
      hardRefresh();
    } else if (currentPage > cellCount - 1) {
      controller.previousPage(duration: 200.ms, curve: Easing.standard);
    } else if (widget
            .getCell(currentPage)
            .getCellData(false, context: context)
            .thumb !=
        currentCell.getCellData(false, context: context).thumb) {
      if (currentPage == 0) {
        controller.nextPage(duration: 200.ms, curve: Easing.standard);
      } else {
        controller.previousPage(duration: 200.ms, curve: Easing.standard);
      }
    } else {
      currentCell = widget.getCell(currentPage);
    }

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

    noteListKey.currentState?.unextendNotes();
    currentPage = index;
    widget.pageChange?.call(this);
    _loadNext(index);
    widget.updateTagScrollPos(null, index);

    widget.scrollUntill(index);

    final c = widget.getCell(index);

    fullscreenPlug.setTitle(c.alias(true));

    setState(() {
      currentCell = c;
      noteListKey.currentState?.loadNotes(currentCell);

      extractPalette(context, currentCell, key, scrollController, currentPage,
          _resetAnimation);
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

  @override
  Widget build(BuildContext context) {
    return ImageViewInfoTilesRefreshNotifier(
      count: _incr,
      incr: _incrTiles,
      child: WrapImageViewNotifiers<T>(
        hardRefresh: hardRefresh,
        mainFocus: mainFocus,
        key: wrapNotifiersKey,
        onTagRefresh: _onTagRefresh,
        currentCell: currentCell,
        registerNotifiers: widget.registerNotifiers,
        child: WrapImageViewTheme(
          key: wrapThemeKey,
          currentPalette: currentPalette,
          previousPallete: previousPallete,
          child: WrapImageViewSkeleton<T>(
              scaffoldKey: key,
              bindings: bindings ?? {},
              currentPalette: currentPalette,
              endDrawer: widget.ignoreEndDrawer
                  ? null
                  : Builder(builder: (context) {
                      FocusNotifier.of(context);
                      ImageViewInfoTilesRefreshNotifier.of(context);

                      final addInfo = currentCell.addInfo(context, () {
                        widget.updateTagScrollPos(
                            scrollController.offset, currentPage);
                      },
                          AddInfoColorData(
                            borderColor:
                                Theme.of(context).colorScheme.outlineVariant,
                            foregroundColor: currentPalette
                                    ?.mutedColor?.bodyTextColor
                                    .harmonizeWith(Theme.of(context)
                                        .colorScheme
                                        .primary) ??
                                kListTileColorInInfo,
                            systemOverlayColor:
                                widget.systemOverlayRestoreColor,
                          ));

                      return addInfo == null || addInfo.isEmpty
                          ? const Drawer(child: EmptyWidget())
                          : ImageViewEndDrawer(
                              scrollController: scrollController,
                              children: addInfo,
                            );
                    }),
              bottomAppBar: ImageViewBottomAppBar(
                  textController: noteTextController,
                  addNote: () => noteListKey.currentState
                      ?.addNote(currentCell, currentPalette),
                  showAddNoteButton: widget.noteInterface != null,
                  children: widget.addIcons
                          ?.call(currentCell)
                          .map(
                            (e) => WrapGridActionButton(e.icon, () {
                              e.onPress([currentCell]);
                            }, false,
                                followColorTheme: true,
                                color: e.color,
                                play: e.play,
                                onLongPress: e.onLongPress == null
                                    ? null
                                    : () => e.onLongPress!([currentCell]),
                                backgroundColor: e.backgroundColor,
                                animate: e.animate,
                                showOnlyWhenSingle: false),
                          )
                          .toList() ??
                      const []),
              mainFocus: mainFocus,
              child: ImageViewBody(
                onPageChanged: _onPageChanged,
                onLongPress: _onLongPress,
                pageController: controller,
                notes: widget.noteInterface == null
                    ? null
                    : NoteList<T>(
                        key: noteListKey,
                        noteInterface: widget.noteInterface!,
                        onEmptyNotes: widget.onEmptyNotes,
                        backgroundColor: currentPalette?.dominantColor?.color
                                .harmonizeWith(
                                    Theme.of(context).colorScheme.primary) ??
                            Colors.black,
                      ),
                loadingBuilder: (context, event, idx) => loadingBuilder(context,
                    event, idx, currentPage, wrapNotifiersKey, currentPalette),
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
