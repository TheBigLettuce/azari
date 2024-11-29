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

  final int lastModified;

  final String bucketId;

  final String name;

  final String relativeLoc;
  final String volumeName;

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
  void onPress(
    BuildContext context,
    GridFunctionality<Directory> functionality,
    int idx,
  ) {
    final l10n = AppLocalizations.of(context)!;

    final (api, callback, segmentFnc) = DirectoriesDataNotifier.of(context);

    openFilesPage(
      context: context,
      l10n: l10n,
      callback: callback,
      api: api,
      segmentFnc: segmentFnc,
      addScaffold: false,
    );
  }

  void openFilesPage({
    required BuildContext context,
    required AppLocalizations l10n,
    required GalleryReturnCallback? callback,
    required Directories api,
    required String Function(Directory) segmentFnc,
    required bool addScaffold,
  }) {
    if (callback?.isDirectory ?? false) {
      Navigator.pop(context);

      (callback! as ReturnDirectoryCallback)(
        (bucketId: bucketId, path: relativeLoc, volumeName: volumeName),
        false,
      );
    } else {
      bool requireAuth = false;

      void onSuccess(bool success) {
        if (!success || !context.mounted) {
          return;
        }

        StatisticsGalleryService.db().current.add(viewedDirectories: 1).save();
        final d = this;

        final db = DatabaseConnectionNotifier.of(context);

        final apiFiles = api.files(
          d,
          switch (bucketId) {
            "favorites" => GalleryFilesPageType.favorites,
            "trash" => GalleryFilesPageType.trash,
            String() => GalleryFilesPageType.normal,
          },
          db.directoryTags,
          db.directoryMetadata,
          db.favoritePosts,
          db.localTags,
          name: d.name,
          bucketId: bucketId,
        );

        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (context) => FilesPage(
              api: apiFiles,
              directory: this,
              secure: requireAuth,
              addScaffold: addScaffold,
              callback: callback?.toFileOrNull,
              dirName: switch (bucketId) {
                "favorites" => l10n.galleryDirectoriesFavorites,
                "trash" => l10n.galleryDirectoryTrash,
                String() => d.name,
              },
              db: DatabaseConnectionNotifier.of(context),
              scrollingSink: ScrollingSinkProvider.maybeOf(context),
              navBarEvents: NavigationButtonEvents.maybeOf(context),
            ),
          ),
        );
      }

      requireAuth = DatabaseConnectionNotifier.of(context)
              .directoryMetadata
              .get(segmentFnc(this))
              ?.requireAuth ??
          false;

      if (AppInfo().canAuthBiometric && requireAuth) {
        LocalAuthentication()
            .authenticate(
              localizedReason: l10n.openDirectory,
            )
            .then(onSuccess);
      } else {
        onSuccess(true);
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
