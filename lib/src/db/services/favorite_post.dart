// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

// extension PostDownloadExt on Post {
//   void download(BuildContext context) {
//     DownloadManager.of(context).addLocalTags(
//       [
//         DownloadEntryTags.d(
//           tags: tags,
//           name: DisassembleResult.makeFilename(
//             booru,
//             fileDownloadUrl(),
//             md5,
//             id,
//           ),
//           url: fileDownloadUrl(),
//           thumbUrl: previewUrl,
//           site: booru.url,
//         ),
//       ],
//       SettingsService.db().current,
//       PostTags.fromContext(context),
//     );
//   }
// }

abstract class FavoritePostData extends PostBase
    with Post, DefaultPostPressable {
  FavoritePostData({
    required this.group,
    required super.id,
    required super.height,
    required super.md5,
    required super.tags,
    required super.width,
    required super.fileUrl,
    required super.booru,
    required super.previewUrl,
    required super.sampleUrl,
    required super.sourceUrl,
    required super.rating,
    required super.score,
    required super.createdAt,
    required super.type,
  });

  @Index()
  String? group;

  @override
  CellStaticData description() => const CellStaticData();
}

abstract interface class FavoritePostService implements ServiceMarker {
  int get count;

  void addRemove(
    BuildContext context,
    List<Post> posts,
    bool showDeleteSnackbar,
  );

  bool isFavorite(int id, Booru booru);

  void addAllFileUrl(List<FavoritePostData> favorites);

  StreamSubscription<void> watch(
    void Function(void) f, [
    bool fire = false,
  ]);
}
