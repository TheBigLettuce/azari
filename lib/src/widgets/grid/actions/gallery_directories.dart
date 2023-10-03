// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/pages/gallery/directories.dart';
import 'package:gallery/src/db/schemas/system_gallery_directory.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../interfaces/gallery.dart';
import '../../../pages/gallery/files.dart';
import '../../../db/schemas/blacklisted_directory.dart';

class SystemGalleryDirectoriesActions {
  static GridBottomSheetAction<SystemGalleryDirectory> blacklist(
      BuildContext context, GalleryDirectoriesExtra extra) {
    return GridBottomSheetAction(Icons.hide_image_outlined, (selected) {
      extra.addBlacklisted(selected
          .map((e) => BlacklistedDirectory(e.bucketId, e.name))
          .toList());
    },
        true,
        GridBottomSheetActionExplanation(
          label: AppLocalizations.of(context)!.blacklistActionLabel,
          body: AppLocalizations.of(context)!.blacklistActionBody,
        ));
  }

  static GridBottomSheetAction<SystemGalleryDirectory> joinedDirectories(
      BuildContext context,
      GalleryDirectoriesExtra extra,
      CallbackDescriptionNested? callback) {
    return GridBottomSheetAction(Icons.merge_rounded, (selected) {
      joinedDirectoriesFnc(
          context,
          selected.length == 1
              ? selected.first.name
              : "${selected.length} ${AppLocalizations.of(context)!.directoriesPlural}",
          selected,
          extra,
          callback);
    },
        true,
        GridBottomSheetActionExplanation(
          label: AppLocalizations.of(context)!.joinActionLabel,
          body: AppLocalizations.of(context)!.joinActionBody,
        ));
  }

  static void joinedDirectoriesFnc(
      BuildContext context,
      String label,
      List<SystemGalleryDirectory> dirs,
      GalleryDirectoriesExtra extra,
      CallbackDescriptionNested? callback) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return GalleryFiles(
            api: extra.joinedDir(dirs.map((e) => e.bucketId).toList()),
            callback: callback,
            dirName: label,
            bucketId: "joinedDir");
      },
    ));
  }
}
