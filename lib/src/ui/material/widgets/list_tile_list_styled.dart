// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";

class ListTileListStyled extends StatelessWidget {
  const ListTileListStyled({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
    this.sliver = false,
    this.tight = false,
  });

  final int itemCount;
  final Widget? Function(BuildContext, int) itemBuilder;

  final EdgeInsets padding;

  final bool tight;
  final bool sliver;

  Widget? _itemBuilder(BuildContext context, int index) {
    final child = itemBuilder(context, index);
    if (child == null) {
      return null;
    }

    final theme = Theme.of(context);

    final isFirst = index == 0;
    final isLast = index == itemCount - 1;
    final isSingle = itemCount == 1;

    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: tight
            ? EdgeInsets.zero
            : !isSingle && !isLast
            ? const EdgeInsets.only(bottom: 6)
            : EdgeInsets.zero,
        child: ListTileTheme(
          shape: isSingle
              ? const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                )
              : isFirst
              ? tight
                    ? const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(25),
                          topRight: Radius.circular(25),
                        ),
                      )
                    : const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(25),
                          topRight: Radius.circular(25),
                          bottomLeft: Radius.circular(6),
                          bottomRight: Radius.circular(6),
                        ),
                      )
              : isLast
              ? tight
                    ? const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                        ),
                      )
                    : const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      )
              : tight
              ? const RoundedRectangleBorder()
              : const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
          tileColor: theme.colorScheme.surfaceContainerHigh,
          child: tight && !isLast
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [child, const Divider(height: 0)],
                )
              : child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return sliver
        ? SliverList.builder(itemCount: itemCount, itemBuilder: _itemBuilder)
        : ListView.builder(
            itemCount: itemCount,
            padding: padding,
            itemBuilder: _itemBuilder,
          );
  }
}

class ListTileListBodyStyled extends StatelessWidget {
  const ListTileListBodyStyled({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListBody(
      children: children.indexed.map((e) {
        final (index, child) = e;

        final isFirst = index == 0;
        final isLast = index == children.length - 1;
        final isSingle = children.length == 1;

        return Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: !isSingle && !isLast
                ? const EdgeInsets.only(bottom: 6)
                : EdgeInsets.zero,
            child: ListTileTheme(
              shape: isSingle
                  ? const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                    )
                  : isFirst
                  ? const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                        bottomLeft: Radius.circular(6),
                        bottomRight: Radius.circular(6),
                      ),
                    )
                  : isLast
                  ? const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    )
                  : const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(6),
                        bottomRight: Radius.circular(6),
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
              tileColor: theme.colorScheme.surfaceContainerHigh,
              child: child,
            ),
          ),
        );
      }).toList(),
    );
  }
}
