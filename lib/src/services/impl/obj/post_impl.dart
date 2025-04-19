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

// class PostImageViewLoader extends DefaultImageViewLoader {
//   PostImageViewLoader({
//     required this.resource,
//     super.precacheThumbs = true,
//   });

//   late final StreamSubscription<int> _countEvents;

//   @override
//   void initCountEvents(Sink<int> sink) {
//     _countEvents = resource.backingStorage.countEvents.listen(sink.add);
//   }

//   @override
//   final ResourceSource<dynamic, PostImpl> resource;

//   @override
//   PhotoViewGalleryPageOptions? drawOptions(int i) {
//     final cell = get(i);
//     if (cell == null) {
//       return null;
//     }

//     final key = cell.uniqueKey();

//     return switch ((cell as PostImpl).type) {
//       PostContentType.none =>
//         PhotoViewGalleryPageOptions.customChild(child: const SizedBox.shrink()),
//       PostContentType.video => _makeVideo(
//           key,
//           cell.videoUrl(),
//           cell.thumbnail(),
//         ),
//       PostContentType.gif ||
//       PostContentType.image =>
//         _makeNetImage(key, cell.imageContent()),
//     };
//   }

//   PhotoViewGalleryPageOptions _makeVideo(
//     Key key,
//     String uri,
//     ImageProvider? networkThumb,
//   ) =>
//       PhotoViewGalleryPageOptions.customChild(
//         disableGestures: true,
//         tightMode: true,
//         child: PhotoGalleryPageVideo(
//           key: key,
//           url: uri,
//           networkThumb: networkThumb,
//           localVideo: false,
//         ),
//       );

//   PhotoViewGalleryPageOptions _makeNetImage(Key key, ImageProvider provider) {
//     final options = PhotoViewGalleryPageOptions(
//       key: ValueKey((key, refreshTries)),
//       minScale: PhotoViewComputedScale.contained * 0.8,
//       maxScale: PhotoViewComputedScale.covered * 1.8,
//       initialScale: PhotoViewComputedScale.contained,
//       filterQuality: FilterQuality.high,
//       imageProvider: provider,
//       errorBuilder: (context, error, stackTrace) {
//         return LoadingErrorWidget(
//           error: error.toString(),
//           short: false,
//           refresh: () {
//             // ReloadImageNotifier.of(context);
//           },
//         );
//       },
//     );

//     return options;
//   }

//   @override
//   List<ImageTag> tagsFor(int i) => resource
//       .forIdxUnsafe(i)
//       .tags
//       .map(
//         (e) => ImageTag(
//           e,
//           type: const TagManagerService().pinned.exists(e)
//               ? ImageTagType.favorite
//               : const TagManagerService().excluded.exists(e)
//                   ? ImageTagType.excluded
//                   : ImageTagType.normal,
//         ),
//       )
//       .toList();

//   @override
//   Stream<void> tagsEventsFor(int i) => const TagManagerService().pinned.events;

//   @override
//   void dispose() {
//     _countEvents.cancel();

//     super.dispose();
//   }
// }

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

  // final loader = PostImageViewLoader(
  //   resource: GenericListSource(() => Future.value(const [])),
  // );

  // // DefaultPostPressable.imageViewTags(c, const TagManagerService());

  // final stateController = DefaultStateController(
  //   loader: loader,
  //   wrapNotifiers: wrapNotifiers,
  //   // watchTags: (c, f) => DefaultPostPressable.watchTags(
  //   //   c,
  //   //   f,
  //   //   const TagManagerService().pinned,
  //   // ),
  // );

  // return ImageView.openAsync(
  //   context,
  // () async {
  //   final dio = BooruAPI.defaultClientForBooru(booru);
  //   final api = BooruAPI.fromEnum(booru, dio);

  //   final Post post;
  //   try {
  //     post = await api.singlePost(postId);
  //   } catch (e) {
  //     rethrow;
  //   } finally {
  //     dio.close(force: true);
  //   }

  //   const VisitedPostsService().addAll([
  //     VisitedPost(
  //       booru: booru,
  //       id: postId,
  //       thumbUrl: post.previewUrl,
  //       rating: post.rating,
  //       date: DateTime.now(),
  //     ),
  //   ]);

  //   loader.resource.backingStorage.clear();
  //   loader.resource.backingStorage.add(post);

  //   return stateController;
  // },
  // ).whenComplete(() {
  //   loader.dispose();
  //   stateController.dispose();
  //   loader.resource.destroy();
  // });
}

// mixin PostImageViewImpl implements ImageViewWidgets, PostImpl {
//   @override
//   List<Sticker> stickers(BuildContext context) {
//     if (this is FavoritePost) {
//       final f = ChainedFilterResourceSource.maybeOf(context);
//       final stars = f?.filteringMode.toStarsOrNull;
//       final thisStars = (this as FavoritePost).stars;

