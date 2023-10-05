// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/plugs/platform_fullscreens.dart';

class AndroidFullscreen implements PlatformFullscreensPlug {
  final Color overlayFullscreenColor;

  bool isOverlaySet = false;
  bool isAppbarShown = true;

  @override
  void fullscreen() {
    if (!isAppbarShown) {
      isAppbarShown = true;
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      isAppbarShown = false;
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
  }

  @override
  void unFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: overlayFullscreenColor,
      systemNavigationBarColor: overlayFullscreenColor,
    ));
  }

  @override
  void setTitle(String windowTitle) {
    if (!isOverlaySet) {
      isOverlaySet = true;
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
            systemNavigationBarColor: Colors.black.withOpacity(0.5)),
      );
    }
  }

  AndroidFullscreen(this.overlayFullscreenColor);
}
