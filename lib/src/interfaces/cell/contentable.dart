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

extension ContentWidgetsExt on ContentWidgets {
  List<ImageViewAction> tryAsActionable(BuildContext context) {
    if (this is ImageViewActionable) {
      return (this as ImageViewActionable).actions(context);
    }

    return const [];
  }

  List<Widget> tryAsAppBarButtonable(BuildContext context) {
    if (this is AppBarButtonsable) {
      return (this as AppBarButtonsable).appBarButtons(context);
    }

    return const [];
  }

  Widget? tryAsInfoable(BuildContext context) {
    if (this is Infoable) {
      return (this as Infoable).info(context);
    }

    return null;
  }

  List<Sticker> tryAsStickerable(BuildContext context, bool excludeDuplicate) {
    if (this is Stickerable) {
      return (this as Stickerable).stickers(context, excludeDuplicate);
    }

    return const [];
  }

  ImageProvider? tryAsThumbnailable() {
    if (this is Thumbnailable) {
      return (this as Thumbnailable).thumbnail();
    }

    return null;
  }
}

/// Content of the file.
/// Classes which extend this can be displayed in the image view.
/// Android* classes should be represented differently.
/// There is no AndroidVideo because [ContentType.video] can display the videos in Android.
/// [NetImage] and [NetGif] are able to display local files, not only network ones.
sealed class Contentable {
  const Contentable();

  ContentWidgets get widgets;
}

abstract interface class ContentWidgets implements UniqueKeyable, Aliasable {}

abstract interface class ImageViewActionable {
  List<ImageViewAction> actions(BuildContext context);
}

abstract interface class AppBarButtonsable {
  List<Widget> appBarButtons(BuildContext context);
}

abstract interface class Infoable {
  Widget info(BuildContext context);
}

/// Displays an error page in the image view.
class EmptyContent extends Contentable {
  const EmptyContent(this.widgets);

  @override
  final ContentWidgets widgets;
}

class AndroidGif extends Contentable {
  const AndroidGif(this.widgets, {required this.uri, required this.size});

  final String uri;
  final Size size;

  @override
  final ContentWidgets widgets;
}

class AndroidVideo extends Contentable {
  const AndroidVideo(this.widgets, {required this.uri, required this.size});
  final String uri;
  final Size size;

  @override
  final ContentWidgets widgets;
}

class AndroidImage extends Contentable {
  const AndroidImage(this.widgets, {required this.uri, required this.size});

  final String uri;
  final Size size;

  @override
  final ContentWidgets widgets;
}

class NetImage extends Contentable {
  const NetImage(this.widgets, this.provider);

  final ImageProvider provider;

  @override
  final ContentWidgets widgets;
}

class NetGif extends Contentable {
  const NetGif(this.widgets, this.provider);

  final ImageProvider provider;

  @override
  final ContentWidgets widgets;
}

class NetVideo extends Contentable {
  const NetVideo(this.widgets, this.uri);

  final String uri;

  @override
  final ContentWidgets widgets;
}