// // excludeDuplicate &&
//       return [
//         if (score > 10)
//           Sticker(
//             score > 80 ? Icons.whatshot_rounded : Icons.thumb_up_rounded,
//             subtitle: score.toString(),
//             important: score > 80,
//           ),
//         if (f?.filteringMode == FilteringMode.onlyHalfStars ||
//             f?.filteringMode == FilteringMode.onlyFullStars ||
//             (f?.sortingMode == SortingMode.stars && thisStars.asNumber != 0) ||
//             stars != null)
//           Sticker(
//             thisStars.asNumber == 0
//                 ? Icons.star_border_rounded
//                 : thisStars.isHalf
//                     ? Icons.star_half_rounded
//                     : Icons.star_rounded,
//             subtitle:
//                 thisStars.asNumber == 0 ? null : thisStars.asNumber.toString(),
//             important: thisStars.asNumber >= 2.5,
//           ),
//       ];
//     }

//     // if (excludeDuplicate) {
//     //   final icons = [
//     //     if (score > 10)
//     //       Sticker(
//     //         score > 80 ? Icons.whatshot_rounded : Icons.thumb_up_rounded,
//     //         subtitle: score.toString(),
//     //         important: score > 80,
//     //       ),
//     //   ];

//     //   return icons;
//     // }

//     return const [];
//   }

//   @override
//   Widget buildInfo(BuildContext context) => PostInfo(post: this);

//   @override
//   List<ImageViewAction> actions(BuildContext context) {
//     final theme = Theme.of(context);

//     final favoritePosts = FavoritePostSourceService.safe();
//     final hiddenPosts = HiddenBooruPostsService.safe();

//     return [
//       if (favoritePosts != null)
//         ImageViewAction(
//           Icons.favorite_border_rounded,
//           () => favoritePosts.addRemove([this]),
//           animate: true,
//           watch: (f, [fire = false]) {
//             return favoritePosts.cache
//                 .streamSingle(id, booru, fire)
//                 .map(
//                   (isFavorite_) => (
//                     isFavorite_
//                         ? Icons.favorite_rounded
//                         : Icons.favorite_border_rounded,
//                     isFavorite_
//                         ? Colors.red.harmonizeWith(theme.colorScheme.primary)
//                         : null,
//                     !isFavorite_,
//                   ),
//                 )
//                 .listen(f);
//           },
//         ),
//       if (DownloadManager.available && LocalTagsService.available)
//         ImageViewAction(
//           Icons.download,
//           () => download(),
//           animate: true,
//           animation: const [
//             SlideEffect(
//               curve: Easing.emphasizedAccelerate,
//               duration: Durations.medium1,
//               begin: Offset.zero,
//               end: Offset(0, -0.4),
//             ),
//             FadeEffect(
//               delay: Duration(milliseconds: 60),
//               curve: Easing.standard,
//               duration: Durations.medium1,
//               begin: 1,
//               end: 0,
//             ),
//           ],
//         ),
//       if (hiddenPosts != null && this is! FavoritePost)
//         ImageViewAction(
//           Icons.hide_image_rounded,
//           () {
//             if (hiddenPosts.isHidden(id, booru)) {
//               hiddenPosts.removeAll([(id, booru)]);
//             } else {
//               hiddenPosts.addAll([
//                 HiddenBooruPostData(
//                   thumbUrl: previewUrl,
//                   postId: id,
//                   booru: booru,
//                 ),
//               ]);
//             }
//           },
//           watch: (f, [fire = false]) {
//             return hiddenPosts
//                 .streamSingle(id, booru, fire)
//                 .map<(IconData?, Color?, bool?)>((e) {
//               return (
//                 null,
//                 e
//                     ? Colors.lightBlue.harmonizeWith(theme.colorScheme.primary)
//                     : null,
//                 null
//               );
//             }).listen(f);
//           },
//         ),
//       // ImageViewAction(
//       //   Icons.comment_rounded,
//       //   (_) {
//       //     final client = BooruAPI.defaultClientForBooru(booru);
//       //     final api = BooruComunnityAPI.fromEnum(booru, client);

//       //     final pageSaver = PageSaver.noPersist();

//       //     Navigator.push<void>(
//       //       context,
//       //       ModalBottomSheetRoute(
//       //         isScrollControlled: true,
//       //         showDragHandle: true,
//       //         builder: (context) {
//       //           return WrapFutureRestartable(
//       //             newStatus: () =>
//       //                 api.comments.forPostId(postId: id, pageSaver: pageSaver),
//       //             builder: (context, data) {
//       //               return ListView.builder(
//       //                 itemCount: data.length,
//       //                 itemBuilder: (context, idx) {
//       //                   return CommentTile(
//       //                     comments: data[idx],
//       //                   );
//       //                 },
//       //               );
//       //             },
//       //           );
//       //         },
//       //       ),
//       //     ).whenComplete(() {
//       //       client.close(force: true);
//       //     });
//       //   },
//       //   animate: true,
//       //   watch: (f, [fire = false]) => db.favoritePosts.watchSingle(
//       //     id,
//       //     booru,
//       //     (isFavorite_) => (
//       //       isFavorite_
//       //           ? Icons.favorite_rounded
//       //           : Icons.favorite_border_rounded,
//       //       isFavorite_
//       //           ? Colors.red.harmonizeWith(theme.colorScheme.primary)
//       //           : null,
//       //       !isFavorite_,
//       //     ),
//       //     f,
//       //     fire,
//       //   ),
//       // ),
//     ];
//   }
// }
