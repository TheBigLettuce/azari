// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/base/booru_post_functionality_mixin.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/db/tags/post_tags.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/display_quality.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/interfaces/cached_db_values.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/interfaces/cell/contentable.dart";
import "package:gallery/src/interfaces/cell/sticker.dart";
import "package:gallery/src/net/download_manager/download_manager.dart";
import "package:gallery/src/pages/more/favorite_booru_actions.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/image_view/image_view.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:isar/isar.dart";
import "package:mime/mime.dart" as mime;
import "package:path/path.dart" as path_util;
import "package:transparent_image/transparent_image.dart";
import "package:url_launcher/url_launcher.dart";

class PostCacheValues implements CacheElement {
  List<Sticker>? _stickers;

  String? _url;

  List<ImageViewAction>? _actions;

  List<ImageViewAction> actions(BuildContext context, Post post) {
    if (_actions != null) {
      return _actions!;
    }

    final db = DatabaseConnectionNotifier.of(context);
    final favorites = db.favoritePosts;
    final hidden = db.hiddenBooruPost;

    final isFavorite = favorites.isFavorite(post.id, post.booru);

    return _actions = [
      ImageViewAction(
        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        (_) {
          favorites.addRemove(context, [post], true);
          // db.localTagDictionary.add(post.tags);
        },
        play: !isFavorite,
        color: isFavorite
            ? Colors.red.harmonizeWith(Theme.of(context).colorScheme.primary)
            : null,
        animate: true,
      ),
      if (post is FavoritePostData)
        FavoritesActions.addToGroup<CellBase>(
          context,
          (selected) => (selected.first as FavoritePostData).group,
          (selected, value, toPin) {
            for (final FavoritePostData e in selected.cast()) {
              e.group = value.isEmpty ? null : value;
            }

            favorites.addAllFileUrl(selected.cast());

            Navigator.of(context, rootNavigator: true).pop();
          },
          false,
        ).asImageView(post),
      ImageViewAction(
        Icons.download,
        (_) => post.download(context),
        animate: true,
      ),
      if (post is! FavoritePostData)
        ImageViewAction(
          Icons.hide_image_rounded,
          (_) {
            if (hidden.isHidden(post.id, post.booru)) {
              hidden.removeAll([(post.id, post.booru)]);
            } else {
              hidden.addAll([
                HiddenBooruPostData.forDb(post.previewUrl, post.id, post.booru),
              ]);
            }
          },
          color: hidden.isHidden(post.id, post.booru)
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
    ];
  }

  String url(BuildContext context, Post post) {
    if (_url != null) {
      return _url!;
    }

    return _url = switch (SettingsService.db().current.quality) {
      DisplayQuality.original => post.fileUrl,
      DisplayQuality.sample => post.sampleUrl
    };
  }

  // bool isHidden(BuildContext context, Post post) {
  //   if (_isHidden != null) {
  //     return _isHidden!;
  //   }

  //   return _isHidden = DatabaseConnectionNotifier.of(context)
  //       .hiddenBooruPost
  //       .isHidden(post.id, post.booru);
  // }

  // PostContentType type(BuildContext context, Post post) {
  //   if (_type != null) {
  //     return _type!;
  //   }

  //   final url_ = url(context, post);

  //   final type = mime.lookupMimeType(url_);
  //   if (type == null) {
  //     return _type = PostContentType.none;
  //   }

  //   final typeHalf = type.split("/");

  //   if (typeHalf[0] == "image") {
  //     return _type =
  //         typeHalf[1] == "gif" ? PostContentType.gif : PostContentType.image;
  //   } else if (typeHalf[0] == "video") {
  //     return _type = PostContentType.video;
  //   } else {
  //     return _type = PostContentType.none;
  //   }
  // }

  List<Sticker> stickers(
    BuildContext context,
    bool excludeDuplicate,
    Post post,
  ) {
    if (_stickers != null) {
      return _stickers!;
    }

    if (excludeDuplicate) {
      final icons = defaultStickersPost(
        post.type,
        context,
        post.tags,
        post.id,
        post.booru,
      );

      return _stickers = icons.isEmpty ? const [] : icons;
    }

    final db = DatabaseConnectionNotifier.of(context);

    final isHidden = db.hiddenBooruPost.isHidden(post.id, post.booru);

    return _stickers = [
      if (isHidden) const Sticker(Icons.hide_image_rounded),
      if (post is! FavoritePostData &&
          db.favoritePosts.isFavorite(post.id, post.booru))
        const Sticker(Icons.favorite_rounded, important: true),
      ...defaultStickersPost(
        post.type,
        context,
        post.tags,
        post.id,
        post.booru,
      ),
    ];
  }
}

class PostValuesCache with SimpleMapCache implements CachedDbValues {
  PostValuesCache();

  factory PostValuesCache.of(BuildContext context) =>
      ValuesCache.of<PostValuesCache>(context);
}

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

abstract class PostBase {
  const PostBase({
    required this.id,
    required this.height,
    required this.md5,
    required this.tags,
    required this.width,
    required this.fileUrl,
    required this.booru,
    required this.previewUrl,
    required this.sampleUrl,
    required this.sourceUrl,
    required this.rating,
    required this.score,
    required this.createdAt,
    required this.type,
    // this.isHidden = false,
  });

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

  @Index()
  @enumerated
  final PostRating rating;
  final int score;
  final DateTime createdAt;
  @enumerated
  final Booru booru;

