// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../grid_frame.dart";

class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.actions,
    required this.bottomWidget,
    required this.leading,
    required this.title,
    required this.snap,
    required this.searchWidget,
    required this.pageName,
  });
  final Widget? title;
  final Widget? leading;
  final List<Widget> actions;
  final PreferredSizeWidget? bottomWidget;
  final bool snap;
  final GridSearchWidget searchWidget;
  final String pageName;

  @override
  Widget build(BuildContext context) {
    return searchWidget is PageNameSearchWidget
        ? SliverAppBar.large(
            title: Text(pageName),
          )
        : SliverAppBar(
            backgroundColor:
                Theme.of(context).colorScheme.surface.withOpacity(0.95),
            actions: actions,
            centerTitle: true,
            title: title,
            leading: leading,
            pinned: true,
            stretch: true,
            snap: snap,
            floating: snap,
            bottom: bottomWidget,
          );
  }
}
