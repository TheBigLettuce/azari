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
import 'package:gallery/src/db/schemas/note.dart';
import 'package:gallery/src/widgets/image_view/loading_builder.dart';
import 'package:gallery/src/widgets/image_view/make_image_view_bindings.dart';
import 'package:gallery/src/widgets/image_view/wrap_image_view_notifiers.dart';
import 'package:gallery/src/widgets/image_view/wrap_image_view_skeleton.dart';
import 'package:gallery/src/widgets/image_view/wrap_theme.dart';
import 'package:gallery/src/plugs/platform_fullscreens.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:logging/logging.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../widgets/keybinds/keybind_description.dart';
import '../widgets/notifiers/filter.dart';
import '../interfaces/cell.dart';
import '../interfaces/contentable.dart';
import '../widgets/keybinds/describe_keys.dart';
import '../widgets/image_view/app_bar.dart';
import '../widgets/image_view/body.dart';
import '../widgets/image_view/bottom_bar.dart';
import '../widgets/image_view/end_drawer.dart';
import '../widgets/image_view/notes_mixin.dart';
import '../widgets/image_view/page_type_mixin.dart';
import '../widgets/image_view/palette_mixin.dart';
import '../widgets/image_view/note_list.dart';
import '../widgets/image_view/notes_container.dart';

final Color kListTileColorInInfo = Colors.white60.withOpacity(0.8);

class NoteInterface<T extends Cell> {
  final void Function(
      String text, T cell, Color? backgroundColor, Color? textColor) addNote;
  final NoteBase? Function(T cell) load;
  final void Function(T cell, int indx, String newCell) replace;
  final void Function(T cell, int indx) delete;
  final void Function(T cell, int from, int to) reorder;

  const NoteInterface(
      {required this.addNote,
      required this.delete,
      required this.load,
      required this.replace,
      required this.reorder});
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

  const ImageView(
      {super.key,
      required this.updateTagScrollPos,
      required this.cellCount,
      required this.scrollUntill,
      required this.startingCell,
      required this.onExit,
      this.predefinedIndexes,
      required this.getCell,
      required this.onNearEnd,
      required this.focusMain,
      this.noteInterface,
      required this.systemOverlayRestoreColor,
      this.pageChange,
      this.onEmptyNotes,
      this.infoScrollOffset,
      this.download,
      this.registerNotifiers,
      this.addIcons});

  @override
  State<ImageView<T>> createState() => ImageViewState<T>();
}

