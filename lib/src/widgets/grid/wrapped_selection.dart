// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'callback_grid.dart';

class _WrappedSelection extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final bool selectionEnabled;
  final int thisIndx;
  final void Function() selectUnselect;
  final void Function(int indx) selectUntil;
  const _WrappedSelection(
      {required this.child,
      required this.isSelected,
      required this.selectUnselect,
      required this.thisIndx,
      required this.selectionEnabled,
      required this.selectUntil});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: selectUnselect,
          onLongPress: () {
            selectUntil(thisIndx);
            HapticFeedback.vibrate();
          },
          child: AbsorbPointer(
            absorbing: selectionEnabled,
            child: child,
          ),
        ),
        if (isSelected)
          GestureDetector(
            onTap: selectUnselect,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topRight,
                child: SizedBox(
                  width: Theme.of(context).iconTheme.size,
                  height: Theme.of(context).iconTheme.size,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle),
                    child: Icon(
                      Icons.check_outlined,
                      color: Theme.of(context).brightness != Brightness.light
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primaryContainer,
                      shadows: const [
                        Shadow(blurRadius: 0, color: Colors.black)
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
      ],
    );
  }
}
