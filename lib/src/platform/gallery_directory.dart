// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "gallery_api.dart";

abstract class Directory
    with DefaultBuildCellImpl
    implements CellBase, Pressable<Directory>, Thumbnailable {
  const Directory({
    required this.bucketId,
    required this.name,
    required this.tag,
    required this.volumeName,
    required this.relativeLoc,
    required this.lastModified,
    required this.thumbFileId,
  });

  final int thumbFileId;

  final String bucketId;

  final String name;

  final String relativeLoc;
  final String volumeName;

  final int lastModified;

  final String tag;

  @override
  CellStaticData description() => const CellStaticData();

  @override
  ImageProvider<Object> thumbnail() => GalleryThumbnailProvider(
        thumbFileId,
        true,
        PinnedThumbnailService.db(),
        ThumbnailService.db(),
      );

  @override
  Key uniqueKey() => ValueKey(bucketId);

  @override
  String alias(bool isList) => name;

  @override
  Future<void> onPress(
    BuildContext context,
    GridFunctionality<Directory> functionality,
    Directory cell,
    int idx,
  ) {
    final l10n = AppLocalizations.of(context)!;

    final (api, callback, nestedCallback, segmentFnc) =
        DirectoriesDataNotifier.of(context);

    if (callback != null) {
      Navigator.pop(context);
      callback(
        chosen: cell.relativeLoc,
        volumeName: cell.volumeName,
        newDir: false,
        bucketId: cell.bucketId,
      );

      return Future.value();
    } else {
      bool requireAuth = false;

      Future<void> onSuccess(bool success) {
        if (!success || !context.mounted) {
          return Future.value();
        }

        StatisticsGalleryService.db().current.add(viewedDirectories: 1).save();
        final d = cell;

        final db = DatabaseConnectionNotifier.of(context);

        final apiFiles = switch (cell.bucketId) {
          "trash" => api.files(
              d,
              d.name,
              GalleryFilesPageType.trash,
              db.directoryTags,
              db.directoryMetadata,
              db.favoritePosts,
              db.localTags,
            ),
          "favorites" => api.files(
              d,
              d.name,
              GalleryFilesPageType.favorites,
              db.directoryTags,
              db.directoryMetadata,
              db.favoritePosts,
              db.localTags,
            ),
          String() => api.files(
              d,
              d.name,
              GalleryFilesPageType.normal,
              db.directoryTags,
              db.directoryMetadata,
              db.favoritePosts,
              db.localTags,
            ),
        };

        final glue = GlueProvider.generateOf(context);

        return Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (context) => switch (cell.bucketId) {
              "favorites" => GalleryFiles(
                  generateGlue: glue,
                  api: apiFiles,
                  directory: this,
                  secure: requireAuth,
                  callback: nestedCallback,
                  dirName: l10n.galleryDirectoriesFavorites,
                  bucketId: "favorites",
                  db: DatabaseConnectionNotifier.of(context),
                  tagManager: TagManager.of(context),
                ),
              "trash" => GalleryFiles(
                  api: apiFiles,
                  directory: this,
                  generateGlue: glue,
                  secure: requireAuth,
                  callback: nestedCallback,
                  dirName: l10n.galleryDirectoryTrash,
                  bucketId: "trash",
                  db: DatabaseConnectionNotifier.of(context),
                  tagManager: TagManager.of(context),
                ),
              String() => GalleryFiles(
                  generateGlue: glue,
                  api: apiFiles,
                  directory: this,
                  secure: requireAuth,
                  dirName: d.name,
                  callback: nestedCallback,
                  bucketId: d.bucketId,
                  db: DatabaseConnectionNotifier.of(context),
                  tagManager: TagManager.of(context),
                )
            },
          ),
        );
      }

      requireAuth = DatabaseConnectionNotifier.of(context)
              .directoryMetadata
              .get(segmentFnc(cell))
              ?.requireAuth ??
          false;

      if (AppInfo().canAuthBiometric && requireAuth) {
        return LocalAuthentication()
            .authenticate(
              localizedReason: l10n.openDirectory,
            )
            .then(onSuccess);
      } else {
        return onSuccess(true);
      }
    }
  }
}

class TrashCell implements AsyncCell<Directory> {
  TrashCell(this.l10n);

  final _events = StreamController<Directory?>.broadcast();

  final AppLocalizations l10n;

  Directory? _currentData;
  Future<Directory?>? _trashFuture;

  void refresh() {
    if (_trashFuture != null) {
      _trashFuture?.ignore();
      _trashFuture = null;
    }

    _trashFuture = GalleryApi().trash.thumb.then((e) {
      _currentData = e;

      _events.add(_currentData);
      return e;
    });
  }

  void dispose() {
    _trashFuture?.ignore();
    _events.close();
  }

  @override
  Key uniqueKey() => const ValueKey("trash");

  @override
  StreamSubscription<Directory?> watch(
    void Function(Directory? p1) f, [
    bool fire = false,
  ]) =>
      _events.stream.transform<Directory?>(
        StreamTransformer((input, cancelOnError) {
          final controller = StreamController<Directory?>(sync: true);
          controller.onListen = () {
            final subscription = input.listen(
              controller.add,
              onError: controller.addError,
              onDone: controller.close,
              cancelOnError: cancelOnError,
            );
            controller
              ..onPause = subscription.pause
              ..onResume = subscription.resume
              ..onCancel = subscription.cancel;
          };

          if (fire) {
            Timer.run(() {
              controller.add(_currentData);
            });
          }

          return controller.stream.listen(null);
        }),
      ).listen(f);
}
