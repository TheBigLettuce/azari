// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/main.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/gallery/gallery_api_directories.dart";
import "package:gallery/src/pages/gallery/callback_description_nested.dart";
import "package:gallery/src/pages/gallery/files.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:local_auth/local_auth.dart";

class SystemGalleryDirectoriesActions {
  const SystemGalleryDirectoriesActions();

  static GridAction<GalleryDirectory> blacklist(
    BuildContext context,
    String Function(GalleryDirectory) segment,
    DirectoryMetadataService directoryMetadata,
    BlacklistedDirectoryService blacklistedDirectory,
    AppLocalizations l8n,
  ) {
    return GridAction(
      Icons.hide_image_outlined,
      (selected) {
        final requireAuth = <BlacklistedDirectoryData>[];
        final noAuth = <BlacklistedDirectoryData>[];

        for (final e in selected) {
          final m = directoryMetadata.get(segment(e));
          if (m != null && m.requireAuth) {
            requireAuth.add(
              objFactory.makeBlacklistedDirectoryData(e.bucketId, e.name),
            );
          } else {
            noAuth.add(
              objFactory.makeBlacklistedDirectoryData(e.bucketId, e.name),
            );
          }
        }

        if (noAuth.isEmpty && requireAuth.isNotEmpty) {
          void onSuccess(bool success) {
            if (!success || !context.mounted) {
              return;
            }

            blacklistedDirectory.backingStorage.addAll(
              noAuth.isEmpty && requireAuth.isNotEmpty ? requireAuth : noAuth,
            );

            if (noAuth.isNotEmpty && requireAuth.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l8n.directoriesAuthMessage),
                  action: SnackBarAction(
                    label: l8n.authLabel,
                    onPressed: () async {
                      final success = await LocalAuthentication().authenticate(
                        localizedReason: l8n.hideDirectoryReason,
                      );
                      if (!success) {
                        return;
                      }

                      blacklistedDirectory.backingStorage.addAll(requireAuth);
                    },
                  ),
                ),
              );
            }
          }

          if (canAuthBiometric) {
            LocalAuthentication()
                .authenticate(localizedReason: l8n.hideDirectoryReason)
                .then(onSuccess);
          } else {
            onSuccess(true);
          }
        }
      },
      true,
    );
  }

  static GridAction<GalleryDirectory> joinedDirectories(
    BuildContext context,
    GalleryAPIDirectories api,
    CallbackDescriptionNested? callback,
    SelectionGlue Function([Set<GluePreferences>])? generate,
    String Function(GalleryDirectory) segment,
    DirectoryMetadataService directoryMetadata,
    DirectoryTagService directoryTags,
    FavoriteFileService favoriteFile,
    LocalTagsService localTags,
    AppLocalizations l8n,
  ) {
    return GridAction(
      Icons.merge_rounded,
      (selected) {
        joinedDirectoriesFnc(
          context,
          selected.length == 1
              ? selected.first.name
              : "${selected.length} ${l8n.directoriesPlural}",
          selected,
          api,
          callback,
          generate,
          segment,
          directoryMetadata,
          directoryTags,
          favoriteFile,
          localTags,
          l8n,
        );
      },
      true,
    );
  }

  static Future<void> joinedDirectoriesFnc(
    BuildContext context,
    String label,
    List<GalleryDirectory> dirs,
    GalleryAPIDirectories api,
    CallbackDescriptionNested? callback,
    SelectionGlue Function([Set<GluePreferences>])? generate,
    String Function(GalleryDirectory) segment,
    DirectoryMetadataService directoryMetadata,
    DirectoryTagService directoryTags,
    FavoriteFileService favoriteFile,
    LocalTagsService localTags,
    AppLocalizations l8n,
  ) {
    bool requireAuth = false;

    for (final e in dirs) {
      final auth = directoryMetadata.get(segment(e))?.requireAuth ?? false;
      if (auth) {
        requireAuth = true;
        break;
      }
    }

    Future<void> onSuccess(bool success) {
      if (!success || !context.mounted) {
        return Future.value();
      }

      StatisticsGalleryService.db().current.add(joined: 1).save();

      final joined = api.joinedFiles(
        dirs.map((e) => e.bucketId).toList(),
        directoryTags,
        directoryMetadata,
        favoriteFile,
        localTags,
      );

      return Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (context) {
            return GalleryFiles(
              secure: requireAuth,
              generateGlue: generate,
              api: joined,
              callback: callback,
              dirName: label,
              bucketId: "joinedDir",
              db: DatabaseConnectionNotifier.of(context),
              tagManager: TagManager.of(context),
            );
          },
        ),
      );
    }

    if (requireAuth && canAuthBiometric) {
      return LocalAuthentication()
          .authenticate(localizedReason: l8n.joinDirectoriesReason)
          .then(onSuccess);
    } else {
      return onSuccess(true);
    }
  }
}
