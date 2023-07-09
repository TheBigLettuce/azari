// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'callback_grid.dart';

mixin _Selection<T extends Cell<B>, B> on State<CallbackGrid<T, B>> {
  int? lastSelected;
  PersistentBottomSheetController? currentBottomSheet;
  Map<int, B> selected = {};

  void _addSelection(int id, T selection) {
    if (selected.isEmpty || currentBottomSheet == null) {
      currentBottomSheet = showBottomSheet(
          context: context,
          enableDrag: false,
          builder: (context) {
            return Padding(
              padding:
                  EdgeInsets.only(bottom: widget.systemNavigationInsets.bottom),
              child: BottomSheet(
                  enableDrag: false,
                  onClosing: () {},
                  builder: (context) {
                    return Wrap(
                      spacing: 4,
                      children: [
                        _wrapSheetButton(context, Icons.close_rounded, () {
                          setState(() {
                            selected.clear();
                            currentBottomSheet?.close();
                          });
                        }, true),
                        ...widget.description.actions
                            .map((e) => _wrapSheetButton(
                                context,
                                e.icon,
                                e.showOnlyWhenSingle && selected.length != 1
                                    ? null
                                    : () {
                                        e.onPress(selected.values.toList());

                                        if (e.closeOnPress) {
                                          setState(() {
                                            selected.clear();
                                            currentBottomSheet?.close();
                                          });
                                        }
                                      },
                                false))
                            .toList()
                      ],
                    );
                  }),
            );
          })
        ..closed.then((value) => currentBottomSheet = null);
    } else {
      if (currentBottomSheet != null && currentBottomSheet!.setState != null) {
        currentBottomSheet!.setState!(() {});
      }
    }

    setState(() {
      selected[id] = selection.shrinkedData();
      lastSelected = id;
    });
  }

  void _removeSelection(int id) {
    setState(() {
      selected.remove(id);
      if (selected.isEmpty) {
        currentBottomSheet?.close();
        currentBottomSheet = null;
        lastSelected = null;
      } else {
        if (currentBottomSheet != null &&
            currentBottomSheet!.setState != null) {
          currentBottomSheet!.setState!(() {});
        }
      }
    });
  }

  void _selectUnselectUntil(int indx) {
    if (lastSelected != null) {
      if (lastSelected == indx) {
        return;
      }

      final selection = !_isSelected(indx);

      if (indx < lastSelected!) {
        for (var i = lastSelected!; i >= indx; i--) {
          if (selection) {
            selected[i] = widget.getCell(i).shrinkedData();
          } else {
            selected.remove(i);
          }
          lastSelected = i;
        }
        setState(() {});
      } else if (indx > lastSelected!) {
        for (var i = lastSelected!; i <= indx; i++) {
          if (selection) {
            selected[i] = widget.getCell(i).shrinkedData();
          } else {
            selected.remove(i);
          }
          lastSelected = i;
        }
        setState(() {});
      }

      if (currentBottomSheet != null && currentBottomSheet!.setState != null) {
        currentBottomSheet!.setState!(() {});
      }
    }
  }

  bool _isSelected(int indx) {
    return selected.containsKey(indx);
  }

  void _selectOrUnselect(int index, T selection) {
    if (!_isSelected(index)) {
      _addSelection(index, selection);
    } else {
      _removeSelection(index);
    }
  }

  Widget _wrapSheetButton(BuildContext context, IconData icon,
      void Function()? onPressed, bool addBadge) {
    var iconBtn = Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: IconButton(
          style: ButtonStyle(
              shape: const MaterialStatePropertyAll(RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.elliptical(10, 10)))),
              backgroundColor: MaterialStatePropertyAll(onPressed == null
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                  : Theme.of(context).colorScheme.primary)),
          onPressed: onPressed,
          icon:
              Icon(icon, color: Theme.of(context).colorScheme.inversePrimary)),
    );

    return addBadge
        ? Badge(
            label: Text(selected.length.toString()),
            child: iconBtn,
          )
        : iconBtn;
  }
}
