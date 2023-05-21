// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/system_gestures.dart';
import 'package:logging/logging.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';
import '../cell/cell.dart';

final Color kListTileColorInInfo = Colors.white60.withOpacity(0.8);

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

  AnimationController? downloadButtonController;

  bool isAppbarShown = true;
  bool isInfoShown = false;

  @override
  void initState() {
    super.initState();

    scrollController =
        ScrollController(initialScrollOffset: widget.infoScrollOffset ?? 0);
    if (widget.infoScrollOffset != null) {
      isInfoShown = true;
    }

    WidgetsBinding.instance.scheduleFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
            systemNavigationBarColor: Colors.black.withOpacity(0.5)),
      );
      _loadNext(widget.startingCell);
    });

    currentCell = widget.getCell(widget.startingCell);
    controller = PageController(initialPage: widget.startingCell);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    widget.updateTagScrollPos(null, null);
    controller.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        systemNavigationBarColor: widget.systemOverlayRestoreColor));
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
    if (!isAppbarShown) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
    setState(() {
      isAppbarShown = !isAppbarShown;
    });
  }

  @override
  Widget build(BuildContext context) {
    var addB = currentCell.addButtons();
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: AppBar().preferredSize,
          child: IgnorePointer(
            ignoring: !isAppbarShown,
            child: AppBar(
              foregroundColor: kListTileColorInInfo,
              backgroundColor: Colors.black.withOpacity(0.5),
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
                    onPressed: () => setState(() {
                          isInfoShown = !isInfoShown;
                        }),
                    icon: const Icon(Icons.info_outline))
              ],
            ),
          ).animate(
            effects: [FadeEffect(begin: 1, end: 0, duration: 500.milliseconds)],
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
                      _loadNext(index);
                      widget.scrollUntill(index);

                      setState(() {
                        currentCell = widget.getCell(index);
                      });
                    },
                    pageController: controller,
                    itemCount: cellCount,
                    builder: (context, indx) {
                      var fileContent = widget.getCell(indx).fileDisplay();

                      if (fileContent.type == "video") {
                        return PhotoViewGalleryPageOptions.customChild(
                            disableGestures: true,
                            tightMode: true,
                            child: PhotoGalleryPageVideo(
                              url: fileContent.videoPath!,
                              localVideo: fileContent.isVideoLocal,
                            ));
                      } else if (fileContent.type == "image") {
                        return PhotoViewGalleryPageOptions(
                            minScale: PhotoViewComputedScale.contained,
                            filterQuality: FilterQuality.high,
                            imageProvider: fileContent.image);
                      } else {
                        return PhotoViewGalleryPageOptions.customChild(
                            disableGestures: true,
                            child: const Icon(Icons.error_outline));
                      }
                    }),
              ),
              Animate(

                  //onInit: (controller) => infoAnimController = controller,
                  effects: [
                    //FadeEffect(begin: 1, end: 0),
                    SwapEffect(builder: (_, __) {
                      var addInfo = currentCell.addInfo(() {
                        widget.updateTagScrollPos(
                            scrollController.offset, currentPage);
                      }, Theme.of(context).colorScheme.outlineVariant,
                          kListTileColorInInfo);

                      return Container(
                        decoration:
                            BoxDecoration(color: Colors.black.withOpacity(0.5)),
                        child:
                            ListView(controller: scrollController, children: [
                          ListTile(
                            textColor: kListTileColorInInfo,
                            title: const Text("Path"),
                            subtitle: Text(currentCell.fileDownloadUrl()),
                          ),
                          if (addInfo != null) ...addInfo,
                        ]),
                      ).animate().fadeIn();
                    })
                  ],
                  target: isInfoShown ? 1 : 0,
                  autoPlay: false)
            ]),
            left: true,
            right: true));
  }
}