class ImageViewState<T extends Cell> extends State<ImageView<T>>
    with
        SingleTickerProviderStateMixin,
        ImageViewPageTypeMixin<T>,
        ImageViewNotesMixin<T>,
        ImageViewPaletteMixin<T>,
        ImageViewLoadingBuilderMixin<T> {
  final mainFocus = FocusNode();
  final GlobalKey<ScaffoldState> key = GlobalKey();

  late final ScrollController scrollController =
      ScrollController(initialScrollOffset: widget.infoScrollOffset ?? 0);

  late final PageController controller =
      PageController(initialPage: widget.startingCell);

  late final AnimationController _animationController =
      AnimationController(vsync: this, duration: 200.ms);

  late final searchData = FilterNotifierData(() {
    mainFocus.requestFocus();
  }, TextEditingController(), FocusNode());

  late final PlatformFullscreensPlug fullscreenPlug =
      choosePlatformFullscreenPlug(widget.systemOverlayRestoreColor);

  late T currentCell;
  late int currentPage = widget.startingCell;
  late int cellCount = widget.cellCount;

  bool refreshing = false;
  bool isAppbarShown = true;

  Map<ShortcutActivator, void Function()>? bindings;

  @override
  void initState() {
    super.initState();
    _animationController.addListener(() {
      setState(() {});
    });

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

    loadNotes(currentCell);

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

      extractPalette(context, currentCell, key, scrollController, currentPage,
          _animationController);
    });
  }

  @override
  void dispose() {
    fullscreenPlug.unfullscreen();

    WakelockPlus.disable();
    widget.updateTagScrollPos(null, null);
    controller.dispose();
    _animationController.dispose();
    searchData.dispose();

    widget.onExit();

    scrollController.dispose();

    disposeNotes();

    super.dispose();
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
      controller.previousPage(duration: 200.ms, curve: Curves.linearToEaseOut);

      currentCell = newCell;
      hardRefresh();
    } else if (currentPage > cellCount - 1) {
      controller.previousPage(duration: 200.ms, curve: Curves.linearToEaseOut);
    } else if (widget
            .getCell(currentPage)
            .getCellData(false, context: context)
            .thumb !=
        currentCell.getCellData(false, context: context).thumb) {
      if (currentPage == 0) {
        controller.nextPage(
            duration: 200.ms, curve: Curves.fastLinearToSlowEaseIn);
      } else {
        controller.previousPage(
            duration: 200.ms, curve: Curves.linearToEaseOut);
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
    setState(() => isAppbarShown = !isAppbarShown);
  }

  void _onTagRefresh() {
    try {
      setState(() {});
    } catch (_) {}
  }

  void _onPop(bool pop) {
    if (extendNotes) {
      setState(() {
        extendNotes = false;
      });
    }
  }

  void _onPageChanged(int index) {
    extendNotes = false;
    currentPage = index;
    widget.pageChange?.call(this);
    _loadNext(index);
    widget.updateTagScrollPos(null, index);

    widget.scrollUntill(index);

    final c = widget.getCell(index);

    fullscreenPlug.setTitle(c.alias(true));

    setState(() {
      currentCell = c;
      loadNotes(currentCell);

      extractPalette(context, currentCell, key, scrollController, currentPage,
          _animationController);
    });
  }

  void _onLongPress() {
    if (widget.download == null) {
      return;
    }

    HapticFeedback.vibrate();
    widget.download!(currentPage);
  }

  @override
  Widget build(BuildContext context) {
    return WrapImageViewNotifiers<T>(
      filterData: searchData,
      onTagRefresh: _onTagRefresh,
      appBarShown: isAppbarShown,
      progress: loadingProgress ?? 1.0,
      currentCell: currentCell,
      notesExtended: extendNotes,
      registerNotifiers: widget.registerNotifiers,
      child: WrapTheme(
        currentPalette: currentPalette,
        previousPallete: previousPallete,
        animationValue: _animationController.value,
        child: WrapImageViewSkeleton(
            scaffoldKey: key,
            bindings: bindings ?? {},
            appBar: PreferredSize(
                preferredSize: currentStickers == null
                    ? const Size.fromHeight(kToolbarHeight + 4)
                    : const Size.fromHeight(kToolbarHeight + 36 + 4),
                child: ImageViewAppBar(
                  title: currentCell.alias(false),
                  stickers: currentStickers ?? const [],
                  actions: addButtons ?? const [],
                )),
            endDrawer: addInfo == null || addInfo!.isEmpty
                ? null
                : ImageViewEndDrawer(
                    scrollController: scrollController,
                    children: addInfo!,
                  ),
            bottomAppBar: ImageViewBottomAppBar(
                textController: noteTextController,
                addNote: () => addNote(currentCell, currentPalette),
                showAddNoteButton: widget.noteInterface != null,
                children: widget.addIcons
                        ?.call(currentCell)
                        .map(
                          (e) => WrapGridActionButton(e.icon, () {
                            e.onPress([currentCell]);
                          }, false, "",
                              followColorTheme: true,
                              color: e.color,
                              play: e.play,
                              backgroundColor: e.backgroundColor,
                              animate: e.animate),
                        )
                        .toList() ??
                    const []),
            canPop: !extendNotes,
            mainFocus: mainFocus,
            onPopInvoked: _onPop,
            child: ImageViewBody(
              onPageChanged: _onPageChanged,
              onLongPress: _onLongPress,
              pageController: controller,
              notes: widget.noteInterface == null ||
                      noteKeys == null ||
                      notes == null
                  ? null
                  : NotesContainer(
                      expandNotes: onExpandNotes,
                      backgroundColor: currentPalette?.dominantColor?.color
                              .harmonizeWith(
                                  Theme.of(context).colorScheme.primary)
                              .withOpacity(extendNotes ? 0.95 : 0.5) ??
                          Colors.black.withOpacity(extendNotes ? 0.95 : 0.5),
                      child: NoteList<NoteBase>(
                        controller: notesScrollController,
                        noteKeys: noteKeys!,
                        notes: notes!,
                        onDismissed: onNoteDismissed,
                        onReorder: onNoteReorder,
                        onReplace: onNoteReplace,
                        onSave: onNoteSave,
                        textController: noteTextController,
                      )),
              loadingBuilder: (context, event, idx) => loadingBuilder(
                  context, event, idx, currentPage, currentPalette),
              itemCount: cellCount,
              onTap: _onTap,
              builder: galleryBuilder,
              decoration: BoxDecoration(
                color: ColorTween(
                  begin: previousPallete?.mutedColor?.color
                      .harmonizeWith(Theme.of(context).colorScheme.primary)
                      .withOpacity(0.7),
                  end: currentPalette?.mutedColor?.color
                      .harmonizeWith(Theme.of(context).colorScheme.primary)
                      .withOpacity(0.7),
                ).transform(_animationController.value),
              ),
            )),
      ),
    );
  }
}
