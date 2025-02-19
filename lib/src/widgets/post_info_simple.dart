// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/obj_impls/post_impl.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/post_info.dart";
import "package:azari/src/widgets/shimmer_loading_indicator.dart";
import "package:flutter/material.dart";
import "package:video_player/video_player.dart";

class PostInfoSimple extends StatelessWidget {
  const PostInfoSimple({
    super.key,
    required this.post,
  });

  final PostImpl post;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(padding: EdgeInsets.only(top: 18)),
        ListBody(
          children: [
            DimensionsName(
              l10n: l10n,
              width: post.width,
              height: post.height,
              name: post.id.toString(),
              icon: post.type.toIcon(),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
            ),
            PostInfoTile(post: post),
            const Padding(padding: EdgeInsets.only(top: 4)),
            const Divider(indent: 24, endIndent: 24),
            PostActionChips(post: post, addAppBarActions: true),
          ],
        ),
      ],
    );
  }
}

class PostSimpleVideo extends StatefulWidget {
  const PostSimpleVideo({
    super.key,
    required this.post,
  });

  final PostImpl post;

  @override
  State<PostSimpleVideo> createState() => _PostSimpleVideoState();
}

class _PostSimpleVideoState extends State<PostSimpleVideo> {
  late final VideoPlayerController controller;

  bool initalized = false;

  @override
  void initState() {
    super.initState();

    controller = VideoPlayerController.networkUrl(
      Uri.parse(
        widget.post.sampleUrl.isEmpty
            ? widget.post.fileUrl
            : widget.post.sampleUrl,
      ),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    controller.setVolume(0);
    controller.setLooping(true);

    controller.initialize().then((_) {
      if (context.mounted) {
        setState(() {
          controller.play();
          initalized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final aspectRatio = widget.post.width == 0 || widget.post.height == 0
    //     ? 1
    //     : widget.post.width / widget.post.height;

    return initalized
        ? LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: constraints.maxHeight,
              width: constraints.maxWidth,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  height: controller.value.size.height,
                  width: controller.value.size.width,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          )
        : const ShimmerLoadingIndicator();
  }
}
