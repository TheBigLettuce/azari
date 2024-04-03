// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/main.dart';
import 'package:gallery/src/db/schemas/gallery/directory_metadata.dart';
import 'package:gallery/src/db/schemas/statistics/statistics_gallery.dart';
import 'package:gallery/src/interfaces/gallery/gallery_api_directories.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart';
import 'package:gallery/src/pages/gallery/callback_description_nested.dart';
import 'package:gallery/src/db/schemas/gallery/system_gallery_directory.dart';
import 'package:gallery/src/widgets/grid_frame/grid_frame.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:local_auth/local_auth.dart';

import 'files.dart';
import '../../db/schemas/gallery/blacklisted_directory.dart';

class SystemGalleryDirectoriesActions {
  static GridAction blacklist(
      BuildContext context,
      GalleryDirectoriesExtra extra,
      String Function(SystemGalleryDirectory) segment) {
    return GridAction(
      Icons.hide_image_outlined,
      (selected) async {
        final requireAuth = <SystemGalleryDirectory>[];
        final noAuth = <SystemGalleryDirectory>[];

        for (final SystemGalleryDirectory e in selected.cast()) {
          final m = DirectoryMetadata.get(segment(e));
          if (m != null && m.requireAuth) {
            requireAuth.add(e);
          } else {
            noAuth.add(e);
          }
        }

        if (noAuth.isEmpty && requireAuth.isNotEmpty && canAuthBiometric) {
          final success = await LocalAuthentication()
              .authenticate(localizedReason: "Hide directory");
          if (!success) {
            return;
          }
        }

        extra.addBlacklisted(
            (noAuth.isEmpty && requireAuth.isNotEmpty ? requireAuth : noAuth)
                .map((e) => BlacklistedDirectory(e.bucketId, e.name))
                .toList());

        if (noAuth.isNotEmpty && requireAuth.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Some directories require authentication"),
            action: SnackBarAction(
                label: "Auth",
                onPressed: () async {
                  final success = await LocalAuthentication()
                      .authenticate(localizedReason: "Hide directory");
                  if (!success) {
                    return;
                  }

                  extra.addBlacklisted(requireAuth
                      .map((e) => BlacklistedDirectory(e.bucketId, e.name))
                      .toList());
                }),
          ));
        }
      },
      true,
    );
  }

  static GridAction joinedDirectories(
    BuildContext context,
    GalleryDirectoriesExtra extra,
    CallbackDescriptionNested? callback,
    SelectionGlue Function([Set<GluePreferences>])? generate,
    String Function(SystemGalleryDirectory) segment,
  ) {
    return GridAction(
      Icons.merge_rounded,
      (selected) {
        joinedDirectoriesFnc(
          context,
          selected.length == 1
              ? (selected.first as SystemGalleryDirectory).name
              : "${selected.length} ${AppLocalizations.of(context)!.directoriesPlural}",
          selected.cast(),
          extra,
          callback,
          generate,
          segment,
        );
      },
      true,
    );
  }

  static void joinedDirectoriesFnc(
    BuildContext context,
    String label,
    List<SystemGalleryDirectory> dirs,
    GalleryDirectoriesExtra extra,
    CallbackDescriptionNested? callback,
    SelectionGlue Function([Set<GluePreferences>])? generate,
    String Function(SystemGalleryDirectory) segment,
  ) async {
    bool requireAuth = false;

    for (final e in dirs) {
      final auth = DirectoryMetadata.get(segment(e))?.requireAuth ?? false;
      if (auth) {
        requireAuth = true;
        break;
      }
    }

    if (requireAuth && canAuthBiometric) {
      final success = await LocalAuthentication()
          .authenticate(localizedReason: "Join directories");

      if (!success) {
        return;
      }
    }

    StatisticsGallery.addJoined();

    final joined = extra.joinedDir(dirs.map((e) => e.bucketId).toList());

    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return GalleryFiles(
          secure: requireAuth,
          generateGlue: generate,
          api: joined,
          callback: callback,
          dirName: label,
          bucketId: "joinedDir",
        );
      },
    ));
  }
}
