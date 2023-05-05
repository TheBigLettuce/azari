import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../cell/cell.dart';

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
  //bool disposed = false;

  @override
  void initState() {
    super.initState();

    currentCell = widget.getCell(widget.startingCell);
    controller = PageController(initialPage: widget.startingCell);
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
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
                                  subtitle: Text(currentCell.path),
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
            onPageChanged: (index) {
              if (index >= cellCount - 2 &&
                  !refreshing &&
                  widget.onNearEnd != null) {
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

              setState(() {
                currentCell = widget.getCell(index);
              });
            },
            pageController: controller,
            itemCount: cellCount,
            builder: (context, indx) {
              return PhotoViewGalleryPageOptions(
                  filterQuality: FilterQuality.high,
                  imageProvider: NetworkImage(widget.getCell(indx).url()));
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
