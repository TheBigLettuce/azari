// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/cell/sticker.dart';
import 'package:gallery/src/widgets/grid_frame/grid_frame.dart';

/// Content of the file.
/// Classes which extend this can be displayed in the image view.
/// Android* classes should be represented differently.
/// There is no AndroidVideo because [ContentType.video] can display the videos in Android.
/// [NetImage] and [NetGif] are able to display local files, not only network ones.
sealed class Contentable {
  const Contentable();

  Thumbnailable get thumbnail;
  ContentWidgets get widgets;
}

abstract interface class ContentWidgets {
  String title(BuildContext context);

  Widget? info(BuildContext context);
  List<Widget> appBarButtons(BuildContext context);
  List<ImageViewAction> actions(BuildContext context);

  List<Sticker> stickers(BuildContext context);

  Key uniquieKey(BuildContext context);

  static ContentWidgets empty(Key Function() f) => _EmptyWidgets(f);
}

class _EmptyWidgets implements ContentWidgets {
  const _EmptyWidgets(this.uniqueKeyF);

  final Key Function() uniqueKeyF;

  @override
  List<ImageViewAction> actions(BuildContext context) => const [];

  @override
  List<Widget> appBarButtons(BuildContext context) => const [];

  @override
  Widget? info(BuildContext context) => null;

  @override
  String title(BuildContext context) => "";

  @override
  Key uniquieKey(BuildContext context) => uniqueKeyF();

  @override
  List<Sticker> stickers(BuildContext context) => const [];
}

/// Displays an error page in the image view.
class EmptyContent extends Contentable {
  const EmptyContent(this.thumbnail, this.widgets);

  @override
  final ContentWidgets widgets;

  @override
  final Thumbnailable thumbnail;
}

class AndroidGif extends Contentable {
  const AndroidGif(this.thumbnail, this.widgets,
      {required this.uri, required this.size});

  final String uri;
  final Size size;

  @override
  final ContentWidgets widgets;

  @override
  final Thumbnailable thumbnail;
}

class AndroidVideo extends Contentable {
  const AndroidVideo(this.thumbnail, this.widgets,
      {required this.uri, required this.size});
  final String uri;
  final Size size;

  @override
  final ContentWidgets widgets;

  @override
  final Thumbnailable thumbnail;
}

class AndroidImage extends Contentable {
  const AndroidImage(this.thumbnail, this.widgets,
      {required this.uri, required this.size});

  final String uri;
  final Size size;

  @override
  final ContentWidgets widgets;

  @override
  final Thumbnailable thumbnail;
}

class NetImage extends Contentable {
  const NetImage(this.thumbnail, this.widgets, this.provider);

  final ImageProvider provider;

  @override
  final ContentWidgets widgets;

  @override
  final Thumbnailable thumbnail;
}

class NetGif extends Contentable {
  const NetGif(this.thumbnail, this.widgets, this.provider);

  final ImageProvider provider;

  @override
  final ContentWidgets widgets;

  @override
  final Thumbnailable thumbnail;
}

class NetVideo extends Contentable {
  const NetVideo(this.thumbnail, this.widgets, this.uri);

  final String uri;

  @override
  final ContentWidgets widgets;

  @override
  final Thumbnailable thumbnail;
}
