import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../cell/image.dart';

class ImageView<T extends ImageCell> extends StatefulWidget {
  final int startingCell;
  final List<T> cells;
  final Future Function(int i)? download;

  const ImageView(
      {super.key,
      required this.startingCell,
      required this.cells,
      this.download});

  @override
  State<ImageView> createState() => _ImageViewState();
}

class _ImageViewState<T extends ImageCell> extends State<ImageView<T>> {
  late PageController controller;
  late T currentCell;

  @override
  void initState() {
    super.initState();

    currentCell = widget.cells[widget.startingCell];
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
                                ListTile(
                                  title: const Text("Type"),
                                  subtitle:
                                      Text(typeToString(currentCell.type)),
                                )
                              ];

                              if (currentCell.addInfo != null) {
                                for (var widget in currentCell.addInfo!) {
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
              setState(() {
                currentCell = widget.cells[index];
              });
            },
            pageController: controller,
            itemCount: widget.cells.length,
            builder: (context, indx) {
              return PhotoViewGalleryPageOptions(
                  filterQuality: FilterQuality.high,
                  imageProvider: NetworkImage(widget.cells[indx].url()));
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
