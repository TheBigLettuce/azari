// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/gallery/gallery_api_files.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/plugs/gallery_management_api.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";

enum GalleryFilesPageType {
  normal,
  trash,
  favorites;

  bool isFavorites() => this == favorites;
  bool isTrash() => this == trash;
}

abstract class GalleryAPIDirectories {
  ResourceSource<int, GalleryDirectory> get source;
  TrashCell get trashCell;

  GalleryAPIFiles? get bindFiles;

  GalleryAPIFiles files(
    GalleryDirectory d,
    GalleryFilesPageType type,
    DirectoryTagService directoryTag,
    DirectoryMetadataService directoryMetadata,
    FavoriteFileService favoriteFile,
    LocalTagsService localTags,
  );

  GalleryAPIFiles joinedFiles(
    List<String> bucketIds,
    DirectoryTagService directoryTag,
    DirectoryMetadataService directoryMetadata,
    FavoriteFileService favoriteFile,
    LocalTagsService localTags,
  );

  void close();
}

class TrashCell implements AsyncCell<GalleryDirectory> {
  TrashCell(this.l8n);

  final _events = StreamController<GalleryDirectory?>.broadcast();
  // final _key = UniqueKey();
  final AppLocalizations l8n;

  GalleryDirectory? _currentData;
  Future<int?>? _trashFuture;

  void refresh() {
    if (_trashFuture != null) {
      _trashFuture?.ignore();
      _trashFuture = null;
    }

    _trashFuture = GalleryManagementApi.current().trashThumbId().then((e) {
      _currentData = e == null
          ? null
          : GalleryDirectory.forPlatform(
              bucketId: "trash",
              name: l8n.galleryDirectoryTrash,
              tag: "",
              volumeName: "",
              relativeLoc: "",
              lastModified: 0,
              thumbFileId: e,
            );

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
  StreamSubscription<GalleryDirectory?> watch(
    void Function(GalleryDirectory? p1) f, [
    bool fire = false,
  ]) =>
      _events.stream.transform<GalleryDirectory?>(
        StreamTransformer((input, cancelOnError) {
          final controller = StreamController<GalleryDirectory?>(sync: true);
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
