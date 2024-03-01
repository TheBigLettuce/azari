// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../gesture_dead_zones.dart';
import '../keybinds/describe_keys.dart';
import '../keybinds/keybind_description.dart';
import '../keybinds/single_activator_description.dart';
import 'skeleton_state.dart';

class SettingsSkeleton extends StatelessWidget {
  final String pageDescription;
  final SkeletonState state;
  final Widget child;
  final PreferredSizeWidget? appBar;
  final bool extendBodyBehindAppBar;
  final bool extendBody;
  final bool expectSliverBody;
  final bool autofocus;

  const SettingsSkeleton(
    this.pageDescription,
    this.state, {
    super.key,
    this.appBar,
    required this.child,
    this.expectSliverBody = true,
    this.extendBody = false,
    this.autofocus = true,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    Map<SingleActivatorDescription, Null Function()> bindings = {
      SingleActivatorDescription(AppLocalizations.of(context)!.back,
          const SingleActivator(LogicalKeyboardKey.escape)): () {
        Navigator.pop(context);
      },
    };

    final insets = MediaQuery.viewPaddingOf(context);

    return CallbackShortcuts(
        bindings: {
          ...bindings,
          ...keybindDescription(
              context, describeKeys(bindings), pageDescription, () {
            state.mainFocus.requestFocus();
          })
        },
        child: Focus(
          autofocus: autofocus,
          focusNode: state.mainFocus,
          child: Scaffold(
            extendBody: extendBody,
            extendBodyBehindAppBar: extendBodyBehindAppBar,
            drawerEnableOpenDragGesture:
                MediaQuery.systemGestureInsetsOf(context) == EdgeInsets.zero,
            key: state.scaffoldKey,
            appBar: appBar,
            body: GestureDeadZones(
                left: true,
                right: true,
                child: appBar == null && expectSliverBody
                    ? CustomScrollView(
                        slivers: [
                          SliverAppBar.large(
                            expandedHeight: 160,
                            flexibleSpace: FlexibleSpaceBar(
                              title: Text(
                                pageDescription,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.only(bottom: insets.bottom),
                            sliver: child,
                          )
                        ],
                      )
                    : child),
          ),
        ));
  }
}
