// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/gallery/blacklisted_directory.dart';
import 'package:gallery/src/db/schemas/gallery/system_gallery_directory.dart';
import 'package:gallery/src/interfaces/gallery/gallery_api_directories.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/pages/gallery/callback_description_nested.dart';

import '../../../pages/gallery/files.dart';
import '../metadata/grid_action.dart';

class SystemGalleryDirectoriesActions {
  static GridAction<SystemGalleryDirectory> blacklist(
    BuildContext context,
    GalleryAPIDirectories api,
  ) {
    return GridAction(
      Icons.hide_image_outlined,
      (selected) {
        api.getExtra().addBlacklisted(selected
            .map((e) => BlacklistedDirectory(e.bucketId, e.name))
            .toList());
      },
      true,
    );
  }

  static GridAction<SystemGalleryDirectory> joinedDirectories(
      BuildContext context,
      GalleryAPIDirectories api,
      CallbackDescriptionNested? callback) {
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
            callback);
      },
      true,
    );
  }

  static void joinedDirectoriesFnc(
      BuildContext context,
      String label,
      List<SystemGalleryDirectory> dirs,
      GalleryAPIDirectories api,
      CallbackDescriptionNested? callback) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return GalleryFiles(
            api: api.getExtra().joinedDir(dirs.map((e) => e.bucketId).toList()),
            callback: callback,
            dirName: label,
            bucketId: "joinedDir");
      },
    ));
  }
}
