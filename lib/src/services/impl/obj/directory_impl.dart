// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:animations/animations.dart";
import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/impl/io/platform_thumbnail_provider.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/gallery/directories.dart";
import "package:azari/src/ui/material/pages/gallery/files.dart";
import "package:azari/src/ui/material/pages/gallery/gallery_return_callback.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/widgets/grid_cell/cell.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";
import "package:local_auth/local_auth.dart";

abstract class DirectoryImpl
    with DefaultBuildCell, CellBuilderData
    implements DirectoryBase, CellBuilder {
  const DirectoryImpl();

  @override
  Key uniqueKey() => ValueKey(bucketId);

  @override
  String title(AppLocalizations l10n) => name;

  @override
  ImageProvider<Object> thumbnail() => PlatformThumbnailProvider(thumbFileId);

  @override
  Widget buildCell(
    AppLocalizations l10n, {
    required bool hideName,
    required CellType cellType,
    Alignment imageAlign = Alignment.center,
  }) =>
      _Cell(
        cellType: cellType,
        hideName: hideName,
        impl: this,
        imageAlign: imageAlign,
        superChild: super.buildCell(
          l10n,
          cellType: cellType,
          imageAlign: imageAlign,
          hideName: hideName,
        ),
      );
}

class _Cell extends StatelessWidget {
  const _Cell({
    super.key,
    required this.impl,
    required this.hideName,
    required this.cellType,
    required this.imageAlign,
    required this.superChild,
  });

  final DirectoryImpl impl;

  final bool hideName;
  final CellType cellType;
  final Alignment imageAlign;

  final Widget superChild;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
    final theme = Theme.of(context);

    final (api, callback, segmentFnc) = DirectoriesDataNotifier.of(context);

    final scrollingState = ScrollingStateSinkProvider.maybeOf(context);
    final navBarEvents = NavigationButtonEvents.maybeOf(context);

    final selectionController = SelectionActions.controllerOf(context);

    final thisIdx = ThisIndex.maybeOf(context);

    return OpenContainer(
      tappable: false,
      closedElevation: 0,
      openElevation: 0,
      transitionType: ContainerTransitionType.fadeThrough,
      middleColor: theme.colorScheme.surface.withValues(alpha: 0),
      openColor: theme.colorScheme.surface.withValues(alpha: 0),
      closedColor: theme.colorScheme.surface.withValues(alpha: 1),
      closedBuilder: (containerContext, action) => WrapSelection(
        overrideIdx: thisIdx,
        onPressed: () {
          final (api, callback, segmentFnc) =
              DirectoriesDataNotifier.of(context);

          if (callback?.isDirectory ?? false) {
            Navigator.pop(containerContext);

            (callback! as ReturnDirectoryCallback)(
              (
                bucketId: impl.bucketId,
                path: impl.relativeLoc,
                volumeName: impl.volumeName
              ),
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

            requireAuth = DirectoryMetadataService.safe()
                    ?.cache
                    .get(segmentFnc(impl as Directory))
                    ?.requireAuth ??
                false;

            if (const AppApi().canAuthBiometric && requireAuth) {
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
        child: superChild,
      ),
      openBuilder: (containerContext, action) {
        return FilesPage(
          api: api,
          dirName: switch (impl.bucketId) {
            "favorites" => l10n.galleryDirectoriesFavorites,
            "trash" => l10n.galleryDirectoryTrash,
            String() => impl.name,
          },
          // secure: secure,
          selectionController: selectionController,
          directories: [impl as Directory],
          scrollingState: scrollingState,
          navBarEvents: navBarEvents,
          callback: callback?.toFileOrNull,
        );
      },
    );
  }
}
