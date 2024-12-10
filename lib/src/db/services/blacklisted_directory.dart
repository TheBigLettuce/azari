// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

abstract interface class BlacklistedDirectoryService
    implements ResourceSource<String, BlacklistedDirectoryData>, ServiceMarker {
  List<BlacklistedDirectoryData> getAll(List<String> bucketIds);
}

@immutable
abstract class BlacklistedDirectoryData
    implements CellBase, Pressable<BlacklistedDirectoryData> {
  const factory BlacklistedDirectoryData({
    required String bucketId,
    required String name,
  }) = $BlacklistedDirectoryData;

  String get bucketId;
  String get name;
}

@immutable
abstract class BlacklistedDirectoryDataImpl
    with DefaultBuildCellImpl
    implements BlacklistedDirectoryData {
  const BlacklistedDirectoryDataImpl();

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
    int idx,
  ) {
    final (api, _, _) = DirectoriesDataNotifier.of(context);
    final db = DatabaseConnectionNotifier.of(context);

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

    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return FilesPage(
            api: api,
            dirName: name,
            directories: [
              PlainDirectory(
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
            db: db,
            navBarEvents: NavigationButtonEvents.maybeOf(context),
            scrollingSink: ScrollingSinkProvider.maybeOf(context),
          );
        },
      ),
    );
  }
}
