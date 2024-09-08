// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/post_tags.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/post_functions.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/plugs/platform_functions.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/sticker.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/image_view/image_view.dart";
import "package:azari/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:mime/mime.dart" as mime;
import "package:path/path.dart" as path_util;
import "package:transparent_image/transparent_image.dart";
import "package:url_launcher/url_launcher.dart";

final _transparent = MemoryImage(kTransparentImage);

abstract class PostImpl
    implements
        PostBase,
        ContentableCell,
        Thumbnailable,
        ContentWidgets,
        AppBarButtonable,
        ImageViewActionable,
        Infoable,
        Stickerable,
        Downloadable {
  const PostImpl();

  String _makeName() =>
      DisassembleResult.makeFilename(booru, fileDownloadUrl(), md5, id);

  @override
  CellStaticData description() => const CellStaticData();

  @override
  Widget info(BuildContext context) => PostInfo(post: this);

  @override
  List<NavigationAction> appBarButtons(BuildContext context) {
    return [
      NavigationAction(
        Icons.public,
        () {
          launchUrl(
            booru.browserLink(id),
            mode: LaunchMode.externalApplication,
          );
        },
      ),
      NavigationAction(
        Icons.share,
        () {
          PlatformApi.current().shareMedia(fileUrl, url: true);
        },
      ),
    ];
  }

  @override
  List<ImageViewAction> actions(BuildContext context) {
    final theme = Theme.of(context);

    final db = DatabaseConnectionNotifier.of(context);
    final favorites = db.favoritePosts;
    final hidden = db.hiddenBooruPost;

    return [
      ImageViewAction(
        Icons.favorite_border_rounded,
        (_) => favorites.addRemove([this]),
        animate: true,
        watch: (f, [fire = false]) => db.favoritePosts.watchSingle(
          id,
          booru,
          (isFavorite_) => (
            isFavorite_
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            isFavorite_
                ? Colors.red.harmonizeWith(theme.colorScheme.primary)
                : null,
            !isFavorite_,
          ),
          f,
          fire,
        ),
      ),
      ImageViewAction(
        Icons.download,
        (_) => download(
          DownloadManager.of(context),
          PostTags.fromContext(context),
        ),
        animate: true,
        animation: const [
          SlideEffect(
            curve: Easing.emphasizedAccelerate,
            duration: Durations.medium1,
            begin: Offset.zero,
            end: Offset(0, -0.4),
          ),
          FadeEffect(
            delay: Duration(milliseconds: 60),
            curve: Easing.standard,
            duration: Durations.medium1,
            begin: 1,
            end: 0,
          ),
        ],
      ),
      if (this is! FavoritePost)
        ImageViewAction(
          Icons.hide_image_rounded,
          (_) {
            if (hidden.isHidden(id, booru)) {
              hidden.removeAll([(id, booru)]);
            } else {
              hidden.addAll([
                HiddenBooruPostData(
                  thumbUrl: previewUrl,
                  postId: id,
                  booru: booru,
                ),
              ]);
            }
          },
          watch: (f, [fire = false]) {
            return hidden
                .streamSingle(id, booru, fire)
                .map<(IconData?, Color?, bool?)>((e) {
              return (
                null,
                e
                    ? Colors.lightBlue.harmonizeWith(theme.colorScheme.primary)
                    : null,
                null
              );
            }).listen(f);
          },
        ),
    ];
  }

  @override
  ImageProvider<Object> thumbnail() {
    if (HiddenBooruPostService.db().isHidden(id, booru)) {
      return _transparent;
    }

    return CachedNetworkImageProvider(previewUrl);
  }

  @override
  Contentable content() {
    final url = Post.getUrl(this);

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
  List<Sticker> stickers(BuildContext context, bool excludeDuplicate) {
    if (this is FavoritePost) {
      return defaultStickersPost(
        type,
        context,
        tags,
        id,
        booru,
      );
    }

    if (excludeDuplicate) {
      final icons = defaultStickersPost(
        type,
        context,
        tags,
        id,
        booru,
      );

      return icons.isEmpty ? const [] : icons;
    }

    final db = DatabaseConnectionNotifier.of(context);

    final isHidden = db.hiddenBooruPost.isHidden(id, booru);

    return [
      if (score > 10)
        Sticker(
          score > 80 ? Icons.whatshot_rounded : Icons.thumb_up_rounded,
          subtitle: score.toString(),
          important: score > 80,
        ),
      if (isHidden) const Sticker(Icons.hide_image_rounded),
      if (db.favoritePosts.isFavorite(id, booru))
        const Sticker(Icons.favorite_rounded, important: true),
      ...defaultStickersPost(
        type,
        context,
        tags,
        id,
        booru,
      ),
    ];
  }
}

enum PostRating {
  general,
  sensitive,
  questionable,
  explicit;

  String translatedName(AppLocalizations l10n) => switch (this) {
        PostRating.general => l10n.enumPostRatingGeneral,
        PostRating.sensitive => l10n.enumPostRatingSensitive,
        PostRating.questionable => l10n.enumPostRatingQuestionable,
        PostRating.explicit => l10n.enumPostRatingExplicit,
      };

  SafeMode get asSafeMode => switch (this) {
        PostRating.general => SafeMode.normal,
        PostRating.sensitive => SafeMode.relaxed,
        PostRating.questionable || PostRating.explicit => SafeMode.none,
      };
}

enum PostContentType {
  none,
  video,
  gif,
  image;

  static PostContentType fromUrl(String url) {
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
}

abstract class PostBase {
  const PostBase();

  int get id;

  String get md5;

  List<String> get tags;

  int get width;
  int get height;

  String get fileUrl;
  String get previewUrl;
  String get sampleUrl;
  String get sourceUrl;
  PostRating get rating;
  int get score;
  DateTime get createdAt;
  Booru get booru;
  PostContentType get type;
}

mixin DefaultPostPressable<T extends PostImpl> implements Pressable<T> {
  @override
  void onPress(
    BuildContext context,
    GridFunctionality<T> functionality,
    T cell,
    int idx,
  ) {
    final db = DatabaseConnectionNotifier.of(context);
    final tagManager = TagManager.of(context);

    ImageView.defaultForGrid<T>(
        context,
        functionality,
        ImageViewDescription(
          ignoreOnNearEnd: false,
          statistics: StatisticsBooruService.asImageViewStatistics(),
        ),
        idx,
        (c) => imageViewTags(c, tagManager),
        (c, f) => watchTags(c, f, tagManager), (post) {
      db.visitedPosts.addAll([
        VisitedPost(
          booru: post.booru,
          id: post.id,
          thumbUrl: post.previewUrl,
          date: DateTime.now(),
        ),
      ]);
    });
  }

  static List<ImageTag> imageViewTags(Contentable c, TagManager tagManager) =>
      (c.widgets as PostBase)
          .tags
          .map(
            (e) => ImageTag(
              e,
              favorite: tagManager.pinned.exists(e),
              excluded: tagManager.excluded.exists(e),
            ),
          )
          .toList();

  static StreamSubscription<List<ImageTag>> watchTags(
    Contentable c,
    void Function(List<ImageTag> l) f,
    TagManager tagManager,
  ) =>
      tagManager.pinned.watchImage((c.widgets as PostBase).tags, f);
}

extension MultiplePostDownloadExt on List<PostImpl> {
  void downloadAll(
    DownloadManager downloadManager,
    PostTags postTags, [
    PathVolume? thenMoveTo,
  ]) {
    downloadManager.addLocalTags(
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
          thenMoveTo: thenMoveTo,
        ),
      ),
      SettingsService.db().current,
      postTags,
    );
  }
}

extension PostDownloadExt on PostImpl {
  void download(
    DownloadManager downloadManager,
    PostTags postTags, [
    PathVolume? thenMoveTo,
  ]) {
    downloadManager.addLocalTags(
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
          thenMoveTo: thenMoveTo,
        ),
      ],
      SettingsService.db().current,
      postTags,
    );
  }
}
