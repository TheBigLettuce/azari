import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/cell/cell.dart';
import 'package:gallery/src/cell/data.dart';
import 'package:gallery/src/schemas/post.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

part 'directory_file.g.dart';

class DirectoryFileShrinked {
  final String dir;
  final String file;
  final String thumbHash;

  const DirectoryFileShrinked(
      {required this.dir, required this.file, required this.thumbHash});
}

@collection
class DirectoryFile implements Cell<DirectoryFileShrinked> {
  Id? isarId;

  String dir;
  @Index()
  String name;
  String thumbHash;
  String origHash;
  int type;
  int time;
  String host;
  List<String> tags;

  @ignore
  @override
  List<Widget>? Function() get addButtons => () => null;

  @ignore
  @override
  List<Widget>? Function(
          BuildContext context, dynamic extra, AddInfoColorData colors)
      get addInfo => (context, extra, colors) {
            return [
              ListTile(
                textColor: colors.foregroundColor,
                title: Text(AppLocalizations.of(context)!.nameTitle),
                subtitle: Text(name),
              ),
              ListTile(
                textColor: colors.foregroundColor,
                title: Text(AppLocalizations.of(context)!.directoryTitle),
                subtitle: Text(dir),
              ),
              ListTile(
                textColor: colors.foregroundColor,
                title: Text(AppLocalizations.of(context)!.thumbnailHashTitle),
                subtitle: Text(thumbHash),
              ),
              ListTile(
                textColor: colors.foregroundColor,
                title: Text(AppLocalizations.of(context)!.originalHashTitle),
                subtitle: Text(origHash),
              ),
              ListTile(
                textColor: colors.foregroundColor,
                title: Text(AppLocalizations.of(context)!.typeTitle),
                subtitle: Text(type.toString()),
              ),
              ListTile(
                textColor: colors.foregroundColor,
                title: Text(AppLocalizations.of(context)!.timeTitle),
                subtitle: Text(time.toString()),
              ),
              ...makeTags(context, extra, colors, tags, null)
            ];
          };

  @override
  String alias(bool isList) {
    return name;
  }

  @override
  Content fileDisplay() {
    if (type == 1) {
      return Content(ContentType.image, false,
          image: CachedNetworkImageProvider(
              Uri.parse(host).replace(path: '/static/$origHash').toString()));
    } else if (type == 2) {
      return Content(ContentType.video, false,
          videoPath:
              Uri.parse(host).replace(path: '/static/$origHash').toString());
    }
    throw "invalid image type";
  }

  @override
  String fileDownloadUrl() =>
      Uri.parse(host).replace(path: "/static/$origHash").toString();

  @override
  CellData getCellData(bool isList) {
    return CellData(
        thumb: NetworkImage(
            Uri.parse(host).replace(path: '/static/$thumbHash').toString()),
        name: name,
        stickers: [
          if (type == 2) Icons.play_circle,
          if (tags.contains("original")) kOriginalSticker,
        ]);
  }

  DirectoryFile(this.dir,
      {required this.host,
      required this.name,
      required this.origHash,
      required this.time,
      required this.thumbHash,
      required this.tags,
      required this.type});

  @override
  shrinkedData() =>
      DirectoryFileShrinked(dir: dir, file: name, thumbHash: thumbHash);
}
