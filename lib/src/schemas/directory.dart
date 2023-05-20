import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:isar/isar.dart';

import '../cell/directory.dart';

part 'directory.g.dart';

@collection
class Directory {
  Id? isarId;

  @Index(unique: true, replace: true)
  String id;
  String name;
  List<int> thumbnail;

  DateTime updatedAt;

  DirectoryCell cell() => DirectoryCell(
      id: id,
      image: MemoryImage(Uint8List.fromList(thumbnail)),
      path: name,
      dirName: name,
      addInfo: (d, c, fc) {
        return null;
      },
      addButtons: () {
        return null;
      });

  Directory(this.id, this.name, this.thumbnail, this.updatedAt);
}
