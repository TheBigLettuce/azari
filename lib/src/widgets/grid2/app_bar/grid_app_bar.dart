// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/widgets/notifiers/is_refreshing.dart';
import 'package:gallery/src/widgets/notifiers/is_search_showing.dart';
import 'package:gallery/src/widgets/notifiers/is_selecting.dart';

import 'grid_app_bar_title.dart';

// void _onTitlePressed() {
//   if (!_showSearchBar) {
//     widget.search?.focus.requestFocus();
//   }
//   setState(() {
//     _showSearchBar = !_showSearchBar;
//   });
// }

// Widget? _makeLeading(BuildContext context) {
//   if (selection.selected.isNotEmpty) {
//     return IconButton(
//         onPressed: () {
//           selection.selected.clear();
//           selection.glue.close();
//           setState(() {});
//         },
//         icon: Badge.count(
//             count: selection.selected.length,
//             child: const Icon(
//               Icons.close_rounded,
//             )));
// }

// List<Widget> _makeActions(BuildContext context) {
//   if (widget.menuButtonItems == null || showSearchBar) {
//     return const [SizedBox.shrink()];
//   }

//   return (!widget.inlineMenuButtonItems && widget.menuButtonItems!.length > 1)
//       ? [
//           PopupMenuButton(
//               position: PopupMenuPosition.under,
//               itemBuilder: (context) {
//                 return widget.menuButtonItems!
//                     .map(
//                       (e) => PopupMenuItem(
//                         enabled: false,
//                         child: e,
//                       ),
//                     )
//                     .toList();
//               })
//         ]
//       : [
//           ...widget.menuButtonItems!,
//         ];
// }

// widget.description.bottomWidget != null
//           ? widget.description.bottomWidget!
//           : PreferredSize(
//               preferredSize: const Size.fromHeight(4),
//               child: !_state.isRefreshing
//                   ? const Padding(
//                       padding: EdgeInsets.only(top: 4),
//                       child: SizedBox(),
//                     )
//                   : const LinearProgressIndicator(),
//             ),

// !_state.isRefreshing && _state.cellCount == 0
//                     ? SliverFillRemaining(
//                         child: Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               EmptyWidget(
//                                 error: _state.refreshingError == null
//                                     ? null
//                                     : EmptyWidget.unwrapDioError(
//                                         _state.refreshingError),
//                               ),
//                               if (widget.onError != null &&
//                                   _state.refreshingError != null)
//                                 widget.onError!(_state.refreshingError!),
//                             ],
//                           ),
//                         ),
//                       )
//                     :

class GridAppBar extends StatelessWidget {
  final List<Widget> actions;
  final PreferredSizeWidget? bottomWidget;
  // final SearchAndFocus? search;
  final Widget leading;
  final Widget title;
  final bool centerTitle;

  const GridAppBar(
      {super.key,
      required this.actions,
      required this.bottomWidget,
      required this.centerTitle,
      required this.leading,
      // required this.search,
      required this.title});

  const GridAppBar.basic(
      {super.key,
      this.actions = const [],
      this.bottomWidget,
      this.leading = const SizedBox.shrink(),
      this.title = const GridAppBarTitle.withCount()})
      : centerTitle = true;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor:
          Theme.of(context).colorScheme.background.withOpacity(0.95),
      automaticallyImplyLeading: false,
      actions: actions,
      centerTitle: centerTitle,
      title: title,
      leading: IsSearchShowingNotifier.maybeOf(context) ?? false
          ? BackButton(
              onPressed: () => IsSearchShowingNotifier.flipOf(context),
            )
          : leading,
      pinned: true,
      stretch: true,
      snap: !IsSelectingNotifier.of(context),
      floating: !IsSelectingNotifier.of(context),
      bottom: bottomWidget ??
          const _BottomWidget(
              preferredSize: Size.fromHeight(4),
              child: LinearProgressIndicator()),
    );
  }
}

class _BottomWidget extends PreferredSize {
  const _BottomWidget(
      {super.key, required super.preferredSize, required super.child});

  @override
  Widget build(BuildContext context) {
    return IsRefreshingNotifier.of(context)
        ? child
        : const Padding(
            padding: EdgeInsets.only(top: 4),
            child: SizedBox(),
          );
  }
}
