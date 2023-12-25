// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'callback_grid.dart';

class SelectionInterface<T extends Cell> {
  final selected = <int, T>{};
  final List<GridAction<T>> addActions;
  int? lastSelected;

  final void Function(Function()) _setState;
  final SelectionGlue<T> glue;
  final ScrollController controller;

  void reset() {
    selected.clear();
    glue.close();
    lastSelected = null;

    _setState(() {});
    glue.updateCount(selected.length);
  }

  bool isSelected(int indx) =>
      indx.isNegative ? false : selected.containsKey(indx);

  void add(BuildContext context, int id, T selection,
      double systemNavigationInsets) {
    if (id.isNegative) {
      return;
    }

    if (selected.isEmpty) {
      glue.open(addActions, this);
    }

    _setState(() {
      selected[id] = selection;
      lastSelected = id;
    });

    glue.updateCount(selected.length);
  }

  void remove(int id) {
    _setState(() {
      selected.remove(id);
      if (selected.isEmpty) {
        glue.close();
        lastSelected = null;
      }
    });

    glue.updateCount(selected.length);
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

      glue.updateCount(selected.length);
    }
  }

  void selectOrUnselect(BuildContext context, int index, T selection,
      double systemNavigationInsets) {
    if (addActions.isEmpty) {
      return;
    }

    if (!isSelected(index)) {
      add(context, index, selection, systemNavigationInsets);
    } else {
      remove(index);
    }

    HapticFeedback.selectionClick();
  }

  SelectionInterface._(
      this._setState, this.addActions, this.glue, this.controller);
}

class WrapGridActionButton extends StatefulWidget {
  final IconData icon;
  final void Function()? onPressed;
  final void Function()? onLongPress;
  final bool addBadge;
  final String label;
  final bool? followColorTheme;
  final Color? backgroundColor;
  final Color? color;
  final bool animate;
  final bool play;
  final bool showOnlyWhenSingle;

  const WrapGridActionButton(
      this.icon, this.onPressed, this.addBadge, this.label,
      {super.key,
      this.followColorTheme,
      this.backgroundColor,
      this.color,
      required this.onLongPress,
      required this.showOnlyWhenSingle,
      required this.play,
      required this.animate});

  @override
  State<WrapGridActionButton> createState() => _WrapGridActionButtonState();
}

class _WrapGridActionButtonState extends State<WrapGridActionButton> {
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
          onLongPress: widget.onLongPress == null
              ? null
              : () {
                  widget.onLongPress!();
                  HapticFeedback.lightImpact();
                },
          child: IconButton(
            style: ButtonStyle(
                shape: const MaterialStatePropertyAll(RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.elliptical(10, 10)))),
                backgroundColor: widget.backgroundColor != null
                    ? MaterialStatePropertyAll(widget.backgroundColor)
                    : widget.followColorTheme == true
                        ? null
                        : MaterialStatePropertyAll(widget.showOnlyWhenSingle &&
                                SelectionCountNotifier.countOf(context) != 1
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.5)
                            : Theme.of(context).colorScheme.primary)),
            onPressed: widget.showOnlyWhenSingle &&
                    SelectionCountNotifier.countOf(context) != 1
                ? null
                : widget.onPressed == null
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
                          curve: Easing.emphasizedAccelerate),
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
