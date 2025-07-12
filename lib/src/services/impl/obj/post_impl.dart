// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/logic/local_tags_helper.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/booru/booru_page.dart";
import "package:azari/src/ui/material/widgets/post_cell.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/cell_builder.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:path/path.dart" as path_util;
import "package:transparent_image/transparent_image.dart";

final _transparent = MemoryImage(kTransparentImage);

extension PostDownloadExt on PostImpl {
  void download({PathVolume? thenMoveTo}) {
    const DownloadManager().addLocalTags([
      DownloadEntryTags.d(
        tags: tags,
        name: ParsedFilenameResult.makeFilename(
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
    ]);
  }
}

extension MultiplePostDownloadExt on List<PostImpl> {
  void downloadAll({PathVolume? thenMoveTo}) {
    const DownloadManager().addLocalTags(
      map(
        (e) => DownloadEntryTags.d(
          tags: e.tags,
          name: ParsedFilenameResult.makeFilename(
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
    );
  }
}

abstract class PostImpl with CellBuilderData implements PostBase, CellBuilder {
  const PostImpl();

  String fileDownloadUrl() {
    if (path_util.extension(fileUrl) == ".zip") {
      return sampleUrl;
    } else {
      return fileUrl;
    }
  }

  String videoUrl([bool thumb = false]) {
    final url = thumb && type == PostContentType.image
        ? previewUrl
        : Post.getUrl(this);

    return path_util.extension(url) == ".zip" ? sampleUrl : url;
  }

  ImageProvider imageContent([bool thumb = false]) {
    final settings = const SettingsService().current;

    final url = thumb && type == PostContentType.image
        ? previewUrl
        : Post.getUrl(this);

    final sampleThumbnails = settings.sampleThumbnails;
    final isOriginal = settings.quality == DisplayQuality.original;

    if (type == PostContentType.gif) {
      return NetworkImage(url);
    } else if (type == PostContentType.image) {
      return thumb || (sampleThumbnails && !isOriginal)
          ? CachedNetworkImageProvider(url)
          : NetworkImage(url);
    }

    throw "Not image or gif: $this";
  }

  @override
  String title(AppLocalizations l10n) => id.toString();

  @override
  Key uniqueKey() => ValueKey(fileUrl);

  ResourceSource<int, PostImpl> getSource(BuildContext context) {
    if (this is FavoritePost) {
      return ResourceSource.maybeOf<int, FavoritePost>(context)!;
    }

    return ResourceSource.maybeOf<int, Post>(context)!;
  }

  @override
  ImageProvider<Object> thumbnail() {
    final hiddenBooruPosts = HiddenBooruPostsService.safe();
    if (hiddenBooruPosts != null && hiddenBooruPosts.isHidden(id, booru)) {
      return _transparent;
    }

    final sampleThumbnails = const SettingsService().current.sampleThumbnails;

    return CachedNetworkImageProvider(
      sampleThumbnails &&
              type != PostContentType.gif &&
              type != PostContentType.video
          ? sampleUrl
          : previewUrl,
    );
  }

  @override
  Widget buildCell(
    AppLocalizations l10n, {
    required CellType cellType,
    required bool hideName,
    bool blur = false,
    Alignment imageAlign = Alignment.center,
  }) =>
      PostCell(key: uniqueKey(), post: this, cellType: cellType, toBlur: blur);
}

Future<void> openPostAsync(
  BuildContext context, {
  required Booru booru,
  required int postId,
  Widget Function(Widget)? wrapNotifiers,
}) {
  if (!TagManagerService.available || !VisitedPostsService.available) {
    addAlert("openPostAsync", "Couldn't launch image view"); // TODO: change

    return Future.value();
  }

  final fnc = OnBooruTagPressed.of(context);

  return Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder(
      barrierDismissible: true,
      fullscreenDialog: true,
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      pageBuilder: (context, animation, secondaryAnimation) {
        return OnBooruTagPressed(
          onPressed: fnc,
          child: CardDialogStatic(
            animation: animation,
            getPost: () async {
              final dio = BooruAPI.defaultClientForBooru(booru);
              final api = BooruAPI.fromEnum(booru, dio);

              final Post post;
              try {
                post = await api.singlePost(postId);
              } catch (e) {
                rethrow;
              } finally {
                dio.close(force: true);
              }

              const VisitedPostsService().addAll([
                VisitedPost(
                  booru: booru,
                  id: postId,
                  thumbUrl: post.previewUrl,
                  rating: post.rating,
                  date: DateTime.now(),
                ),
              ]);

              return post;
            },
          ),
        );
      },
    ),
  );
}
