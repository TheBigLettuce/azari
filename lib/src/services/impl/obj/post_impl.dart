// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/logic/local_tags_helper.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/resource_source/chained_filter.dart";
import "package:azari/src/logic/resource_source/filtering_mode.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/widgets/grid_cell/cell.dart";
import "package:azari/src/ui/material/widgets/grid_cell/contentable.dart";
import "package:azari/src/ui/material/widgets/grid_cell/sticker.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view.dart";
import "package:azari/src/ui/material/widgets/post_cell.dart";
import "package:azari/src/ui/material/widgets/post_info.dart";
import "package:azari/src/ui/material/widgets/shell/parts/shell_configuration.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
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

abstract class PostImpl
    implements
        PostBase,
        SelectionWrapperBuilder,
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
      ParsedFilenameResult.makeFilename(booru, fileDownloadUrl(), md5, id);

  @override
  CellStaticData description() => const CellStaticData();

  @override
  Widget info(BuildContext context) => PostInfo(post: this);

  ResourceSource<int, T> getSource<T extends PostImpl>(BuildContext context) =>
      ResourceSource.maybeOf<int, T>(context)!;

  @override
  Widget buildSelectionWrapper<T extends CellBase>({
    required BuildContext context,
    required int thisIndx,
    required List<int>? selectFrom,
    required CellStaticData description,
    required VoidCallback? onPressed,
    required Widget child,
  }) {
    return WrapSelection(
      thisIndx: thisIndx,
      description: description,
      selectFrom: selectFrom,
      onPressed: onPressed,
      onDoubleTap: DownloadManager.available && LocalTagsService.available
          ? (context) {
              const downloadManager = DownloadManager();
              final status = downloadManager.statusFor(fileDownloadUrl());
              final downloadStatus = status?.data.status;

              if (downloadStatus == DownloadStatus.failed) {
                downloadManager.restartAll([status!]);
              } else {
                download();
              }
              WrapperSelectionAnimation.tryPlayOf(context);
            }
          : null,
      child: child,
    );
  }

  @override
  Widget buildCell<T extends CellBase>(
    BuildContext context,
    int idx,
    T cell, {
    required bool isList,
    required bool hideTitle,
    bool animated = false,
    bool blur = false,
    required Alignment imageAlign,
    required Widget Function(Widget child) wrapSelection,
  }) {
    return PostCell(
      key: uniqueKey(),
      wrapSelection: wrapSelection,
      post: this,
    );
  }

  @override
  List<NavigationAction> appBarButtons(BuildContext context) {
    final l10n = context.l10n();

    return [
      NavigationAction(
        Icons.public,
        () {
          url.launchUrl(
            booru.browserLink(id),
            mode: url.LaunchMode.externalApplication,
          );
        },
        l10n.openOnBooru(booru.string),
      ),
      NavigationAction(
        Icons.share,
        () => const AppApi().shareMedia(fileUrl, url: true),
        l10n.shareLabel,
      ),
      NavigationAction(
        Icons.star_rounded,
        null,
        "",
        StarsButton(
          idBooru: (id, booru),
        ),
      ),
    ];
  }

  @override
  List<ImageViewAction> actions(BuildContext context) {
    final theme = Theme.of(context);

    final favoritePosts = FavoritePostSourceService.safe();
    final hiddenPosts = HiddenBooruPostsService.safe();

    return [
      if (favoritePosts != null)
        ImageViewAction(
          Icons.favorite_border_rounded,
          (_) => favoritePosts.addRemove([this]),
          animate: true,
          watch: (f, [fire = false]) {
            return favoritePosts.cache
                .streamSingle(id, booru, fire)
                .map(
                  (isFavorite_) => (
                    isFavorite_
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    isFavorite_
                        ? Colors.red.harmonizeWith(theme.colorScheme.primary)
                        : null,
                    !isFavorite_,
                  ),
                )
                .listen(f);
          },
        ),
      if (DownloadManager.available && LocalTagsService.available)
        ImageViewAction(
          Icons.download,
          (_) => download(),
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
      if (hiddenPosts != null && this is! FavoritePost)
        ImageViewAction(
          Icons.hide_image_rounded,
          (_) {
            if (hiddenPosts.isHidden(id, booru)) {
              hiddenPosts.removeAll([(id, booru)]);
            } else {
              hiddenPosts.addAll([
                HiddenBooruPostData(
                  thumbUrl: previewUrl,
                  postId: id,
                  booru: booru,
                ),
              ]);
            }
          },
          watch: (f, [fire = false]) {
            return hiddenPosts
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
      // ImageViewAction(
      //   Icons.comment_rounded,
      //   (_) {
      //     final client = BooruAPI.defaultClientForBooru(booru);
      //     final api = BooruComunnityAPI.fromEnum(booru, client);

      //     final pageSaver = PageSaver.noPersist();

      //     Navigator.push<void>(
      //       context,
      //       ModalBottomSheetRoute(
      //         isScrollControlled: true,
      //         showDragHandle: true,
      //         builder: (context) {
      //           return WrapFutureRestartable(
      //             newStatus: () =>
      //                 api.comments.forPostId(postId: id, pageSaver: pageSaver),
      //             builder: (context, data) {
      //               return ListView.builder(
      //                 itemCount: data.length,
      //                 itemBuilder: (context, idx) {
      //                   return CommentTile(
      //                     comments: data[idx],
      //                   );
      //                 },
      //               );
      //             },
      //           );
      //         },
      //       ),
      //     ).whenComplete(() {
      //       client.close(force: true);
      //     });
      //   },
      //   animate: true,
      //   watch: (f, [fire = false]) => db.favoritePosts.watchSingle(
      //     id,
      //     booru,
      //     (isFavorite_) => (
      //       isFavorite_
      //           ? Icons.favorite_rounded
      //           : Icons.favorite_border_rounded,
      //       isFavorite_
      //           ? Colors.red.harmonizeWith(theme.colorScheme.primary)
      //           : null,
      //       !isFavorite_,
      //     ),
      //     f,
      //     fire,
      //   ),
      // ),
    ];
  }

  @override
  ImageProvider<Object> thumbnail(BuildContext? context) {
    final hiddenBooruPosts = HiddenBooruPostsService.safe();
    if (hiddenBooruPosts != null && hiddenBooruPosts.isHidden(id, booru)) {
      return _transparent;
    }

    final sampleThumbnails = const SettingsService().current.sampleThumbnails;

    final int columns = (context == null
            ? null
            : ShellConfiguration.maybeOf(context)?.columns.number) ??
        3;

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
  Contentable content(BuildContext context, [bool thumb = false]) {
    final settings = const SettingsService().current;

    final url =
        thumb && type == PostContentType.image ? previewUrl : Post.getUrl(this);

    final sampleThumbnails = settings.sampleThumbnails;
    final isOriginal = settings.quality == DisplayQuality.original;

    return switch (type) {
      PostContentType.none => EmptyContent(this),
      PostContentType.video => NetVideo(
          this,
          path_util.extension(url) == ".zip" ? sampleUrl : url,
        ),
      PostContentType.gif => NetGif(this, NetworkImage(url)),
      PostContentType.image => NetImage(
          this,
          thumb || (sampleThumbnails && !isOriginal)
              ? CachedNetworkImageProvider(url)
              : NetworkImage(url),
        ),
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
      final f = ChainedFilterResourceSource.maybeOf(context);
      final stars = f?.filteringMode.toStarsOrNull;
      final thisStars = (this as FavoritePost).stars;

      return [
        if (excludeDuplicate && score > 10)
          Sticker(
            score > 80 ? Icons.whatshot_rounded : Icons.thumb_up_rounded,
            subtitle: score.toString(),
            important: score > 80,
          ),
        if (f?.filteringMode == FilteringMode.onlyHalfStars ||
            f?.filteringMode == FilteringMode.onlyFullStars ||
            (f?.sortingMode == SortingMode.stars && thisStars.asNumber != 0) ||
            stars != null)
          Sticker(
            thisStars.asNumber == 0
                ? Icons.star_border_rounded
                : thisStars.isHalf
                    ? Icons.star_half_rounded
                    : Icons.star_rounded,
            subtitle:
                thisStars.asNumber == 0 ? null : thisStars.asNumber.toString(),
            important: thisStars.asNumber >= 2.5,
          ),
      ];
    }

    if (excludeDuplicate) {
      final icons = [
        if (score > 10)
          Sticker(
            score > 80 ? Icons.whatshot_rounded : Icons.thumb_up_rounded,
            subtitle: score.toString(),
            important: score > 80,
          ),
      ];

      return icons;
    }

    return const [];
  }
}
