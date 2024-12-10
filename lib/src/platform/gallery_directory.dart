// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "gallery_api.dart";

class _Placeholder extends StatefulWidget {
  const _Placeholder(
      // {super.key,}
      );

  @override
  State<_Placeholder> createState() => __PlaceholderState();
}

class __PlaceholderState extends State<_Placeholder> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

abstract class Directory
    with DefaultBuildCellImpl
    implements
        CellBase,
        Pressable<Directory>,
        Thumbnailable,
        SelectionWrapperBuilder {
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
  Widget buildSelectionWrapper<T extends CellBase>({
    required BuildContext context,
    required int thisIndx,
    required List<int>? selectFrom,
    required GridSelection<T>? selection,
    required CellStaticData description,
    required GridFunctionality<T> functionality,
    required VoidCallback? onPressed,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    final (api, callback, segmentFnc) = DirectoriesDataNotifier.of(context);

    return OpenContainer(
      tappable: false,
      closedElevation: 0,
      openElevation: 0,
      transitionType: ContainerTransitionType.fadeThrough,
      middleColor: theme.colorScheme.surface.withValues(alpha: 0),
      openColor: theme.colorScheme.surface.withValues(alpha: 0),
      closedColor: theme.colorScheme.surface.withValues(alpha: 1),
      closedBuilder: (containerContext, action) => WrapSelection(
        thisIndx: thisIndx,
        description: description,
        selectFrom: selectFrom,
        selection: selection,
        functionality: functionality,
        onPressed: () {
          final l10n = AppLocalizations.of(containerContext)!;

          final (api, callback, segmentFnc) =
              DirectoriesDataNotifier.of(context);

          if (callback?.isDirectory ?? false) {
            Navigator.pop(containerContext);

            (callback! as ReturnDirectoryCallback)(
              (bucketId: bucketId, path: relativeLoc, volumeName: volumeName),
              false,
            );
          } else {
            bool requireAuth = false;

            void onSuccess(bool success) {
              if (!success || !containerContext.mounted) {
                return;
              }

              StatisticsGalleryService.db()
                  .current
                  .add(viewedDirectories: 1)
                  .save();

              action();
            }

            requireAuth = DatabaseConnectionNotifier.of(containerContext)
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
          // action();
        }, // onPressed
        child: child,
      ),
      openBuilder: (containerContext, action) {
        final l10n = AppLocalizations.of(containerContext)!;

        return FilesPage(
          api: api,
          dirName: switch (bucketId) {
            "favorites" => l10n.galleryDirectoriesFavorites,
            "trash" => l10n.galleryDirectoryTrash,
            String() => name,
          },
          // secure: secure,
          directories: [this],
          db: DatabaseConnectionNotifier.of(containerContext),
          scrollingSink: ScrollingSinkProvider.maybeOf(containerContext),
          navBarEvents: NavigationButtonEvents.maybeOf(containerContext),
          callback: callback?.toFileOrNull,
        );
      },
    );
  }

  @override
  ImageProvider<Object> thumbnail(BuildContext? context) =>
      GalleryThumbnailProvider(
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

        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (context) => FilesPage(
              api: api,
              directories: [this],
              // secure: requireAuth,
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
