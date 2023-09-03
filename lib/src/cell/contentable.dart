// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

/// Content of the file.
/// Classes which extend this can be displayed in the image view.
/// Android* classes should be represented differently.
/// There is no AndroidVideo because [ContentType.video] can display the videos in Android.
/// [NetImage] and [NetGif] are able to display local files, not only network ones.
sealed class Contentable {
  const Contentable();
}

/// Displays an error page in the image view.
class EmptyContent extends Contentable {
  const EmptyContent();
}

class AndroidGif extends Contentable {
  final String uri;
  final Size size;

  const AndroidGif({required this.uri, required this.size});
}

class AndroidVideo extends Contentable {
  final String uri;
  final Size size;

  const AndroidVideo({required this.uri, required this.size});
}

class AndroidImage extends Contentable {
  final String uri;
  final Size size;

  const AndroidImage({required this.uri, required this.size});
}

class NetImage extends Contentable {
  final ImageProvider provider;

  const NetImage(this.provider);
}

class NetGif extends Contentable {
  final ImageProvider provider;

  const NetGif(this.provider);
}

class NetVideo extends Contentable {
  final String uri;

  const NetVideo(this.uri);
}
