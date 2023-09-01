// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class PhotoGalleryPageVideoLinux extends StatefulWidget {
  final String url;
  final bool localVideo;

  const PhotoGalleryPageVideoLinux(
      {super.key, required this.url, required this.localVideo});

  @override
  State<PhotoGalleryPageVideoLinux> createState() =>
      _PhotoGalleryPageVideoLinuxState();
}

class _PhotoGalleryPageVideoLinuxState
    extends State<PhotoGalleryPageVideoLinux> {
  final Player player = Player();
  VideoController? controller;

  @override
  void initState() {
    super.initState();

    controller = VideoController(player,
        configuration: const VideoControllerConfiguration(
            enableHardwareAcceleration: false));

    player.open(Media(widget.url));
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return controller == null
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : GestureDetector(
            onDoubleTap: () {
              player.playOrPause();
            },
            child: Video(controller: controller!),
          );
  }
}
