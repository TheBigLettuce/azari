import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:mime/mime.dart';
import 'package:video_player/video_player.dart';
import '../cell/cell.dart';

class PhotoGalleryPageVideo extends StatefulWidget {
  final String url;
  const PhotoGalleryPageVideo({super.key, required this.url});

  @override
  State<PhotoGalleryPageVideo> createState() => _PhotoGalleryPageVideoState();
}

class _PhotoGalleryPageVideoState extends State<PhotoGalleryPageVideo> {
  late VideoPlayerController controller = VideoPlayerController.network(
    widget.url,
  );
  ChewieController? chewieController;
  bool disposed = false;
  Object? error;

  @override
  void initState() {
    super.initState();

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
              allowMuting: false,
              showControlsOnInitialize: false,
              showOptions: false,
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
            : Chewie(controller: chewieController!);
  }
}

class ImageView<T extends Cell> extends StatefulWidget {
  final int startingCell;
  final T Function(int i) getCell;
  final int cellCount;
  final Future<int> Function()? onNearEnd;
  final Future Function(int i)? download;

  const ImageView(
      {super.key,
      required this.cellCount,
      required this.startingCell,
      required this.getCell,
      required this.onNearEnd,
      this.download});

  @override
  State<ImageView> createState() => _ImageViewState();
}

class _ImageViewState<T extends Cell> extends State<ImageView<T>> {
  late PageController controller;
  late T currentCell;
  late int cellCount = widget.cellCount;
  bool refreshing = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.scheduleFrameCallback((_) {
      _loadNext(widget.startingCell);
    });

    currentCell = widget.getCell(widget.startingCell);
    controller = PageController(initialPage: widget.startingCell);
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          bottom: refreshing
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(4),
                  child: LinearProgressIndicator())
              : null,
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
                    widget.download!(controller.page!.toInt());
                  },
                  icon: const Icon(Icons.download)));
            }

            list.add(IconButton(
                onPressed: () {
                  Navigator.of(context).push(DialogRoute(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(currentCell.alias),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView(children: () {
                              List<Widget> list = [
                                ListTile(
                                  title: const Text("Alias"),
                                  subtitle: Text(currentCell.alias),
                                ),
                                ListTile(
                                  title: const Text("Path"),
                                  subtitle: Text(currentCell.fileDisplayUrl()),
                                ),
                              ];

                              var addInfo = currentCell.addInfo();
                              if (addInfo != null) {
                                for (var widget in addInfo) {
                                  list.add(widget);
                                }
                              }

                              return list;
                            }()),
                          ),
                        );
                      }));
                },
                icon: const Icon(Icons.info_outline)));

            return list;
          }(),
        ),
        body: PhotoViewGallery.builder(
            onPageChanged: (index) async {
              _loadNext(index);

              setState(() {
                currentCell = widget.getCell(index);
              });
            },
            pageController: controller,
            itemCount: cellCount,
            builder: (context, indx) {
              var fileUrl = widget.getCell(indx).fileDisplayUrl();
              var s = lookupMimeType(fileUrl);
              if (s == null) {
                return PhotoViewGalleryPageOptions.customChild(
                    child: const Icon(Icons.error_outline));
              }

              var type = s.split("/")[0];
              if (type == "video") {
                return PhotoViewGalleryPageOptions.customChild(
                    tightMode: true,
                    child: PhotoGalleryPageVideo(
                      url: fileUrl,
                    ));
              } else if (type == "image") {
                return PhotoViewGalleryPageOptions(
                    filterQuality: FilterQuality.high,
                    imageProvider: NetworkImage(fileUrl));
              } else {
                return PhotoViewGalleryPageOptions.customChild(
                    child: const Icon(Icons.error_outline));
              }
            }));
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
