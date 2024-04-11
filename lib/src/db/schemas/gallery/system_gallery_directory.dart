// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/main.dart';
import 'package:gallery/src/db/base/system_gallery_thumbnail_provider.dart';
import 'package:gallery/src/db/schemas/gallery/directory_metadata.dart';
import 'package:gallery/src/db/schemas/statistics/statistics_gallery.dart';
import 'package:gallery/src/pages/gallery/directories.dart';
import 'package:gallery/src/pages/gallery/files.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:local_auth/local_auth.dart';

import '../../../interfaces/cell/cell.dart';

part 'system_gallery_directory.g.dart';

@collection
class SystemGalleryDirectory
    implements
        CellBase,
        Pressable<SystemGalleryDirectory>,
        IsarEntryId,
        Thumbnailable {
  SystemGalleryDirectory({
    required this.bucketId,
    required this.name,
    required this.tag,
    required this.volumeName,
    required this.relativeLoc,
    required this.lastModified,
    required this.thumbFileId,
  });

  @override
  Id? isarId;

  final int thumbFileId;
  @Index(unique: true)
  final String bucketId;

  @Index()
  final String name;

  final String relativeLoc;
  final String volumeName;

  @Index()
  final int lastModified;

  @Index()
  final String tag;

  @override
  CellStaticData description() => const CellStaticData();

  @override
  ImageProvider<Object> thumbnail() =>
      SystemGalleryThumbnailProvider(thumbFileId, true);

  @override
  Key uniqueKey() => ValueKey(bucketId);

  @override
  String alias(bool isList) => name;

  @override
  void onPress(
    BuildContext context,
    GridFunctionality<SystemGalleryDirectory> functionality,
    SystemGalleryDirectory cell,
    int idx,
  ) async {
    final (api, callback, nestedCallback, segmentFnc) =
        DirectoriesDataNotifier.of(context);
    final extra = api.getExtra();

    if (callback != null) {
      functionality.refreshingStatus.mutation.cellCount = 0;

      Navigator.pop(context);
      callback(cell, null);
    } else {
      bool requireAuth = false;

      if (canAuthBiometric) {
        requireAuth =
            DirectoryMetadata.get(segmentFnc(cell))?.requireAuth ?? false;
        if (requireAuth) {
          final success = await LocalAuthentication().authenticate(
            localizedReason: AppLocalizations.of(context)!.openDirectory,
          );
          if (!success) {
            return;
          }
        }
      }

      StatisticsGallery.addViewedDirectories();
      final d = cell;

      final apiFiles = switch (cell.bucketId) {
        "trash" => extra.trash(),
        "favorites" => extra.favorites(),
        String() => api.files(d),
      };

      final glue = GlueProvider.generateOf(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => switch (cell.bucketId) {
            "favorites" => GalleryFiles(
                generateGlue: glue,
                api: apiFiles,
                secure: requireAuth,
                callback: nestedCallback,
                dirName:
                    AppLocalizations.of(context)!.galleryDirectoriesFavorites,
                bucketId: "favorites",
              ),
            "trash" => GalleryFiles(
                api: apiFiles,
                generateGlue: glue,
                secure: requireAuth,
                callback: nestedCallback,
                dirName: AppLocalizations.of(context)!.galleryDirectoryTrash,
                bucketId: "trash",
              ),
            String() => GalleryFiles(
                generateGlue: glue,
                api: apiFiles,
                secure: requireAuth,
                dirName: d.name,
                callback: nestedCallback,
                bucketId: d.bucketId,
              )
          },
        ),
      );
    }
  }
}
