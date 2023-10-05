// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/main.dart';
import 'package:gallery/src/plugs/platform_fullscreens.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/gesture_dead_zones.dart';
import 'package:gallery/src/widgets/grid/sticker.dart';
import 'package:logging/logging.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../widgets/keybinds/keybind_description.dart';
import '../widgets/keybinds/single_activator_description.dart';
import '../widgets/notifiers/filter.dart';
import '../widgets/notifiers/filter_value.dart';
import '../widgets/notifiers/focus.dart';
import '../widgets/notifiers/tag_refresh.dart';
import '../interfaces/cell.dart';
import '../interfaces/contentable.dart';
import '../widgets/skeletons/drawer/end_drawer_heading.dart';
import '../widgets/keybinds/describe_keys.dart';
import '../widgets/video/photo_gallery_page_video.dart';

final Color kListTileColorInInfo = Colors.white60.withOpacity(0.8);

class ImageView<T extends Cell> extends StatefulWidget {
  final int startingCell;
  final T Function(int i) getCell;
  final int cellCount;
  final void Function(int post) scrollUntill;
  final void Function(double? pos, int? selectedCell) updateTagScrollPos;
  final Future<int> Function()? onNearEnd;
  final List<GridBottomSheetAction<T>> Function(T)? addIcons;
  final void Function(int i)? download;
  final double? infoScrollOffset;
  final Color systemOverlayRestoreColor;
  final void Function(ImageViewState<T> state)? pageChange;
  final void Function() onExit;
  final void Function() focusMain;

  final List<int>? predefinedIndexes;

  final List<InheritedWidget Function(Widget)>? registerNotifiers;

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
      required this.systemOverlayRestoreColor,
      this.pageChange,
      this.infoScrollOffset,
      this.download,
      this.registerNotifiers,
      this.addIcons});

  @override
  State<ImageView<T>> createState() => ImageViewState<T>();
}

