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
  ) {
    return GridAction(
      Icons.hide_image_outlined,
      (selected) async {
        final requireAuth = <GalleryDirectory>[];
        final noAuth = <GalleryDirectory>[];

        for (final e in selected) {
          final m = directoryMetadata.get(segment(e));
          if (m != null && m.requireAuth) {
            requireAuth.add(e);
          } else {
            noAuth.add(e);
          }
        }

        if (noAuth.isEmpty && requireAuth.isNotEmpty && canAuthBiometric) {
          final success = await LocalAuthentication()
              .authenticate(localizedReason: "Hide directory"); // TODO: change
          if (!success) {
            return;
          }
        }

        blacklistedDirectory.addAll(
          noAuth.isEmpty && requireAuth.isNotEmpty ? requireAuth : noAuth,
        );

        if (noAuth.isNotEmpty && requireAuth.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  "Some directories require authentication"), // TODO: change
              action: SnackBarAction(
                label: "Auth",
                onPressed: () async {
                  final success = await LocalAuthentication().authenticate(
                      localizedReason: "Hide directory"); // TODO: change
                  if (!success) {
                    return;
                  }

                  blacklistedDirectory.addAll(requireAuth);
                },
              ),
            ),
          );
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
  ) {
    return GridAction(
      Icons.merge_rounded,
      (selected) {
        joinedDirectoriesFnc(
          context,
          selected.length == 1
              ? selected.first.name
              : "${selected.length} ${AppLocalizations.of(context)!.directoriesPlural}",
          selected,
          api,
          callback,
          generate,
          segment,
          directoryMetadata,
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
  ) async {
    bool requireAuth = false;

    for (final e in dirs) {
      final auth = directoryMetadata.get(segment(e))?.requireAuth ?? false;
      if (auth) {
        requireAuth = true;
        break;
      }
    }

    if (requireAuth && canAuthBiometric) {
      final success = await LocalAuthentication()
          .authenticate(localizedReason: "Join directories"); // TODO: change

      if (!success) {
        return;
      }
    }

    StatisticsGalleryService.db().current.add(joined: 1).save();

    final joined = api.joinedFiles(dirs.map((e) => e.bucketId).toList());

    return Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
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
}
