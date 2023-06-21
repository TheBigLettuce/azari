// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/plugs/platform_fullscreens.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/system_gestures.dart';
import 'package:logging/logging.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';
import '../cell/cell.dart';
import '../keybinds/keybinds.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final Color kListTileColorInInfo = Colors.white60.withOpacity(0.8);

class PhotoGalleryPageVideoLinux extends StatefulWidget {
  final String url;
  final bool localVideo;
  const PhotoGalleryPageVideoLinux(
      {super.key, required this.url, required this.localVideo});

  @override
  State<PhotoGalleryPageVideoLinux> createState() =>
      _PhotoGalleryPageVideoLinuxState();
}

class _PhotoGalleryPageVideoLinuxState
    extends State<PhotoGalleryPageVideoLinux> {
  Player player = Player();
  VideoController? controller;

  @override
  void initState() {
    super.initState();

    VideoController.create(player, enableHardwareAcceleration: false)
        .then((value) {
      controller = value;
      player.open(
        Media(
          widget.url,
        ),
      );
      setState(() {});
    }).onError((error, stackTrace) {
      log("video player linux",
          level: Level.SEVERE.value, error: error, stackTrace: stackTrace);
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return controller == null
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : GestureDetector(
            onDoubleTap: () {
              player.playOrPause();
            },
            child: Video(controller: controller),
          );
  }
}

class PhotoGalleryPageVideo extends StatefulWidget {
  final String url;
  final bool localVideo;
  const PhotoGalleryPageVideo({
    super.key,
    required this.url,
    required this.localVideo,
  });

  @override
  State<PhotoGalleryPageVideo> createState() => _PhotoGalleryPageVideoState();
}

class _PhotoGalleryPageVideoState extends State<PhotoGalleryPageVideo> {
  late VideoPlayerController controller;
  ChewieController? chewieController;
  bool disposed = false;
  Object? error;

  @override
  void initState() {
    super.initState();

    if (widget.localVideo) {
      controller = VideoPlayerController.contentUri(Uri.parse(widget.url),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
    } else {
      controller = VideoPlayerController.network(widget.url,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
    }

    _initController();
  }

  void _initController() async {
    controller.initialize().then((value) {
      if (!disposed) {
        setState(() {
          chewieController = ChewieController(
              videoPlayerController: controller,
              aspectRatio: controller.value.aspectRatio,
              autoInitialize: false,
              looping: true,
              allowPlaybackSpeedChanging: false,
              showOptions: false,
              showControls: false,
              allowMuting: false,
              zoomAndPan: true,
              showControlsOnInitialize: false,
              autoPlay: false);
        });

        chewieController!.play().onError((e, stackTrace) {
          if (!disposed) {
            setState(() {
              error = e;
            });
          }
        });
      }
    }).onError((e, stackTrace) {
      if (!disposed) {
        setState(() {
          error = e;
        });
      }
    });
  }

  @override
  void dispose() {
    disposed = true;
    controller.dispose();
    if (chewieController != null) {
      chewieController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return error != null
        ? const Icon(Icons.error)
        : chewieController == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : GestureDetector(
                // onTap: widget.onTap,
                onDoubleTap: () {
                  if (!disposed) {
                    if (chewieController!.isPlaying) {
                      chewieController!.pause();
                    } else {
                      chewieController!.play();
                    }
                  }
                },
                child: Chewie(controller: chewieController!),
              );
  }
}

class ImageView<T extends Cell> extends StatefulWidget {
  final int startingCell;
  final T Function(int i) getCell;
  final int cellCount;
  final void Function(int post) scrollUntill;
  final void Function(double? pos, int? selectedCell) updateTagScrollPos;
  final Future<int> Function()? onNearEnd;
  final void Function(int i)? download;
  final double? infoScrollOffset;
  final Color systemOverlayRestoreColor;

  const ImageView(
      {super.key,
      required this.updateTagScrollPos,
      required this.cellCount,
      required this.scrollUntill,
      required this.startingCell,
      required this.getCell,
      required this.onNearEnd,
      required this.systemOverlayRestoreColor,
      this.infoScrollOffset,
      this.download});

  @override
  State<ImageView> createState() => _ImageViewState();
}

class _ImageViewState<T extends Cell> extends State<ImageView<T>> {
  late PageController controller;
  late T currentCell;
  late int currentPage = widget.startingCell;
  late ScrollController scrollController;
  late int cellCount = widget.cellCount;
  bool refreshing = false;

  PhotoViewController photoController = PhotoViewController();

  final GlobalKey<ScaffoldState> key = GlobalKey();

  AnimationController? downloadButtonController;

  bool isAppbarShown = true;

  late PlatformFullscreensPlug fullscreenPlug =
      choosePlatformFullscreenPlug(widget.systemOverlayRestoreColor);

  @override
  void initState() {
    super.initState();

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
  }

  @override
  void dispose() {
    fullscreenPlug.unFullscreen();

    widget.updateTagScrollPos(null, null);
    controller.dispose();
    photoController.dispose();

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

  @override
  Widget build(BuildContext context) {
    var addB = currentCell.addButtons();
    Map<SingleActivatorDescription, Null Function()> bindings = {
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
        var pos = photoController.position;
        photoController.position = pos.translate(-40, 0);
      },
      SingleActivatorDescription(AppLocalizations.of(context)!.moveImageLeft,
              const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true)):
          () {
        var pos = photoController.position;
        photoController.position = pos.translate(40, 0);
      },
      SingleActivatorDescription(
          AppLocalizations.of(context)!.rotateImageRight,
          const SingleActivator(LogicalKeyboardKey.arrowRight,
              control: true)): () {
        photoController.rotation += 0.5;
      },
      SingleActivatorDescription(
          AppLocalizations.of(context)!.rotateImageLeft,
          const SingleActivator(LogicalKeyboardKey.arrowLeft,
              control: true)): () {
        photoController.rotation -= 0.5;
      },
      SingleActivatorDescription(AppLocalizations.of(context)!.moveImageUp,
          const SingleActivator(LogicalKeyboardKey.arrowUp)): () {
        var pos = photoController.position;
        photoController.position = pos.translate(0, 40);
      },
      SingleActivatorDescription(AppLocalizations.of(context)!.moveImageDown,
          const SingleActivator(LogicalKeyboardKey.arrowDown)): () {
        var pos = photoController.position;
        photoController.position = pos.translate(0, -40);
      },
      SingleActivatorDescription(AppLocalizations.of(context)!.zoomImageIn,
          const SingleActivator(LogicalKeyboardKey.pageUp)): () {
        var s = photoController.scale;

        if (s != null && s < 2.5) {
          photoController.scale = s + 0.5;
        }
      },
      SingleActivatorDescription(AppLocalizations.of(context)!.zoomImageOut,
          const SingleActivator(LogicalKeyboardKey.pageDown)): () {
        var s = photoController.scale;

        if (s != null && s > 0.2) {
          photoController.scale = s - 0.25;
        }
      },
      SingleActivatorDescription(AppLocalizations.of(context)!.showImageInfo,
          const SingleActivator(LogicalKeyboardKey.keyI)): () {
        if (key.currentState != null) {
          if (key.currentState!.isEndDrawerOpen) {
            key.currentState?.closeEndDrawer();
          } else {
            key.currentState?.openEndDrawer();
          }
        }
      },
      SingleActivatorDescription(AppLocalizations.of(context)!.downloadImage,
          const SingleActivator(LogicalKeyboardKey.keyD)): () {
        if (widget.download != null) {
          widget.download!(currentPage);
        }
      },
      SingleActivatorDescription(AppLocalizations.of(context)!.hideAppBar,
          const SingleActivator(LogicalKeyboardKey.space)): () {
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

    var addInfo = currentCell.addInfo(context, () {
      widget.updateTagScrollPos(scrollController.offset, currentPage);
    }, Theme.of(context).colorScheme.outlineVariant, kListTileColorInInfo,
        widget.systemOverlayRestoreColor);

    var insets = MediaQuery.viewPaddingOf(context);

    return CallbackShortcuts(
        bindings: {
          ...bindings,
          ...keybindDescription(context, describeKeys(bindings),
              AppLocalizations.of(context)!.imageViewPageName)
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
              key: key,
              extendBodyBehindAppBar: true,
              endDrawerEnableOpenDragGesture: false,
              endDrawer: Drawer(
                backgroundColor:
                    Theme.of(context).colorScheme.surface.withOpacity(0.5),
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    endDrawerHeading(context, "Info", key),
                    SliverPadding(
                      padding: EdgeInsets.only(bottom: insets.bottom),
                      sliver: SliverList.list(
                          children: [if (addInfo != null) ...addInfo]),
                    )
                  ],
                ),
              ),
              appBar: PreferredSize(
                preferredSize: AppBar().preferredSize,
                child: IgnorePointer(
                  ignoring: !isAppbarShown,
                  child: AppBar(
                    automaticallyImplyLeading: false,
                    foregroundColor: kListTileColorInInfo,
                    backgroundColor: Colors.black.withOpacity(0.5),
                    leading: const BackButton(),
                    title: Text(currentCell.alias(false)),
                    actions: [
                      if (addB != null) ...addB,
                      if (widget.download != null)
                        IconButton(
                                onPressed: () {
                                  if (downloadButtonController != null) {
                                    downloadButtonController!.forward(from: 0);
                                  }
                                  widget.download!(currentPage);
                                },
                                icon: const Icon(Icons.download))
                            .animate(
                                onInit: (controller) =>
                                    downloadButtonController = controller,
                                effects: const [ShakeEffect()],
                                autoPlay: false),
                      IconButton(
                          onPressed: () {
                            key.currentState?.openEndDrawer();
                          },
                          icon: const Icon(Icons.info_outline))
                    ],
                  ),
                ).animate(
                  effects: [
                    FadeEffect(begin: 1, end: 0, duration: 500.milliseconds)
                  ],
                  autoPlay: false,
                  target: isAppbarShown ? 0 : 1,
                ),
              ),
              body: gestureDeadZones(context,
                  child: Stack(children: [
                    GestureDetector(
                      onLongPress: widget.download == null
                          ? null
                          : () {
                              HapticFeedback.vibrate();
                              widget.download!(currentPage);
                            },
                      onTap: _onTap,
                      child: PhotoViewGallery.builder(
                          enableRotation: true,
                          onPageChanged: (index) async {
                            currentPage = index;
                            photoController.rotation = 0;
                            photoController.position = Offset.zero;
                            _loadNext(index);

                            widget.scrollUntill(index);

                            var c = widget.getCell(index);

                            fullscreenPlug.setTitle(c.alias(true));

                            setState(() {
                              currentCell = c;
                            });
                          },
                          pageController: controller,
                          itemCount: cellCount,
                          builder: (context, indx) {
                            var fileContent =
                                widget.getCell(indx).fileDisplay();

                            if (fileContent.type == "video") {
                              return PhotoViewGalleryPageOptions.customChild(
                                  disableGestures: true,
                                  tightMode: true,
                                  child: Platform.isLinux
                                      ? PhotoGalleryPageVideoLinux(
                                          url: fileContent.videoPath!,
                                          localVideo: fileContent.isVideoLocal)
                                      : PhotoGalleryPageVideo(
                                          url: fileContent.videoPath!,
                                          localVideo: fileContent.isVideoLocal,
                                        ));
                            } else if (fileContent.type == "image") {
                              return PhotoViewGalleryPageOptions(
                                  controller: photoController,
                                  minScale:
                                      PhotoViewComputedScale.contained * 0.8,
                                  maxScale:
                                      PhotoViewComputedScale.covered * 1.8,
                                  initialScale:
                                      PhotoViewComputedScale.contained,
                                  filterQuality: FilterQuality.high,
                                  imageProvider: fileContent.image);
                            } else {
                              return PhotoViewGalleryPageOptions.customChild(
                                  disableGestures: true,
                                  child: const Icon(Icons.error_outline));
                            }
                          }),
                    ),
                  ]),
                  left: true,
                  right: true)),
        ));
  }
}