  @enumerated
  final PostContentType type;
}

mixin DefaultPostPressable implements Pressable<Post> {
  @override
  void onPress(
    BuildContext context,
    GridFunctionality<Post> functionality,
    PostBase cell,
    int idx,
  ) {
    final tagManager = TagManager.of(context);

    ImageView.defaultForGrid<Post>(
      context,
      functionality,
      ImageViewDescription(
        ignoreOnNearEnd: false,
        statistics: StatisticsBooruService.asImageViewStatistics(),
      ),
      idx,
      (c) => _imageViewTags(c, tagManager),
      (c, f) => _watchTags(c, f, tagManager),
    );
  }

  List<ImageTag> _imageViewTags(Contentable c, TagManager tagManager) =>
      (c.widgets as PostBase)
          .tags
          .map((e) => ImageTag(e, tagManager.pinned.exists(e)))
          .toList();

  StreamSubscription<List<ImageTag>> _watchTags(
    Contentable c,
    void Function(List<ImageTag> l) f,
    TagManager tagManager,
  ) =>
      tagManager.pinned.watchImage((c.widgets as PostBase).tags, f);
}

extension MultiplePostDownloadExt on List<Post> {
  void downloadAll(BuildContext context) {
    DownloadManager.of(context).addLocalTags(
      map(
        (e) => DownloadEntryTags.d(
          tags: e.tags,
          name: DisassembleResult.makeFilename(
            e.booru,
            e.fileDownloadUrl(),
            e.md5,
            e.id,
          ),
          url: e.fileDownloadUrl(),
          thumbUrl: e.previewUrl,
          site: e.booru.url,
        ),
      ),
      SettingsService.db().current,
      PostTags.fromContext(context),
    );
  }
}

extension PostDownloadExt on Post {
  void download(BuildContext context) {
    DownloadManager.of(context).addLocalTags(
      [
        DownloadEntryTags.d(
          tags: tags,
          name: DisassembleResult.makeFilename(
            booru,
            fileDownloadUrl(),
            md5,
            id,
          ),
          url: fileDownloadUrl(),
          thumbUrl: previewUrl,
          site: booru.url,
        ),
      ],
      SettingsService.db().current,
      PostTags.fromContext(context),
    );
  }
}

abstract mixin class Post
    implements
        PostBase,
        ContentableCell,
        Thumbnailable,
        ContentWidgets,
        AppBarButtonable,
        ImageViewActionable,
        Infoable,
        Stickerable,
        Downloadable,
        Pressable<Post> {
  static String _getUrl(Post p) {
    var url = switch (SettingsService.db().current.quality) {
      DisplayQuality.original => p.fileUrl,
      DisplayQuality.sample => p.sampleUrl
    };
    if (url.isEmpty) {
      url = p.sampleUrl.isNotEmpty
          ? p.sampleUrl
          : p.fileUrl.isEmpty
              ? p.previewUrl
              : p.fileUrl;
    }

    return url;
  }

  static PostContentType makeType(Post p) {
    final url = _getUrl(p);

    final t = mime.lookupMimeType(url);
    if (t == null) {
      return PostContentType.none;
    }

    final typeHalf = t.split("/");

    if (typeHalf[0] == "image") {
      return typeHalf[1] == "gif" ? PostContentType.gif : PostContentType.image;
    } else if (typeHalf[0] == "video") {
      return PostContentType.video;
    } else {
      throw "";
    }
  }

  PostCacheValues _cache(BuildContext context) => PostValuesCache.of(context)
      .putIfAbsent(uniqueKey(), () => PostCacheValues());
  String _makeName() =>
      DisassembleResult.makeFilename(booru, fileDownloadUrl(), md5, id);

  @override
  CellStaticData description() => const CellStaticData();

  @override
  Widget info(BuildContext context) => PostInfo(post: this);

  @override
  List<Widget> appBarButtons(BuildContext context) {
    return [
      OpenInBrowserButton(
        Uri.base,
        overrideOnPressed: () {
          launchUrl(
            booru.browserLink(id),
            mode: LaunchMode.externalApplication,
          );
        },
      ),
      // if (Platform.isAndroid)
      ShareButton(
        fileUrl,
        onLongPress: () {
          showQr(context, booru.prefix, id);
        },
      )
      // else
      // IconButton(
      // onPressed: () {
      // showQr(context, booru.prefix, id);
      // },
      // icon: const Icon(Icons.qr_code_rounded),
      // ),
    ];
  }

  @override
  List<ImageViewAction> actions(BuildContext context) =>
      _cache(context).actions(context, this);

  @override
  ImageProvider<Object> thumbnail() {
    // if (isHidden) {
    //   return _transparent;
    // }

    return CachedNetworkImageProvider(previewUrl);
  }

  @override
  Contentable content() {
    // final values = _cache(context);

    // if (isHidden) {
    //   return EmptyContent(this);
    // }

    final url = _getUrl(this);

    return switch (type) {
      PostContentType.none => EmptyContent(this),
      PostContentType.video => NetVideo(
          this,
          path_util.extension(url) == ".zip" ? sampleUrl : url,
        ),
      PostContentType.gif => NetGif(this, NetworkImage(url)),
      PostContentType.image => NetImage(this, NetworkImage(url)),
    };
  }

  @override
  Key uniqueKey() => ValueKey(fileUrl);

  @override
  String alias(bool isList) => isList ? _makeName() : id.toString();

  @override
  String fileDownloadUrl() {
    if (path_util.extension(fileUrl) == ".zip") {
      return sampleUrl;
    } else {
      return fileUrl;
    }
  }

  @override
  List<Sticker> stickers(BuildContext context, bool excludeDuplicate) =>
      _cache(context).stickers(context, excludeDuplicate, this);
}

final _transparent = MemoryImage(kTransparentImage);
