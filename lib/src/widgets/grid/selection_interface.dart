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
                  WrapSheetButton(
                    Icons.close_rounded,
                    () {
                      _setState(() {
                        selected.clear();
                        currentBottomSheet?.close();
                      });
                    },
                    true,
                    selected.length.toString(),
                    GridBottomSheetActionExplanation(
                      label: AppLocalizations.of(context)!
                          .clearSelectionActionLabel,
                      body: AppLocalizations.of(context)!
                          .clearSelectionActionBody,
                    ),
                    animate: false,
                    play: false,
                  ),
                  ...addActions
                      .map((e) => WrapSheetButton(
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
                          e.explanation,
                          animate: e.animate,
                          color: e.color,
                          play: e.play,
                          backgroundColor: e.backgroundColor))
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

  void selectUnselectUntil(int indx, GridMutationInterface<T> state,
      {List<int>? selectFrom}) {
    if (lastSelected != null) {
      final last = selectFrom?.indexOf(lastSelected!) ?? lastSelected!;
      indx = selectFrom?.indexOf(indx) ?? indx;
      if (lastSelected == indx) {
        return;
      }

      final selection = !isSelected(indx);

      if (indx < last) {
        for (var i = last; i >= indx; i--) {
          if (selection) {
            selected[selectFrom?[i] ?? i] = state.getCell(selectFrom?[i] ?? i);
          } else {
            remove(selectFrom?[i] ?? i);
          }
          lastSelected = selectFrom?[i] ?? i;
        }
        _setState(() {});
      } else if (indx > last) {
        for (var i = last; i <= indx; i++) {
          if (selection) {
            selected[selectFrom?[i] ?? i] = state.getCell(selectFrom?[i] ?? i);
          } else {
            remove(selectFrom?[i] ?? i);
          }
          lastSelected = selectFrom?[i] ?? i;
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

  SelectionInterface._(this._setState, this.addActions);
}

class WrapSheetButton extends StatefulWidget {
  final IconData icon;
  final void Function()? onPressed;
  final bool addBadge;
  final String label;
  final GridBottomSheetActionExplanation explanation;
  final bool? followColorTheme;
  final Color? backgroundColor;
  final Color? color;
  final bool animate;
  final bool play;

  const WrapSheetButton(
      this.icon, this.onPressed, this.addBadge, this.label, this.explanation,
      {super.key,
      this.followColorTheme,
      this.backgroundColor,
      this.color,
      required this.play,
      required this.animate});

  @override
  State<WrapSheetButton> createState() => _WrapSheetButtonState();
}

class _WrapSheetButtonState extends State<WrapSheetButton> {
  AnimationController? _controller;

  @override
  Widget build(BuildContext context) {
    final icn = Icon(widget.icon,
        color: widget.color ??
            (widget.followColorTheme == true
                ? null
                : Theme.of(context).colorScheme.inversePrimary));

    Widget iconBtn(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: GestureDetector(
          onLongPress: () {
            Navigator.push(
                context,
                DialogRoute(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(widget.explanation.label),
                      content: Text(widget.explanation.body),
                    );
                  },
                ));
          },
          child: IconButton(
            style: ButtonStyle(
                shape: const MaterialStatePropertyAll(RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.elliptical(10, 10)))),
                backgroundColor: widget.backgroundColor != null
                    ? MaterialStatePropertyAll(widget.backgroundColor)
                    : widget.followColorTheme == true
                        ? null
                        : MaterialStatePropertyAll(widget.onPressed == null
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.5)
                            : Theme.of(context).colorScheme.primary)),
            onPressed: widget.onPressed == null
                ? null
                : () {
                    if (widget.animate && widget.play) {
                      _controller?.reset();
                      _controller
                          ?.animateTo(1)
                          .then((value) => _controller?.animateBack(0));
                    }
                    HapticFeedback.selectionClick();
                    widget.onPressed!();
                  },
            icon: widget.animate
                ? Animate(
                    effects: [
                      ScaleEffect(
                          duration: 150.ms,
                          begin: const Offset(1, 1),
                          end: const Offset(2, 2),
                          curve: Curves.easeInOutBack),
                    ],
                    onInit: (controller) {
                      _controller = controller;
                    },
                    autoPlay: false,
                    child: icn,
                  )
                : icn,
          ),
        ),
      );
    }

    return widget.addBadge
        ? Badge(
            label: Text(widget.label),
            child: iconBtn(context),
          )
        : iconBtn(context);
  }
}
