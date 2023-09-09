// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/search_filter_grid.dart';
import 'package:gallery/src/widgets/system_gestures.dart';

import '../booru/interface.dart';
import '../cell/cell.dart';
import '../keybinds/keybinds.dart';
import '../pages/senitel.dart';
import '../schemas/settings.dart';
import 'drawer/add_rail.dart';
import 'drawer/drawer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SkeletonState {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  final FocusNode mainFocus = FocusNode();
  final int index;

  void dispose() {
    mainFocus.dispose();
  }

  SkeletonState.settings() : index = kSettingsDrawerIndex;
  SkeletonState(this.index);
}

class GridSkeletonStateFilter<T extends Cell> extends GridSkeletonState<T> {
  final FilterInterface<T> filter;
  final Set<FilteringMode> filteringModes;

  static SortingMode _doNothing(FilteringMode m) => SortingMode.none;

  final SortingMode Function(FilteringMode selected) hook;

  final T Function(T cell, SortingMode sort) transform;

  GridSkeletonStateFilter(
      {required this.filter,
      required super.index,
      required this.transform,
      this.filteringModes = const {},
      this.hook = _doNothing});
}

class GridSkeletonState<T extends Cell> extends SkeletonState {
  bool showFab;
  final GlobalKey<CallbackGridState<T>> gridKey = GlobalKey();
  Settings settings = Settings.fromDb();
  // final Future<bool> Function() onWillPop;

  void updateFab(void Function(void Function()) setState,
      {required bool fab, required bool foreground}) {
    if (fab != showFab) {
      showFab = fab;
      if (!foreground) {
        try {
          setState(() {});
        } catch (_) {}
      }
    }
  }

  GridSkeletonState({required int index})
      : showFab = false,
        super(index);
}

Widget makeGridSkeleton<T extends Cell>(
    BuildContext context, GridSkeletonState<T> state, CallbackGrid<T> grid,
    {bool popSenitel = true,
    bool noDrawer = false,
    Booru? overrideBooru,
    Future<bool> Function()? overrideOnPop}) {
  return WillPopScope(
    onWillPop: overrideOnPop ??
        (popSenitel
            ? () => popUntilSenitel(context)
            : () => Future.value(true)),
    child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        drawerEnableOpenDragGesture:
            MediaQuery.systemGestureInsetsOf(context) == EdgeInsets.zero,
        floatingActionButton: state.showFab
            ? GestureDetector(
                onLongPress: () {
                  if (grid.key != null &&
                      grid.key is GlobalKey<CallbackGridState>) {
                    final maxOffset = state.gridKey.currentState?.controller
                        .position.maxScrollExtent;
                    if (maxOffset == null || maxOffset.isInfinite) {
                      return;
                    }

                    HapticFeedback.vibrate();
                    (grid.key as GlobalKey<CallbackGridState>)
                        .currentState
                        ?.controller
                        .animateTo(maxOffset,
                            duration: 500.ms, curve: Curves.easeInOutSine);
                  }
                },
                child: FloatingActionButton(
                  heroTag: null,
                  onPressed: () {
                    if (grid.key != null &&
                        grid.key is GlobalKey<CallbackGridState>) {
                      (grid.key as GlobalKey<CallbackGridState>)
                          .currentState
                          ?.controller
                          .animateTo(0,
                              duration: 500.ms, curve: Curves.easeInOutSine);
                    }
                  },
                  child: const Icon(Icons.arrow_upward),
                ),
              )
            : null,
        endDrawerEnableOpenDragGesture: false,
        key: state.scaffoldKey,
        drawer: noDrawer
            ? null
            : makeDrawer(context, state.index, overrideBooru: overrideBooru),
        endDrawer:
            noDrawer ? null : makeEndDrawerSettings(context, state.scaffoldKey),
        body: gestureDeadZones(
          context,
          child: addRail(context, state.index, state.scaffoldKey, grid),
        )),
  );
}

