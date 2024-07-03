// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

abstract interface class BlacklistedDirectoryService
    implements ResourceSource<String, BlacklistedDirectoryData>, ServiceMarker {
  List<BlacklistedDirectoryData> getAll(List<String> bucketIds);
}

abstract class BlacklistedDirectoryData
    implements CellBase, Pressable<BlacklistedDirectoryData> {
  const BlacklistedDirectoryData(this.bucketId, this.name);

  @Index(unique: true, replace: true)
  final String bucketId;
  @Index()
  final String name;

  @override
  Key uniqueKey() => ValueKey(bucketId);

  @override
  CellStaticData description() => const CellStaticData();

  @override
  String alias(bool isList) => name;

  @override
  void onPress(
    BuildContext context,
    GridFunctionality<BlacklistedDirectoryData> functionality,
    BlacklistedDirectoryData cell,
    int idx,
  ) {
    final (api, _, _, _) = DirectoriesDataNotifier.of(context);
    final db = DatabaseConnectionNotifier.of(context);

    final filesApi = api.files(
      PlainGalleryDirectory(
        bucketId: bucketId,
        name: name,
        tag: "",
        volumeName: "",
        relativeLoc: "",
        lastModified: 0,
        thumbFileId: 0,
      ),
      name,
      GalleryFilesPageType.normal,
      db.directoryTags,
      db.directoryMetadata,
      db.favoriteFiles,
      db.localTags,
    );

    final glue = GlueProvider.generateOf(context);

    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return GalleryFiles(
            api: filesApi,
            dirName: name,
            directory: null,
            bucketId: bucketId,
            secure: true,
            generateGlue: glue,
            db: db,
            tagManager: TagManager.of(context),
          );
        },
      ),
    );
  }
}
