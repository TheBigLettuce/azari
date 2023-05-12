import 'package:isar/isar.dart';

part 'download_file.g.dart';

@collection
class File {
  Id? id;

  @Index(unique: true, replace: true)
  String url;
  @Index(unique: true, replace: true)
  String name;

  DateTime date;

  String site;

  bool isFailed;

  bool inProgress;

  bool isOnHold() => isFailed == false && inProgress == false;

  File inprogress() => File(url, true, false, site, name, id: id);
  File failed() => File(url, false, true, site, name, id: id);
  File onHold() => File(url, false, false, site, name, id: id);

  File.d(this.url, this.site, this.name, {this.id})
      : inProgress = true,
        isFailed = false,
        date = DateTime.now();

  File(this.url, this.inProgress, this.isFailed, this.site, this.name,
      {this.id})
      : date = DateTime.now();
}
