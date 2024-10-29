// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../grid_frame.dart";

class _WrapPadding extends StatelessWidget {
  const _WrapPadding({
    required this.footer,
    required this.selectionGlue,
    required this.child,
  });

  final PreferredSizeWidget? footer;
  final SelectionGlue selectionGlue;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    SelectionCountNotifier.maybeCountOf(context);

    final insets = EdgeInsets.only(
      bottom: (kFloatingActionButtonMargin * 2 + 24 + 8 + 8 + 4) +
          (selectionGlue.keyboardVisible()
              ? 0
              : MediaQuery.viewPaddingOf(context).bottom +
                  (selectionGlue.isOpen()
                      ? selectionGlue.barHeight()
                      : selectionGlue.persistentBarHeight
                          ? selectionGlue.barHeight()
                          : 0)) +
          (footer != null ? footer!.preferredSize.height : 0),
    );

    return SliverPadding(
      padding: insets,
      sliver: child,
    );
  }
}
