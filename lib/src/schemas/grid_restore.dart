import 'package:isar/isar.dart';

part 'grid_restore.g.dart';

@collection
class GridRestore {
  Id? id;
  @Index(unique: true, replace: true)
  String path;
  DateTime date;
  GridRestore(this.path) : date = DateTime.now();
}
