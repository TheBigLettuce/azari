// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:io";

import "package:azari/src/plugs/gallery_management/android.dart";
import "package:azari/src/plugs/gallery_management/dummy_io.dart";
import "package:azari/src/plugs/gallery_management_api.dart";
import "package:file_picker/file_picker.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

GalleryManagementApi getApi() => Platform.isAndroid
    ? const AndroidGalleryManagementApi()
    : Platform.isAndroid
        ? const LinuxGalleryManagementApi()
        : const DummyIoGalleryManagementApi();

void initApi() {}

class LinuxGalleryManagementApi implements DummyIoGalleryManagementApi {
  const LinuxGalleryManagementApi();

  @override
  Future<(String, String)?> chooseDirectory(
    AppLocalizations l10n, {
    bool temporary = false,
  }) {
    return FilePicker.platform
        .getDirectoryPath(dialogTitle: l10n.pickDirectory)
        .then((e) => e == null ? null : (e, e));
  }

  @override
  GalleryTrash get trash => const DummyGalleryTrash();

  @override
  CachedThumbs get thumbs => const DummyCachedThumbs();

  @override
  FilesManagement get files => const IoFilesManagement();
}
