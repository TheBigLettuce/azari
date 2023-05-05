import 'package:isar/isar.dart';

part 'download_file.g.dart';

@collection
class File {
  Id? id;

  String url;
  String name;

  String site;

  bool inProgress;

  File(this.url, this.inProgress, this.site, this.name, {this.id});
}
