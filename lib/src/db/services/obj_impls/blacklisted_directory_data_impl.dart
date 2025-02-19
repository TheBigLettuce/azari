// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/services.dart";
import "package:azari/src/pages/gallery/directories.dart";
import "package:azari/src/pages/gallery/files.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:flutter/material.dart";

@immutable
mixin BlacklistedDirectoryDataImpl
    implements CellBase, BlacklistedDirectoryDataBase {
  @override
  Key uniqueKey() => ValueKey(bucketId);

  @override
  CellStaticData description() => const CellStaticData();

  @override
  String alias(bool isList) => name;
}

mixin DefaultBlacklistedDirectoryDataOnPress
    implements
        BlacklistedDirectoryDataBase,
        Pressable<BlacklistedDirectoryData> {
  @override
  void onPressed(
    BuildContext context,
    GridFunctionality<BlacklistedDirectoryData> functionality,
    int idx,
  ) {
    final (api, _, _) = DirectoriesDataNotifier.of(context);
    // final db = DbConn.of(context);

    // final filesApi = api.files(
    //   PlainDirectory(
    //     bucketId: bucketId,
    //     name: name,
    //     tag: "",
    //     volumeName: "",
    //     relativeLoc: "",
    //     lastModified: 0,
    //     thumbFileId: 0,
    //   ),
    //   GalleryFilesPageType.normal,
    //   db.directoryTags,
    //   db.directoryMetadata,
    //   db.favoritePosts,
    //   db.localTags,
    //   name: name,
    //   bucketId: bucketId,
    // );

    FilesPage.open(
      context,
      api: api,
      dirName: name,
      directories: [
        Directory(
          bucketId: bucketId,
          name: name,
          tag: "",
          volumeName: "",
          relativeLoc: "",
          lastModified: 0,
          thumbFileId: 0,
        ),
      ],
      // directory: null,
      secure: true,
    );
  }
}
