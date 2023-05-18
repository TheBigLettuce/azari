import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/system_gestures.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';
import '../cell/cell.dart';

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
  final Future Function(int i)? download;
  final double? infoScrollOffset;

  const ImageView(
      {super.key,
      required this.updateTagScrollPos,
      required this.cellCount,
      required this.scrollUntill,
      required this.startingCell,
      required this.getCell,
      required this.onNearEnd,
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

  bool showInfo = false;
  bool showAppBar = true;

  @override
  void initState() {
    super.initState();

    scrollController =
        ScrollController(initialScrollOffset: widget.infoScrollOffset ?? 0);
    if (widget.infoScrollOffset != null) {
      showInfo = true;
    }

    WidgetsBinding.instance.scheduleFrameCallback((_) {
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
        print(error);
      });
    }
  }

  void _onTap() {
    if (!showAppBar) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
    setState(() {
      showAppBar = !showAppBar;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: !showAppBar
            ? null
            : PreferredSize(
                preferredSize: AppBar().preferredSize,
                child: AppBar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  title: Text(currentCell.alias),
                  actions: () {
                    List<Widget> list = [];

                    var addB = currentCell.addButtons();
                    if (addB != null) {
                      list.addAll(addB);
                    }

                    if (widget.download != null) {
                      list.add(IconButton(
                          onPressed: () {
                            widget.download!(currentPage);
                          },
                          icon: const Icon(Icons.download)));
                    }

                    list.add(IconButton(
                        onPressed: () => setState(() {
                              showInfo = !showInfo;
                            }),
                        icon: const Icon(Icons.info_outline)));

                    return list;
                  }(),
                ).animate().fadeIn(),
              ),
        body: gestureDeadZones(context,
            child: WillPopScope(
              onWillPop: () {
                if (showInfo) {
                  setState(() {
                    showInfo = false;
                  });
                  return Future.value(false);
                }

                return Future.value(true);
              },
              child: Stack(children: () {
                List<Widget> list = [];

                list.add(GestureDetector(
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
                ));

                if (showInfo) {
                  list.add(Container(
                    decoration:
                        BoxDecoration(color: Colors.black.withOpacity(0.5)),
                    child: ListView(
                        controller: scrollController,
                        children: () {
                          List<Widget> list = [
                            ListTile(
                              title: const Text("Alias"),
                              subtitle: Text(currentCell.alias),
                            ),
                            ListTile(
                              title: const Text("Path"),
                              subtitle: Text(currentCell.fileDownloadUrl()),
                            ),
                          ];

                          var addInfo = currentCell.addInfo(() {
                            widget.updateTagScrollPos(
                                scrollController.offset, currentPage);
                          });
                          if (addInfo != null) {
                            for (var widget in addInfo) {
                              list.add(widget);
                            }
                          }

                          return list;
                        }()),
                  ).animate().fadeIn());
                }

                return list;
              }()),
            ),
            left: true,
            right: true));
  }
}

const imageType = 1;
const videoType = 2;
const movingImageType = 3;

String typeToString(int t) {
  switch (t) {
    case imageType:
      return "Image";
    default:
      return "Unknown";
  }
}
