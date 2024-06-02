// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";

class SettingsLabel extends StatelessWidget {
  const SettingsLabel(
    this.string,
    this.style, {
    super.key,
    this.removePadding = false,
  });
  final String string;
  final TextStyle style;
  final bool removePadding;

  static TextStyle defaultStyle(BuildContext context, ThemeData theme) =>
      theme.textTheme.titleSmall!.copyWith(color: theme.colorScheme.secondary);

  @override
  Widget build(BuildContext context) {
    return removePadding
        ? Text(
            string,
            style: style,
          )
        : Padding(
            padding:
                const EdgeInsets.only(bottom: 12, top: 18, right: 12, left: 16),
            child: Text(
              string,
              style: style,
            ),
          );
  }
}

class MenuLabel extends StatefulWidget {
  const MenuLabel({
    super.key,
    required this.title,
  });
  final String title;

  @override
  State<MenuLabel> createState() => _MenuLabelState();
}

class _MenuLabelState extends State<MenuLabel> {
  bool expandTitle = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        expandTitle = !expandTitle;

        setState(() {});
      },
      child: Text(
        widget.title,
        style: theme.textTheme.titleSmall!.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 0.6,
        ),
        maxLines: expandTitle ? null : 1,
        overflow: expandTitle ? null : TextOverflow.ellipsis,
      ),
    );
  }
}
