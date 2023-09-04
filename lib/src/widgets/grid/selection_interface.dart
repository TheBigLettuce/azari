// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'callback_grid.dart';

class SelectionInterface<T extends Cell> {
  final selected = <int, T>{};
  final List<GridBottomSheetAction<T>> addActions;
  int? lastSelected;

  final void Function(Function()) _setState;

  PersistentBottomSheetController? currentBottomSheet;

  bool isSelected(int indx) =>
      indx.isNegative ? false : selected.containsKey(indx);

  void add(BuildContext context, int id, T selection,
      double systemNavigationInsets) {
    if (id.isNegative) {
      return;
    }
    if (selected.isEmpty || currentBottomSheet == null) {
      currentBottomSheet = showBottomSheet(
          constraints:
              BoxConstraints(minWidth: MediaQuery.of(context).size.width),
          backgroundColor:
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
          context: context,
          enableDrag: false,
          builder: (context) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: systemNavigationInsets + 4, top: 48 / 2),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                children: [
                  wrapSheetButton(context, Icons.close_rounded, () {
                    _setState(() {
                      selected.clear();
                      currentBottomSheet?.close();
                    });
                  },
                      true,
                      selected.length.toString(),
                      const GridBottomSheetActionExplanation(
                        label: "Clear selection", // TODO: change
                        body: "Unselects every item.", // TODO: change
                      )),
                  ...addActions
                      .map((e) => wrapSheetButton(
                          context,
                          e.icon,
                          e.showOnlyWhenSingle && selected.length != 1
                              ? null
                              : () {
                                  e.onPress(selected.values.toList());

                                  if (e.closeOnPress) {
                                    _setState(() {
                                      selected.clear();
                                      currentBottomSheet?.close();
                                    });
                                  }
                                },
                          false,
                          selected.length.toString(),
                          e.explanation))
                      .toList()
                ],
              ),
            );
          })
        ..closed.then((value) => currentBottomSheet = null);
    } else {
      if (currentBottomSheet != null && currentBottomSheet!.setState != null) {
        currentBottomSheet!.setState!(() {});
      }
    }

    _setState(() {
      selected[id] = selection;
      lastSelected = id;
    });
  }

  void remove(int id) {
    _setState(() {
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

  void selectUnselectUntil(int indx, GridMutationInterface<T> state) {
    if (lastSelected != null) {
      if (lastSelected == indx) {
        return;
      }

      final selection = !isSelected(indx);

      if (indx < lastSelected!) {
        for (var i = lastSelected!; i >= indx; i--) {
          if (selection) {
            selected[i] = state.getCell(i);
          } else {
            remove(i);
          }
          lastSelected = i;
        }
        _setState(() {});
      } else if (indx > lastSelected!) {
        for (var i = lastSelected!; i <= indx; i++) {
          if (selection) {
            selected[i] = state.getCell(i);
          } else {
            remove(i);
          }
          lastSelected = i;
        }
        _setState(() {});
      }

      currentBottomSheet?.setState?.call(() {});
    }
  }

  void selectOrUnselect(BuildContext context, int index, T selection,
      double systemNavigationInsets) {
    if (!isSelected(index)) {
      add(context, index, selection, systemNavigationInsets);
    } else {
      remove(index);
    }
  }

  static Widget wrapSheetButton(
      BuildContext context,
      IconData icon,
      void Function()? onPressed,
      bool addBadge,
      String label,
      GridBottomSheetActionExplanation explanation,
      {bool? followColorTheme}) {
    final iconBtn = Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: GestureDetector(
        onLongPress: () {
          Navigator.push(
              context,
              DialogRoute(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(explanation.label),
                    content: Text(explanation.body),
                  );
                },
              ));
        },
        child: IconButton(
          style: ButtonStyle(
              shape: const MaterialStatePropertyAll(RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.elliptical(10, 10)))),
              backgroundColor: followColorTheme == true
                  ? null
                  : MaterialStatePropertyAll(onPressed == null
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                      : Theme.of(context).colorScheme.primary)),
          onPressed: onPressed == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onPressed();
                },
          icon: Icon(icon,
              color: followColorTheme == true
                  ? null
                  : Theme.of(context).colorScheme.inversePrimary),
        ),
      ),
    );

    return addBadge
        ? Badge(
            label: Text(label),
            child: iconBtn,
          )
        : iconBtn;
  }

  SelectionInterface._(this._setState, this.addActions);
}