Widget makeSkeletonSettings(BuildContext context, String pageDescription,
    SkeletonState state, Widget child) {
  Map<SingleActivatorDescription, Null Function()> bindings = {
    SingleActivatorDescription(AppLocalizations.of(context)!.back,
        const SingleActivator(LogicalKeyboardKey.escape)): () {
      Navigator.pop(context);
    },
  };

  var insets = MediaQuery.viewPaddingOf(context);

  return CallbackShortcuts(
      bindings: {
        ...bindings,
        ...keybindDescription(context, describeKeys(bindings), pageDescription,
            () {
          state.mainFocus.requestFocus();
        })
      },
      child: Focus(
        autofocus: true,
        focusNode: state.mainFocus,
        child: Scaffold(
          drawerEnableOpenDragGesture:
              MediaQuery.systemGestureInsetsOf(context) == EdgeInsets.zero,
          key: state.scaffoldKey,
          body: gestureDeadZones(context,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar.large(
                    expandedHeight: 160,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(pageDescription),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.only(bottom: insets.bottom),
                    sliver: child,
                  )
                ],
              )),
        ),
      ));
}

Widget makeSkeletonInnerSettings(BuildContext context, String pageDescription,
    SkeletonState state, List<Widget> children,
    {List<Widget>? appBarActions}) {
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
        ...keybindDescription(context, describeKeys(bindings), pageDescription,
            () {
          state.mainFocus.requestFocus();
        })
      },
      child: Focus(
        autofocus: true,
        focusNode: state.mainFocus,
        child: Scaffold(
          drawerEnableOpenDragGesture:
              MediaQuery.systemGestureInsetsOf(context) == EdgeInsets.zero,
          body: gestureDeadZones(context,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar.large(
                    expandedHeight: 160,
                    flexibleSpace: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: FlexibleSpaceBar(
                          title: Text(
                            pageDescription,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        )),
                        if (appBarActions != null)
                          ...appBarActions
                              .map((e) => wrapAppBarAction(e))
                              .toList()
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.only(bottom: insets.bottom),
                    sliver:
                        SliverList(delegate: SliverChildListDelegate(children)),
                  )
                ],
              )),
        ),
      ));
}

Widget makeSkeleton(
    BuildContext context, String pageDescription, SkeletonState state,
    {List<Widget>? children,
    Widget Function(BuildContext context, int indx)? builder,
    Map<SingleActivatorDescription, Null Function()>? additionalBindings,
    bool popSenitel = true,
    int? itemCount,
    void Function(int route, void Function() original)? overrideChooseRoute,
    List<Widget>? appBarActions,
    Widget? customTitle}) {
  if (children == null && builder == null ||
      children != null && builder != null) {
    throw "only one should be specified";
  }

  if (builder != null && itemCount == null) {
    throw "itemCount should be supplied";
  }

  var insets = MediaQuery.viewPaddingOf(context);

  Map<SingleActivatorDescription, Null Function()> bindings = {
    SingleActivatorDescription(AppLocalizations.of(context)!.back,
        const SingleActivator(LogicalKeyboardKey.escape)): () {
      if (state.scaffoldKey.currentState != null) {
        if (state.scaffoldKey.currentState!.hasEndDrawer &&
            state.scaffoldKey.currentState!.isEndDrawerOpen) {
          state.scaffoldKey.currentState?.closeEndDrawer();
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
    ...digitAndSettings(context, state.index, state.scaffoldKey)
  };

  return CallbackShortcuts(
      bindings: {
        ...bindings,
        ...keybindDescription(context, describeKeys(bindings), pageDescription,
            () {
          state.mainFocus.requestFocus();
        })
      },
      child: Focus(
          autofocus: true,
          focusNode: state.mainFocus,
          child: WillPopScope(
            onWillPop: () =>
                !popSenitel ? Future.value(true) : popUntilSenitel(context),
            child: Scaffold(
              drawerEnableOpenDragGesture:
                  MediaQuery.systemGestureInsetsOf(context) == EdgeInsets.zero,
              key: state.scaffoldKey,
              drawer: makeDrawer(context, state.index,
                  overrideChooseRoute: overrideChooseRoute),
              endDrawer: makeEndDrawerSettings(context, state.scaffoldKey),
              body: gestureDeadZones(context,
                  child: addRail(
                      context,
                      state.index,
                      state.scaffoldKey,
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
                            SliverPadding(
                              padding: EdgeInsets.only(bottom: insets.bottom),
                              sliver: SliverList.list(
                                children: children,
                              ),
                            ),
                          if (builder != null)
                            SliverPadding(
                              padding: EdgeInsets.only(bottom: insets.bottom),
                              sliver: SliverList.builder(
                                itemBuilder: builder,
                                itemCount: itemCount,
                              ),
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
          ? const EdgeInsets.only(top: 4, bottom: 4)
          : const EdgeInsets.only(top: 8, bottom: 8),
      child: child,
    ));
