// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/system_gestures.dart';

import '../keybinds/keybinds.dart';
import '../pages/senitel.dart';
import 'drawer/add_rail.dart';
import 'drawer/drawer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Widget makeGridSkeleton(
    BuildContext context,
    int index,
    Future<bool> Function() onWillPop,
    GlobalKey<ScaffoldState> scaffoldKey,
    CallbackGrid grid) {
  return WillPopScope(
    onWillPop: onWillPop,
    child: Scaffold(
        endDrawerEnableOpenDragGesture: false,
        key: scaffoldKey,
        drawer: makeDrawer(context, index),
        endDrawer: makeEndDrawerSettings(context, scaffoldKey),
        body: gestureDeadZones(
          context,
          child: addRail(context, index, scaffoldKey, grid),
        )),
  );
}

Widget makeSkeletonSettings(BuildContext context, String pageDescription,
    GlobalKey<ScaffoldState> key, FocusNode focus, Widget child) {
  Map<SingleActivatorDescription, Null Function()> bindings = {
    SingleActivatorDescription(AppLocalizations.of(context)!.back,
        const SingleActivator(LogicalKeyboardKey.escape)): () {
      Navigator.pop(context);
    },
  };

  return CallbackShortcuts(
      bindings: {
        ...bindings,
        ...keybindDescription(context, describeKeys(bindings), pageDescription)
      },
      child: Focus(
        autofocus: true,
        focusNode: focus,
        child: Scaffold(
          key: key,
          body: gestureDeadZones(context,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar.large(
                    expandedHeight: 160,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(pageDescription),
                    ),
                  ),
                  child
                ],
              )),
        ),
      ));
}

Widget makeSkeletonInnerSettings(BuildContext context, String pageDescription,
    FocusNode focus, List<Widget> children) {
  Map<SingleActivatorDescription, Null Function()> bindings = {
    SingleActivatorDescription(AppLocalizations.of(context)!.back,
        const SingleActivator(LogicalKeyboardKey.escape)): () {
      Navigator.pop(context);
    },
  };

  return CallbackShortcuts(
      bindings: {
        ...bindings,
        ...keybindDescription(context, describeKeys(bindings), pageDescription)
      },
      child: Focus(
        autofocus: true,
        focusNode: focus,
        child: Scaffold(
          body: gestureDeadZones(context,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar.large(
                    expandedHeight: 160,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(pageDescription),
                    ),
                  ),
                  SliverList(delegate: SliverChildListDelegate(children))
                ],
              )),
        ),
      ));
}

Widget makeSkeleton(BuildContext context, int drawerIndex,
    String pageDescription, GlobalKey<ScaffoldState> key, FocusNode focus,
    {Future<bool> Function()? overrideOnPop,
    List<Widget>? children,
    Widget Function(BuildContext context, int indx)? builder,
    Map<SingleActivatorDescription, Null Function()>? additionalBindings,
    bool popSenitel = true,
    int? itemCount,
    List<Widget>? appBarActions,
    Widget? customTitle}) {
  if (children == null && builder == null ||
      children != null && builder != null) {
    throw "only one should be specified";
  }

  if (builder != null && itemCount == null) {
    throw "itemCount should be supplied";
  }

  Map<SingleActivatorDescription, Null Function()> bindings = {
    SingleActivatorDescription(AppLocalizations.of(context)!.back,
        const SingleActivator(LogicalKeyboardKey.escape)): () {
      if (key.currentState != null) {
        if (key.currentState!.hasEndDrawer &&
            key.currentState!.isEndDrawerOpen) {
          key.currentState?.closeEndDrawer();
        } else {
          if (popSenitel) {
            popUntilSenitel(context);
          } else {
            Navigator.pop(context);
          }
        }
      } else {
        if (popSenitel) {
          popUntilSenitel(context);
        } else {
          Navigator.pop(context);
        }
      }
    },
    if (additionalBindings != null) ...additionalBindings,
    ...digitAndSettings(context, drawerIndex, key)
  };

  return CallbackShortcuts(
      bindings: {
        ...bindings,
        ...keybindDescription(context, describeKeys(bindings), pageDescription)
      },
      child: Focus(
          autofocus: true,
          focusNode: focus,
          child: WillPopScope(
            onWillPop: () => overrideOnPop != null
                ? overrideOnPop()
                : popUntilSenitel(context),
            child: Scaffold(
              key: key,
              drawer: makeDrawer(context, drawerIndex),
              endDrawer: makeEndDrawerSettings(context, key),
              body: gestureDeadZones(context,
                  child: addRail(
                      context,
                      drawerIndex,
                      key,
                      CustomScrollView(
                        slivers: [
                          SliverAppBar(
                            expandedHeight: 152,
                            collapsedHeight: 64,
                            automaticallyImplyLeading: true,
                            actions: [Container()],
                            flexibleSpace: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: FlexibleSpaceBar(
                                        title: customTitle ??
                                            Text(pageDescription))),
                                if (appBarActions != null)
                                  ...appBarActions
                                      .map((e) => wrapAppBarAction(e))
                                      .toList()
                              ],
                            ),
                          ),
                          if (children != null)
                            SliverList.list(
                              children: children,
                            ),
                          if (builder != null)
                            SliverList.builder(
                              itemBuilder: builder,
                              itemCount: itemCount,
                            )
                        ],
                      ))),
            ),
          )));
}

// hardcoded as there is no simpler way
Widget wrapAppBarAction(Widget child) => SafeArea(
        child: Padding(
      padding: Platform.isAndroid
          ? const EdgeInsets.only(top: 4, bottom: 4, right: 4, left: 4)
          : const EdgeInsets.only(top: 8, bottom: 8, right: 8, left: 8),
      child: child,
    ));
