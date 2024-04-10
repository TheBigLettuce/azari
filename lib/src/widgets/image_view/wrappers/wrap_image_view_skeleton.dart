// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/cell/contentable.dart';
import 'package:gallery/src/widgets/image_view/app_bar/end_drawer.dart';
import 'package:gallery/src/widgets/notifiers/focus.dart';
import 'package:gallery/src/widgets/notifiers/image_view_info_tiles_refresh_notifier.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../notifiers/current_content.dart';
import '../app_bar/app_bar.dart';

class WrapImageViewSkeleton extends StatelessWidget {
  final FocusNode mainFocus;
  final Widget? bottomAppBar;
  final ScrollController scrollController;
  final PaletteGenerator? currentPalette;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final AnimationController controller;

  final Widget child;

  const WrapImageViewSkeleton({
    super.key,
    required this.mainFocus,
    required this.controller,
    required this.scaffoldKey,
    required this.currentPalette,
    required this.bottomAppBar,
    required this.scrollController,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final widgets = CurrentContentNotifier.of(context).widgets;
    final b = widgets.tryAsAppBarButtonable(context);

    return Scaffold(
      key: scaffoldKey,
      extendBodyBehindAppBar: true,
      extendBody: true,
      endDrawerEnableOpenDragGesture: false,
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: bottomAppBar,
      endDrawer: widgets is! Infoable
          ? null
          : Builder(
              builder: (context) {
                FocusNotifier.of(context);
                ImageViewInfoTilesRefreshNotifier.of(context);

                final info = (widgets as Infoable).info(context);

                return ImageViewEndDrawer(
                  scrollController: scrollController,
                  sliver: info,
                );
              },
            ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 4),
        child: ImageViewAppBar(
          actions: b,
          controller: controller,
        ),
      ),
      body: child,
    );
  }
}
