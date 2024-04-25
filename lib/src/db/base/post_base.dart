// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:io";

import "package:cached_network_image/cached_network_image.dart";
import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/base/booru_post_functionality_mixin.dart";
import "package:gallery/src/db/schemas/booru/favorite_booru.dart";
import "package:gallery/src/db/schemas/booru/note_booru.dart";
import "package:gallery/src/db/schemas/downloader/download_file.dart";
import "package:gallery/src/db/schemas/settings/hidden_booru_post.dart";
import "package:gallery/src/db/schemas/settings/settings.dart";
import "package:gallery/src/db/schemas/tags/local_tag_dictionary.dart";
import "package:gallery/src/db/schemas/tags/pinned_tag.dart";
import "package:gallery/src/db/services/settings.dart";
import "package:gallery/src/db/tags/post_tags.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/display_quality.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/interfaces/cell/contentable.dart";
import "package:gallery/src/interfaces/cell/sticker.dart";
import "package:gallery/src/net/downloader.dart";
import "package:gallery/src/pages/more/favorite_booru_actions.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/image_view/image_view.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:isar/isar.dart";
import "package:mime/mime.dart";
import "package:path/path.dart" as path_util;
import "package:transparent_image/transparent_image.dart";
import "package:url_launcher/url_launcher.dart";

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

class PostBase
    with BooruPostFunctionalityMixin
    implements
        ContentableCell,
        Thumbnailable,
        ContentWidgets,
        AppBarButtonable,
        ImageViewActionable,
        Infoable,
        Stickerable,
        Downloadable,
        IsarEntryId {
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

  List<ImageTag> imageViewTags(Contentable c) => (c.widgets as PostBase)
      .tags
      .map((e) => ImageTag(e, PinnedTag.isPinned(e)))
      .toList();

  StreamSubscription<List<ImageTag>> watchTags(
    Contentable c,
    void Function(List<ImageTag> l) f,
  ) =>
      PostTags.g.watchImagePinned(tags, f);

  @override
  CellStaticData description() => const CellStaticData();

  @override
  Widget info(BuildContext context) => PostInfo(post: this);

  @override
  List<Widget> appBarButtons(BuildContext context) {
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
        ),
    ];
  }

  @override
  List<ImageViewAction> actions(BuildContext context) {
    final isFavorite = IsarSettings.isFavorite(id, booru);

    return [
      ImageViewAction(
        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        (_) {
          IsarSettings.addRemoveFavorites(context, [this], true);
          LocalTagDictionary.addAll(tags);
        },
        play: !isFavorite,
        color: isFavorite
            ? Colors.red.harmonizeWith(Theme.of(context).colorScheme.primary)
            : null,
        animate: true,
      ),
      if (this is FavoriteBooru)
        FavoritesActions.addToGroup<PostBase>(
          context,
          (selected) {
            final g = (selected.first as FavoriteBooru).group;

            for (final e in selected.cast<FavoriteBooru>().skip(1)) {
              if (g != e.group) {
                return null;
              }
            }

            return g;
          },
          (selected, value, toPin) {
            for (final FavoriteBooru e in selected.cast()) {
              e.group = value.isEmpty ? null : value;
            }

            FavoriteBooru.addAllFileUrl(selected.cast());

            Navigator.of(context, rootNavigator: true).pop();
          },
          false,
        ).asImageView(this),
      ImageViewAction(
        Icons.download,
        (_) {
          final settings = SettingsService.currentData;

          PostTags.g.addTagsPostAll([(filename(), tags)]);
          Downloader.g.add(
            DownloadFile.d(
              url: fileUrl,
              site: booru.url,
              name: filename(),
              thumbUrl: previewUrl,
            ),
            settings,
          );
        },
        animate: true,
      ),
      if (this is! FavoriteBooru)
        ImageViewAction(
          Icons.hide_image_rounded,
          (_) {
            if (HiddenBooruPost.isHidden(id, booru)) {
              HiddenBooruPost.removeAll([(id, booru)]);
            } else {
              HiddenBooruPost.addAll([
                HiddenBooruPost(booru, id, previewUrl),
              ]);
            }
          },
          color: HiddenBooruPost.isHidden(id, booru)
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
    ];
  }

  @override
  ImageProvider<Object> thumbnail() {
    if (HiddenBooruPost.isHidden(id, booru)) {
      return _transparent;
    }

    return CachedNetworkImageProvider(previewUrl);
  }

  @override
  Contentable content(BuildContext context) {
    if (HiddenBooruPost.isHidden(id, booru)) {
      return EmptyContent(this);
    }

    final url = switch (SettingsService.currentData.quality) {
      DisplayQuality.original => fileUrl,
      DisplayQuality.sample => sampleUrl
    };

    final type = lookupMimeType(url);
    if (type == null) {
      return EmptyContent(this);
    }

    final typeHalf = type.split("/");

    if (typeHalf[0] == "image") {
      final provider = NetworkImage(url);

      return typeHalf[1] == "gif"
          ? NetGif(this, provider)
          : NetImage(this, provider);
    } else if (typeHalf[0] == "video") {
      return NetVideo(
        this,
        path_util.extension(url) == ".zip" ? sampleUrl : url,
      );
    } else {
      return EmptyContent(this);
    }
  }

  @override
  Key uniqueKey() => ValueKey(fileUrl);

  String filename() =>
      "${booru.prefix}_$id - $md5${ext != '.zip' ? ext : path_util.extension(sampleUrl)}";

  @override
  String alias(bool isList) => isList ? filename() : id.toString();

  @override
  String fileDownloadUrl() {
    if (path_util.extension(fileUrl) == ".zip") {
      return sampleUrl;
    } else {
      return fileUrl;
    }
  }

  PostContentType _type() {
    final url = switch (SettingsService.currentData.quality) {
      DisplayQuality.original => fileUrl,
      DisplayQuality.sample => sampleUrl
    };

    final type = lookupMimeType(url);
    if (type == null) {
      return PostContentType.none;
    }

    final typeHalf = type.split("/");

    if (typeHalf[0] == "image") {
      return typeHalf[1] == "gif" ? PostContentType.gif : PostContentType.image;
    } else if (typeHalf[0] == "video") {
      return PostContentType.video;
    } else {
      return PostContentType.none;
    }
  }

  @override
  List<Sticker> stickers(BuildContext context, bool excludeDuplicate) {
    if (excludeDuplicate) {
      final icons = defaultStickers(
        _type(),
        context,
        tags,
        id,
        booru,
      );

      return icons.isEmpty ? const [] : icons;
    }

    final isHidden = HiddenBooruPost.isHidden(id, booru);

    return [
      if (isHidden) const Sticker(Icons.hide_image_rounded),
      if (this is! FavoriteBooru && IsarSettings.isFavorite(id, booru))
        const Sticker(Icons.favorite_rounded, important: true),
      if (NoteBooru.hasNotes(id, booru))
        const Sticker(Icons.sticky_note_2_outlined),
      ...defaultStickers(
        _type(),
        context,
        tags,
        id,
        booru,
      ),
    ];
  }
}

final _transparent = MemoryImage(kTransparentImage);