class ImageViewState<T extends Cell> extends State<ImageView<T>>
    with SingleTickerProviderStateMixin {
  late PageController controller;
  late T currentCell;
  late int currentPage = widget.startingCell;
  late ScrollController scrollController;
  late int cellCount = widget.cellCount;
  bool refreshing = false;
  final mainFocus = FocusNode();

  ImageProvider? fakeProvider;

  PhotoViewController? currentPageController;

  final GlobalKey<ScaffoldState> key = GlobalKey();

  final _finalizer = Finalizer<PhotoViewController>((controller) {
    try {
      controller.dispose();
    } catch (_) {}
  });

  PaletteGenerator? currentPalette;
  PaletteGenerator? previousPallete;

  late final AnimationController _animationController =
      AnimationController(vsync: this, duration: 200.ms);

  late final searchData = FilterNotifierData(() {
    mainFocus.requestFocus();
  }, TextEditingController(), FocusNode());

  bool isAppbarShown = true;

  late PlatformFullscreensPlug fullscreenPlug =
      choosePlatformFullscreenPlug(widget.systemOverlayRestoreColor);

  void _extractPalette() {
    final t = currentCell.getCellData(false).thumb;
    if (t == null) {
      return;
    }

    PaletteGenerator.fromImageProvider(t).then((value) {
      setState(() {
        previousPallete = currentPalette;
        currentPalette = value;
        // _animationController.reset();
        _animationController.forward(from: 0);
      });
    }).onError((error, stackTrace) {
      log("making palette for image_view",
          level: Level.SEVERE.value, error: error, stackTrace: stackTrace);
    });
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

  void update(int count, {bool pop = true}) {
    if (count == 0) {
      if (pop) {
        key.currentState?.closeEndDrawer();
        Navigator.pop(context);
      }
      return;
    }

    cellCount = count;

    if (cellCount == 1) {
      controller.previousPage(duration: 200.ms, curve: Curves.linearToEaseOut);

      currentCell = widget.getCell(0);
    } else if (currentPage > cellCount - 1) {
      controller.previousPage(duration: 200.ms, curve: Curves.linearToEaseOut);
    } else if (widget.getCell(currentPage).getCellData(false).thumb !=
        currentCell.getCellData(false).thumb) {
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

  @override
  void initState() {
    super.initState();
    _animationController.addListener(() {
      setState(() {});
    });

    WakelockPlus.enable();

    scrollController =
        ScrollController(initialScrollOffset: widget.infoScrollOffset ?? 0);

    WidgetsBinding.instance.scheduleFrameCallback((_) {
      if (widget.infoScrollOffset != null) {
        key.currentState?.openEndDrawer();
      }

      fullscreenPlug.setTitle(currentCell.alias(true));
      _loadNext(widget.startingCell);
    });

    currentCell = widget.getCell(widget.startingCell);
    controller = PageController(initialPage: widget.startingCell);

    widget.updateTagScrollPos(null, widget.startingCell);

    _extractPalette();
  }

  @override
  void dispose() {
    fullscreenPlug.unFullscreen();

    WakelockPlus.disable();
    widget.updateTagScrollPos(null, null);
    controller.dispose();
    _animationController.dispose();
    searchData.dispose();

    widget.onExit();

    currentPageController?.dispose();

    super.dispose();
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

  Map<SingleActivatorDescription, Null Function()> _makeBindings(
          BuildContext context) =>
      {
        SingleActivatorDescription(AppLocalizations.of(context)!.back,
            const SingleActivator(LogicalKeyboardKey.escape)): () {
          if (key.currentState?.isEndDrawerOpen ?? false) {
            key.currentState?.closeEndDrawer();
          } else {
            Navigator.pop(context);
          }
        },
        SingleActivatorDescription(
            AppLocalizations.of(context)!.moveImageRight,
            const SingleActivator(LogicalKeyboardKey.arrowRight,
                shift: true)): () {
          final pos = currentPageController?.position;

          if (pos != null) {
            currentPageController?.position = pos.translate(-40, 0);
          }
        },
        SingleActivatorDescription(
            AppLocalizations.of(context)!.moveImageLeft,
            const SingleActivator(LogicalKeyboardKey.arrowLeft,
                shift: true)): () {
          final pos = currentPageController?.position;

          if (pos != null) {
            currentPageController?.position = pos.translate(40, 0);
          }
        },
        SingleActivatorDescription(
            AppLocalizations.of(context)!.rotateImageRight,
            const SingleActivator(LogicalKeyboardKey.arrowRight,
                control: true)): () {
          currentPageController?.rotation -= 0.5;
        },
        SingleActivatorDescription(
            AppLocalizations.of(context)!.rotateImageLeft,
            const SingleActivator(LogicalKeyboardKey.arrowLeft,
                control: true)): () {
          currentPageController?.rotation += 0.5;
        },
        SingleActivatorDescription(AppLocalizations.of(context)!.moveImageUp,
            const SingleActivator(LogicalKeyboardKey.arrowUp)): () {
          final pos = currentPageController?.position;

          if (pos != null) {
            currentPageController?.position = pos.translate(0, 40);
          }
        },
        SingleActivatorDescription(AppLocalizations.of(context)!.moveImageDown,
            const SingleActivator(LogicalKeyboardKey.arrowDown)): () {
          final pos = currentPageController?.position;

          if (pos != null) {
            currentPageController?.position = pos.translate(0, -40);
          }
        },
        SingleActivatorDescription(AppLocalizations.of(context)!.zoomImageIn,
            const SingleActivator(LogicalKeyboardKey.pageUp)): () {
          final s = currentPageController?.scale;

          if (s != null && s < 2.5) {
            currentPageController?.scale = s + 0.5;
          }
        },
        SingleActivatorDescription(AppLocalizations.of(context)!.zoomImageOut,
            const SingleActivator(LogicalKeyboardKey.pageDown)): () {
          final s = currentPageController?.scale;

          if (s != null && s > 0.2) {
            currentPageController?.scale = s - 0.25;
          }
        },
        SingleActivatorDescription(AppLocalizations.of(context)!.showImageInfo,
            const SingleActivator(LogicalKeyboardKey.keyI, control: true)): () {
          if (key.currentState != null) {
            if (key.currentState!.isEndDrawerOpen) {
              key.currentState?.closeEndDrawer();
            } else {
              key.currentState?.openEndDrawer();
            }
          }
        },
        SingleActivatorDescription(AppLocalizations.of(context)!.downloadImage,
            const SingleActivator(LogicalKeyboardKey.keyD, control: true)): () {
          if (widget.download != null) {
            widget.download!(currentPage);
          }
        },
        SingleActivatorDescription(AppLocalizations.of(context)!.hideAppBar,
                const SingleActivator(LogicalKeyboardKey.space, control: true)):
            () {
          _onTap();
        },
        SingleActivatorDescription(AppLocalizations.of(context)!.nextImage,
            const SingleActivator(LogicalKeyboardKey.arrowRight)): () {
          controller.nextPage(duration: 500.milliseconds, curve: Curves.linear);
        },
        SingleActivatorDescription(AppLocalizations.of(context)!.previousImage,
            const SingleActivator(LogicalKeyboardKey.arrowLeft)): () {
          controller.previousPage(
              duration: 500.milliseconds, curve: Curves.linear);
        }
      };

  PhotoViewGalleryPageOptions _makeVideo(String uri, bool local) =>
      PhotoViewGalleryPageOptions.customChild(
          disableGestures: true,
          tightMode: true,
          child: Platform.isLinux
              ? const Center(child: Icon(Icons.error_outline))
              : PhotoGalleryPageVideo(
                  url: uri,
                  localVideo: local,
                  loadingColor: ColorTween(
                              begin: previousPallete?.dominantColor?.color,
                              end: currentPalette?.dominantColor?.color)
                          .transform(_animationController.value) ??
                      Colors.black,
                  backgroundColor: ColorTween(
                              begin: previousPallete?.mutedColor?.color
                                  .withOpacity(0.7),
                              end: currentPalette?.mutedColor?.color
                                  .withOpacity(0.7))
                          .transform(_animationController.value) ??
                      Theme.of(context).colorScheme.primary,
                ));

  PhotoViewGalleryPageOptions _makeNetImage(ImageProvider provider) {
    final options = PhotoViewGalleryPageOptions(
        minScale: PhotoViewComputedScale.contained * 0.8,
        maxScale: PhotoViewComputedScale.covered * 1.8,
        initialScale: PhotoViewComputedScale.contained,
        controller: Platform.isLinux ? PhotoViewController() : null,
        filterQuality: FilterQuality.high,
        imageProvider: fakeProvider ?? provider);

    if (options.controller != null) {
      _finalizer.attach(provider, options.controller!);
    }

    return options;
  }

  PhotoViewGalleryPageOptions _makeAndroidImage(
          Size size, String uri, bool isGif) =>
      PhotoViewGalleryPageOptions.customChild(
          gestureDetectorBehavior: HitTestBehavior.translucent,
          disableGestures: true,
          filterQuality: FilterQuality.high,
          child: Center(
            child: SizedBox(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: AspectRatio(
                  aspectRatio: MediaQuery.of(context).size.aspectRatio,
                  child: InteractiveViewer(
                    trackpadScrollCausesScale: true,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: size.aspectRatio == 0
                            ? MediaQuery.of(context).size.aspectRatio
                            : size.aspectRatio,
                        child: fakeProvider != null
                            ? Image(image: fakeProvider!)
                            : AndroidView(
                                viewType: "imageview",
                                hitTestBehavior:
                                    PlatformViewHitTestBehavior.transparent,
                                creationParams: {
                                  "uri": uri,
                                  if (isGif) "gif": "",
                                },
                                creationParamsCodec:
                                    const StandardMessageCodec(),
                              ),
                      ),
                    ),
                  ),
                )),
          ));

  PreferredSizeWidget _makeAppBar(BuildContext context) {
    final s = currentCell.addStickers(context);
    final b = currentCell.addButtons(context);
    final size = s == null
        ? AppBar().preferredSize
        : Size.fromHeight(AppBar().preferredSize.height + 36);

    return PreferredSize(
      preferredSize: size,
      child: IgnorePointer(
        ignoring: !isAppbarShown,
        child: Column(
          children: [
            AppBar(
              automaticallyImplyLeading: false,
              foregroundColor: ColorTween(
                begin: previousPallete?.dominantColor?.bodyTextColor
                        .withOpacity(0.8) ??
                    kListTileColorInInfo,
                end: currentPalette?.dominantColor?.bodyTextColor
                        .withOpacity(0.8) ??
                    kListTileColorInInfo,
              ).transform(_animationController.value),
              backgroundColor: ColorTween(
                begin: previousPallete?.dominantColor?.color.withOpacity(0.5) ??
                    Colors.black.withOpacity(0.5),
                end: currentPalette?.dominantColor?.color.withOpacity(0.5) ??
                    Colors.black.withOpacity(0.5),
              ).transform(_animationController.value),
              leading: const BackButton(),
              title: GestureDetector(
                onLongPress: () {
                  Clipboard.setData(
                      ClipboardData(text: currentCell.alias(false)));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text(AppLocalizations.of(context)!.copiedClipboard)));
                },
                child: Text(currentCell.alias(false)),
              ),
              actions: [
                if (b != null) ...b,
                IconButton(
                    onPressed: () {
                      key.currentState?.openEndDrawer();
                    },
                    icon: const Icon(Icons.info_outline))
              ],
            ),
            if (s != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  children: s
                      .map((e) => Sticker.widget(
                            context,
                            Sticker(e.$1,
                                color: ColorTween(
                                  begin: previousPallete
                                          ?.dominantColor?.bodyTextColor
                                          .withOpacity(0.8) ??
                                      kListTileColorInInfo,
                                  end: currentPalette
                                          ?.dominantColor?.bodyTextColor
                                          .withOpacity(0.8) ??
                                      kListTileColorInInfo,
                                ).transform(_animationController.value),
                                backgroundColor: ColorTween(
                                  begin: previousPallete?.dominantColor?.color
                                          .withOpacity(0.5) ??
                                      Colors.black.withOpacity(0.5),
                                  end: currentPalette?.dominantColor?.color
                                          .withOpacity(0.5) ??
                                      Colors.black.withOpacity(0.5),
                                ).transform(_animationController.value)),
                            onPressed: e.$2,
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ).animate(
        effects: [FadeEffect(begin: 1, end: 0, duration: 500.milliseconds)],
        autoPlay: false,
        target: isAppbarShown ? 0 : 1,
      ),
    );
  }

  Widget? _makeBottomSheet(BuildContext context) {
    if (!isAppbarShown) {
      return null;
    }

    final items = widget.addIcons!(currentCell);

    return Theme(
        data: Theme.of(context).copyWith(
          iconButtonTheme: IconButtonThemeData(
              style: ButtonStyle(
                  shape: const MaterialStatePropertyAll(RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.all(Radius.elliptical(10, 10)))),
                  backgroundColor: MaterialStatePropertyAll(ColorTween(
                          begin: previousPallete?.dominantColor?.color
                                  .withOpacity(0.5) ??
                              Colors.black.withOpacity(0.5),
                          end: currentPalette?.dominantColor?.color
                                  .withOpacity(0.5) ??
                              Colors.black.withOpacity(0.5))
                      .transform(_animationController.value)))),
        ),
        child: SizedBox.fromSize(
          size: Size.fromHeight(
              kToolbarHeight + MediaQuery.viewPaddingOf(context).bottom),
          child: Center(
              child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.viewPaddingOf(context).bottom),
            child: Wrap(
              spacing: 4,
              children: items
                  .map(
                    (e) => WrapSheetButton(e.icon, () {
                      e.onPress([currentCell]);
                    }, false, "", e.explanation,
                        followColorTheme: true,
                        color: e.color,
                        play: e.play,
                        backgroundColor: e.backgroundColor,
                        animate: e.animate),
                  )
                  .toList(),
            ),
          )),
        ));
  }

  Widget _wrapNotifiers(Widget Function(BuildContext context) f) {
    return TagRefreshNotifier(
        notify: () {
          try {
            setState(() {});
          } catch (_) {}
        },
        child: FilterValueNotifier(
            notifier: searchData.searchController,
            child: FilterNotifier(
              data: searchData,
              child: FocusNotifier(
                  notifier: searchData.searchFocus,
                  focusMain: () {
                    mainFocus.requestFocus();
                  },
                  child: Builder(
                    builder: f,
                  )),
            )));
  }

  Widget _makeEndDrawer(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);

    return Drawer(
      backgroundColor: ColorTween(
              begin: previousPallete?.mutedColor?.color.withOpacity(0.85) ??
                  Theme.of(context).colorScheme.surface.withOpacity(0.5),
              end: currentPalette?.mutedColor?.color.withOpacity(0.85) ??
                  Theme.of(context).colorScheme.surface.withOpacity(0.5))
          .transform(_animationController.value),
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          endDrawerHeading(
              context, AppLocalizations.of(context)!.infoHeadline, key,
              titleColor: ColorTween(
                      begin: previousPallete?.dominantColor?.titleTextColor ??
                          Theme.of(context)
                              .colorScheme
                              .surface
                              .withOpacity(0.5),
                      end: currentPalette?.dominantColor?.titleTextColor ??
                          Theme.of(context)
                              .colorScheme
                              .surface
                              .withOpacity(0.5))
                  .transform(_animationController.value),
              backroundColor: ColorTween(
                      begin: previousPallete?.dominantColor?.color
                              .withOpacity(0.5) ??
                          Theme.of(context)
                              .colorScheme
                              .surface
                              .withOpacity(0.5),
                      end: currentPalette?.dominantColor?.color.withOpacity(0.5) ??
                          Theme.of(context).colorScheme.surface.withOpacity(0.5))
                  .transform(_animationController.value)),
          _wrapNotifiers((context) {
            final addInfo = currentCell.addInfo(context, () {
              widget.updateTagScrollPos(scrollController.offset, currentPage);
            },
                AddInfoColorData(
                  borderColor: Theme.of(context).colorScheme.outlineVariant,
                  foregroundColor: ColorTween(
                          begin: previousPallete?.mutedColor?.bodyTextColor ??
                              kListTileColorInInfo,
                          end: currentPalette?.mutedColor?.bodyTextColor ??
                              kListTileColorInInfo)
                      .transform(_animationController.value)!,
                  systemOverlayColor: widget.systemOverlayRestoreColor,
                ));

            return Theme(
              data: Theme.of(context).copyWith(
                  hintColor: ColorTween(
                          begin: previousPallete?.mutedColor?.bodyTextColor ??
                              kListTileColorInInfo,
                          end: currentPalette?.mutedColor?.bodyTextColor ??
                              kListTileColorInInfo)
                      .transform(_animationController.value)),
              child: SliverPadding(
                padding: EdgeInsets.only(
                    bottom: insets.bottom +
                        MediaQuery.of(context).viewPadding.bottom),
                sliver: SliverList.list(
                    children: [if (addInfo != null) ...addInfo]),
              ),
            );
          })
        ],
      ),
    );
  }

  Widget _wrapSkeleton(
      BuildContext context, Widget Function(BuildContext context) f) {
    final Map<SingleActivatorDescription, Null Function()> bindings =
        _makeBindings(context);

    return CallbackGridState.wrapNotifiers(context, widget.registerNotifiers,
        (context) {
      return CallbackShortcuts(
          bindings: {
            ...bindings,
            ...keybindDescription(
                context,
                describeKeys(bindings),
                AppLocalizations.of(context)!.imageViewPageName,
                widget.focusMain)
          },
          child: Focus(
            autofocus: true,
            focusNode: mainFocus,
            child: Theme(
              data: Theme.of(context).copyWith(
                  iconTheme: IconThemeData(
                      color: ColorTween(
                              begin: previousPallete
                                      ?.dominantColor?.bodyTextColor
                                      .withOpacity(0.8) ??
                                  kListTileColorInInfo,
                              end: currentPalette?.dominantColor?.bodyTextColor
                                      .withOpacity(0.8) ??
                                  kListTileColorInInfo)
                          .transform(_animationController.value)),
                  bottomSheetTheme: BottomSheetThemeData(
                    shape: const Border(),
                    backgroundColor: ColorTween(
                            begin: previousPallete?.dominantColor?.color
                                    .withOpacity(0.5) ??
                                Colors.black.withOpacity(0.5),
                            end: currentPalette?.dominantColor?.color
                                    .withOpacity(0.5) ??
                                Colors.black.withOpacity(0.5))
                        .transform(_animationController.value),
                  )),
              child: Builder(
                builder: f,
              ),
            ),
          ));
    });
  }

  Widget _loadingBuilder(BuildContext context, ImageChunkEvent? event) {
    final expectedBytes = event?.expectedTotalBytes;
    final loadedBytes = event?.cumulativeBytesLoaded;
    final value = loadedBytes != null && expectedBytes != null
        ? loadedBytes / expectedBytes
        : null;

    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
            ColorTween(
              begin: Colors.black,
              end: currentPalette?.mutedColor?.color.withOpacity(0.7),
            ).lerp(value ?? 0)!,
            ColorTween(
              begin: Colors.black38,
              end: currentPalette?.mutedColor?.color.withOpacity(0.5),
            ).lerp(value ?? 0)!,
            ColorTween(
              begin: Colors.black12,
              end: currentPalette?.mutedColor?.color.withOpacity(0.3),
            ).lerp(value ?? 0)!,
          ])),
      child: Center(
        child: SizedBox(
            width: 20.0,
            height: 20.0,
            child: CircularProgressIndicator(
                backgroundColor: ColorTween(
                  begin: previousPallete?.mutedColor?.color.withOpacity(0.7),
                  end: currentPalette?.mutedColor?.color.withOpacity(0.7),
                ).transform(_animationController.value),
                color: ColorTween(
                  begin: previousPallete?.dominantColor?.color,
                  end: currentPalette?.dominantColor?.color,
                ).transform(_animationController.value),
                value: value)),
      ),
    );
  }

  BoxDecoration _photoBackgroundDecoration() {
    return BoxDecoration(
      color: ColorTween(
        begin: previousPallete?.mutedColor?.color.withOpacity(0.7),
        end: currentPalette?.mutedColor?.color.withOpacity(0.7),
      ).transform(_animationController.value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _wrapSkeleton(context, (context) {
      return Scaffold(
        key: key,
        extendBodyBehindAppBar: true,
        endDrawerEnableOpenDragGesture: false,
        resizeToAvoidBottomInset: false,
        bottomSheet: _makeBottomSheet(context),
        endDrawer: _makeEndDrawer(context),
        appBar: _makeAppBar(context),
        body: gestureDeadZones(
          context,
          child: GestureDetector(
            onLongPress: widget.download == null
                ? null
                : () {
                    HapticFeedback.vibrate();
                    widget.download!(currentPage);
                  },
            onTap: _onTap,
            child: PhotoViewGallery.builder(
                loadingBuilder: _loadingBuilder,
                enableRotation: true,
                backgroundDecoration: _photoBackgroundDecoration(),
                onPageChanged: (index) async {
                  currentPage = index;
                  widget.pageChange?.call(this);
                  _loadNext(index);
                  widget.updateTagScrollPos(null, index);

                  widget.scrollUntill(index);

                  final c = widget.getCell(index);

                  fullscreenPlug.setTitle(c.alias(true));

                  setState(() {
                    currentCell = c;
                    _extractPalette();
                  });
                },
                pageController: controller,
                itemCount: cellCount,
                builder: (context, indx) {
                  final fileContent = widget.predefinedIndexes != null
                      ? widget
                          .getCell(widget.predefinedIndexes![indx])
                          .fileDisplay()
                      : widget.getCell(indx).fileDisplay();

                  return switch (fileContent) {
                    AndroidImage() => _makeAndroidImage(
                        fileContent.size, fileContent.uri, false),
                    AndroidGif() => _makeAndroidImage(
                        fileContent.size, fileContent.uri, true),
                    NetGif() => _makeNetImage(fileContent.provider),
                    NetImage() => _makeNetImage(fileContent.provider),
                    AndroidVideo() => _makeVideo(fileContent.uri, true),
                    NetVideo() => _makeVideo(fileContent.uri, false),
                    EmptyContent() => PhotoViewGalleryPageOptions.customChild(
                          child: const Center(
                        child: Icon(Icons.error_outline),
                      ))
                  };
                }),
          ),
          left: true,
          right: true,
        ),
      );
    });
  }
}
