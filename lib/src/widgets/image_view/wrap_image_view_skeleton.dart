// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

class WrapImageViewSkeleton extends StatelessWidget {
  final Map<ShortcutActivator, void Function()> bindings;
  final Widget child;
  final bool canPop;
  final void Function(bool) onPopInvoked;
  final FocusNode mainFocus;
  final Widget bottomAppBar;
  final Widget? endDrawer;
  final PreferredSizeWidget appBar;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const WrapImageViewSkeleton(
      {super.key,
      required this.bindings,
      required this.canPop,
      required this.mainFocus,
      required this.scaffoldKey,
      required this.onPopInvoked,
      required this.appBar,
      required this.bottomAppBar,
      required this.endDrawer,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: canPop,
        onPopInvoked: onPopInvoked,
        child: CallbackShortcuts(
            bindings: bindings,
            child: Focus(
              autofocus: true,
              focusNode: mainFocus,
              child: Scaffold(
                key: scaffoldKey,
                extendBodyBehindAppBar: true,
                extendBody: true,
                endDrawerEnableOpenDragGesture: false,
                resizeToAvoidBottomInset: false,
                bottomNavigationBar: bottomAppBar,
                endDrawer: endDrawer,
                appBar: appBar,
                body: child,
              ),
            )));
  }
}
