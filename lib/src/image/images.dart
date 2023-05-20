/*import 'package:flutter/material.dart';
import '../cell/cell.dart';
import '../cell/directory.dart';
import 'cells.dart';

class Images extends StatefulWidget {
  final DirectoryCell cell;
  const Images({super.key, required this.cell});

  @override
  State<Images> createState() => _ImagesState();
}

class _ImagesState extends State<Images> {
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  AssetPathEntity? directoryEntity;
  List<ImageCell> cells = [];
  int page = 0;
  bool reachedEnd = false;

  @override
  void initState() {
    super.initState();
  }

  Future<List<ImageCell>> _convertFromAssets(List<AssetEntity> l) async {
    var newCells = l.map((e) async {
      var thumb = await e.thumbnailData;
      String? videoUri;
      if (e.type == AssetType.video) {
        videoUri = await e.getMediaUrl();
      }

      return ImageCell(
          videoUri: videoUri,
          entity: e,
          thumb: thumb!,
          addButtons: () {
            return null;
          },
          addInfo: (_) {
            return null;
          },
          alias: e.title!,
          path: e.relativePath!);
    }).toList();

    List<ImageCell> newCellsSync = [];

    for (var cell in newCells) {
      newCellsSync.add(await cell);
    }

    return newCellsSync;
  }

  Future<int> _refresh() async {
    cells.clear();
    page = 0;
    reachedEnd = false;

    return _loadNext();
  }

  Future<int> _loadNext() async {
    try {
      directoryEntity ??= await AssetPathEntity.fromId(widget.cell.id);
      var entities =
          await directoryEntity!.getAssetListPaged(page: page, size: 20);

      if (entities.isNotEmpty) {
        cells.addAll(await _convertFromAssets(entities));
      } else {
        reachedEnd = true;
      }
    } catch (e) {
      print(e);
    }

    page++;

    return Future.value(cells.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      body: CellsWidget<ImageCell>(
        updateScrollPosition: (pos, {double? infoPos, int? selectedCell}) {},
        scaffoldKey: _key,
        refresh: _refresh,
        hasReachedEnd: () => reachedEnd,
        search: (s) {},
        onBack: () => Navigator.of(context).pop(),
        loadNext: _loadNext,
        getCell: (i) => cells[i],
        initalScrollPosition: 0,
        onLongPress: (indx) {
          return Navigator.of(context).push(DialogRoute(
              context: context,
              builder: ((context) {
                return AlertDialog(
                  title: const Text("Do you want to delete:"),
                  content: Text(widget.cell.alias),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("no")),
                    TextButton(onPressed: () {}, child: const Text("yes")),
                  ],
                );
              })));
        },
      ),
    );
  }
}*/
