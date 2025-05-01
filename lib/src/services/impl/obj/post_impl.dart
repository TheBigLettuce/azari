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
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/booru/booru_page.dart";
import "package:azari/src/ui/material/widgets/grid_cell/cell.dart";
import "package:azari/src/ui/material/widgets/post_cell.dart";
import "package:azari/src/ui/material/widgets/post_info.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:path/path.dart" as path_util;
import "package:transparent_image/transparent_image.dart";
import "package:url_launcher/url_launcher.dart" as url;

final _transparent = MemoryImage(kTransparentImage);

extension PostDownloadExt on PostImpl {
  void download({PathVolume? thenMoveTo}) {
    const DownloadManager().addLocalTags(
      [
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
      ],
    );
  }
}

extension MultiplePostDownloadExt on List<PostImpl> {
  void downloadAll({
    PathVolume? thenMoveTo,
  }) {
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
    final url =
        thumb && type == PostContentType.image ? previewUrl : Post.getUrl(this);

    return path_util.extension(url) == ".zip" ? sampleUrl : url;
  }

  ImageProvider imageContent([bool thumb = false]) {
    final settings = const SettingsService().current;

    final url =
        thumb && type == PostContentType.image ? previewUrl : Post.getUrl(this);

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

  List<Widget> appBarIcons(BuildContext context) {
    final l10n = context.l10n();

    return [
      ActionChip(
        onPressed: () {
          url.launchUrl(
            booru.browserLink(id),
            mode: url.LaunchMode.externalApplication,
          );
        },
        avatar: const Icon(Icons.public),
        label: Text(l10n.openOnBooru(booru.string)),
      ),
      ActionChip(
        onPressed: () => const AppApi().shareMedia(fileUrl, url: true),
        avatar: const Icon(Icons.share),
        label: Text(l10n.shareLabel),
      ),
      StarsButton(
        idBooru: (id, booru),
      ),
    ];
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

    // final int columns = (context == null
    //         ? null
    //         : ShellConfiguration.maybeOf(context)?.columns.number) ??
    //     3;

    final columns = 3;

    return CachedNetworkImageProvider(
      sampleThumbnails &&
              columns <= 2 &&
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
    Alignment imageAlign = Alignment.center,
  }) =>
      PostCell(key: uniqueKey(), post: this);
}
