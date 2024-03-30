// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/db/base/booru_post_functionality_mixin.dart';
import 'package:gallery/src/db/schemas/booru/favorite_booru.dart';
import 'package:gallery/src/db/schemas/booru/note_booru.dart';
import 'package:gallery/src/db/schemas/settings/hidden_booru_post.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/interfaces/booru/safe_mode.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/db/schemas/settings/settings.dart';
import 'package:gallery/src/interfaces/cell/sticker.dart';
import 'package:isar/isar.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path_util;
import 'package:transparent_image/transparent_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../interfaces/cell/contentable.dart';
import '../../interfaces/booru/display_quality.dart';

enum PostRating {
  general,
  sensitive,
  questionable,
  explicit;

  String translatedName(BuildContext context) => switch (this) {
        PostRating.general =>
          AppLocalizations.of(context)!.enumPostRatingGeneral,
        PostRating.sensitive =>
          AppLocalizations.of(context)!.enumPostRatingSensitive,
        PostRating.questionable =>
          AppLocalizations.of(context)!.enumPostRatingQuestionable,
        PostRating.explicit =>
          AppLocalizations.of(context)!.enumPostRatingExplicit,
      };

  SafeMode get asSafeMode => switch (this) {
        PostRating.general => SafeMode.normal,
        PostRating.sensitive => SafeMode.relaxed,
        PostRating.questionable || PostRating.explicit => SafeMode.none,
      };
}

class PostBase with BooruPostFunctionalityMixin implements Cell {
  PostBase({
    required this.id,
    required this.height,
    required this.md5,
    required this.tags,
    required this.width,
    required this.fileUrl,
    required this.booru,
    required this.previewUrl,
    required this.sampleUrl,
    required this.ext,
    required this.sourceUrl,
    required this.rating,
    required this.score,
    required this.createdAt,
    this.isarId,
  });

  @override
  Id? isarId;

  @Index(unique: true, replace: true, composite: [CompositeIndex("booru")])
  final int id;

  final String md5;

  @Index(caseSensitive: false, type: IndexType.hashElements)
  final List<String> tags;

  final int width;
  final int height;

  @Index()
  final String fileUrl;
  final String previewUrl;
  final String sampleUrl;
  final String sourceUrl;

  final String ext;

  @Index()
  @enumerated
  final PostRating rating;
  final int score;
  final DateTime createdAt;
  @enumerated
  final Booru booru;

  @override
  ImageProvider<Object>? thumbnail() {
    if (HiddenBooruPost.isHidden(id, booru)) {
      return _transparent;
    }

    return CachedNetworkImageProvider(previewUrl);
  }

  @override
  Contentable content() {
    if (HiddenBooruPost.isHidden(id, booru)) {
      return const EmptyContent();
    }

    String url = switch (Settings.fromDb().quality) {
      DisplayQuality.original => fileUrl,
      DisplayQuality.sample => sampleUrl
    };

    var type = lookupMimeType(url);
    if (type == null) {
      return const EmptyContent();
    }

    var typeHalf = type.split("/");

    if (typeHalf[0] == "image") {
      ImageProvider provider;
      try {
        provider = NetworkImage(url);
      } catch (e) {
        provider = MemoryImage(kTransparentImage);
      }

      return typeHalf[1] == "gif" ? NetGif(provider) : NetImage(provider);
    } else if (typeHalf[0] == "video") {
      return NetVideo(path_util.extension(url) == ".zip" ? sampleUrl : url);
    } else {
      return const EmptyContent();
    }
  }

  @override
  Key uniqueKey() => ValueKey(fileUrl);

  String filename() =>
      "${booru.prefix}_$id - $md5${ext != '.zip' ? ext : path_util.extension(sampleUrl)}";

  @override
  List<Widget>? addButtons(BuildContext context) {
    return [
      openInBrowserButton(Uri.base, () {
        launchUrl(
          booru.browserLink(id),
          mode: LaunchMode.externalApplication,
        );
      }),
      if (Platform.isAndroid)
        shareButton(context, fileUrl, () {
          showQr(context, booru.prefix, id);
        })
      else
        IconButton(
          onPressed: () {
            showQr(context, booru.prefix, id);
          },
          icon: const Icon(Icons.qr_code_rounded),
        )
    ];
  }

  @override
  List<(IconData, void Function()?)>? addStickers(BuildContext context) {
    final icons = defaultStickers(
      content(),
      context,
      tags,
      id,
      booru,
    );

    return icons.isEmpty ? null : icons;
  }

  @override
  Widget? contentInfo(BuildContext context) => PostInfo(post: this);

  @override
  String alias(bool isList) => isList ? tags.join(" ") : id.toString();

  @override
  String fileDownloadUrl() {
    if (path_util.extension(fileUrl) == ".zip") {
      return sampleUrl;
    } else {
      return fileUrl;
    }
  }

  @override
  List<Sticker> stickers(BuildContext context) {
    final isHidden = HiddenBooruPost.isHidden(id, booru);

    return [
      if (isHidden) const Sticker(Icons.hide_image_rounded),
      if (this is! FavoriteBooru && Settings.isFavorite(id, booru))
        const Sticker(Icons.favorite_rounded, important: true),
      if (NoteBooru.hasNotes(id, booru))
        const Sticker(Icons.sticky_note_2_outlined),
      ...defaultStickers(
        content(),
        context,
        tags,
        id,
        booru,
      ).map((e) => Sticker(e.$1))
    ];
  }
}

final _transparent = MemoryImage(kTransparentImage);
