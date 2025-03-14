// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:animations/animations.dart";
import "package:azari/init_main/app_info.dart";
import "package:azari/src/db/gallery_thumbnail_provider.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/pages/gallery/directories.dart";
import "package:azari/src/pages/gallery/files.dart";
import "package:azari/src/pages/gallery/gallery_return_callback.dart";
import "package:azari/src/pages/home/home.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/grid_cell/cell.dart";
import "package:azari/src/widgets/grid_cell_widget.dart";
import "package:azari/src/widgets/selection_bar.dart";
import "package:azari/src/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";
import "package:local_auth/local_auth.dart";

abstract class DirectoryImpl
    with DefaultBuildCellImpl
    implements DirectoryBase, CellBase, Thumbnailable, SelectionWrapperBuilder {
  const DirectoryImpl();

  @override
  CellStaticData description() => const CellStaticData();

  @override
  Widget buildSelectionWrapper<T extends CellBase>({
    required BuildContext context,
    required int thisIndx,
    required List<int>? selectFrom,
    required CellStaticData description,
    required VoidCallback? onPressed,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    final (api, callback, segmentFnc) = DirectoriesDataNotifier.of(context);

    final db = Services.of(context);
    final l10n = context.l10n();

    final scrollingState = ScrollingStateSinkProvider.maybeOf(context);
    final navBarEvents = NavigationButtonEvents.maybeOf(context);
    final downloadManager = DownloadManager.of(context);

    final selectionController = SelectionActions.controllerOf(context);

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
        onPressed: () {
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

              StatisticsGalleryService.addViewedDirectories(1);

              action();
            }

            requireAuth =
                Services.getOf<DirectoryMetadataService>(containerContext)
                        ?.cache
                        .get(segmentFnc(this as Directory))
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
        return FilesPage(
          api: api,
          dirName: switch (bucketId) {
            "favorites" => l10n.galleryDirectoriesFavorites,
            "trash" => l10n.galleryDirectoryTrash,
            String() => name,
          },
          // secure: secure,
          selectionController: selectionController,
          directories: [this as Directory],
          scrollingState: scrollingState,
          navBarEvents: navBarEvents,
          callback: callback?.toFileOrNull,
          favoritePosts: db.get<FavoritePostSourceService>(),
          localTags: db.get<LocalTagsService>(),
          thumbnails: db.get<ThumbnailService>(),
          tagManager: db.get<TagManagerService>(),
          directoryMetadata: db.get<DirectoryMetadataService>(),
          videoSettings: db.get<VideoSettingsService>(),
          downloadManager: downloadManager,
          directoryTags: db.get<DirectoryTagService>(),
          galleryService: db.get<GalleryService>()!,
          gridSettings: db.get<GridSettingsService>()!,
          settingsService: db.require<SettingsService>(),
        );
      },
    );
  }

  @override
  ImageProvider<Object> thumbnail(BuildContext? context) =>
      GalleryThumbnailProvider(
        thumbFileId,
        true,
      );

  @override
  Key uniqueKey() => ValueKey(bucketId);

  @override
  String alias(bool isList) => name;
}

mixin PigeonDirectoryPressable implements Directory, Pressable<Directory> {
  @override
  void onPressed(
    BuildContext context,
    int idx,
  ) {
    final l10n = context.l10n();

    final (api, callback, segmentFnc) = DirectoriesDataNotifier.of(context);

    FilesPage.openProtected(
      context: context,
      l10n: l10n,
      directory: this,
      callback: callback,
      api: api,
      segmentFnc: segmentFnc,
      addScaffold: false,
    );
  }
}
