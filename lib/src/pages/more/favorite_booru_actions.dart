// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";

abstract class FavoritesActions {
  const FavoritesActions();

  static GridAction<T> addToGroup<T extends CellBase>(
    BuildContext context,
    String? Function(List<T>) initalValue,
    Future<void Function(BuildContext)?> Function(List<T>, String, bool)
        onSubmitted,
    bool showPinButton,
  ) {
    return GridAction(
      Icons.group_work_outlined,
      (selected) {
        if (selected.isEmpty) {
          return;
        }

        Navigator.of(context, rootNavigator: true).push(
          DialogRoute<void>(
            context: context,
            builder: (context) {
              return _GroupDialogWidget<T>(
                initalValue: initalValue,
                onSubmitted: onSubmitted,
                selected: selected,
                showPinButton: showPinButton,
              );
            },
          ),
        );
      },
      false,
    );
  }
}

class _GroupDialogWidget<T> extends StatefulWidget {
  const _GroupDialogWidget({
    super.key,
    required this.initalValue,
    required this.onSubmitted,
    required this.selected,
    required this.showPinButton,
  });

  final List<T> selected;
  final String? Function(List<T>) initalValue;
  final Future<void Function(BuildContext)?> Function(List<T>, String, bool)
      onSubmitted;
  final bool showPinButton;

  @override
  State<_GroupDialogWidget<T>> createState() => __GroupDialogWidgetState();
}

class __GroupDialogWidgetState<T> extends State<_GroupDialogWidget<T>> {
  bool toPin = false;

  @override
  Widget build(BuildContext context) {
    final l8n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l8n.group),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            autofocus: true,
            initialValue: widget.initalValue(widget.selected),
            onFieldSubmitted: (value) {
              widget.onSubmitted(widget.selected, value, toPin).then((e) {
                if (mounted) {
                  e?.call(context);
                }

                Navigator.pop(context);
              });
            },
          ),
          if (widget.showPinButton)
            SwitchListTile(
              title: Text(l8n.pinGroupLabel),
              value: toPin,
              onChanged: (b) {
                toPin = b;

                setState(() {});
              },
            ),
        ],
      ),
    );
  }
}
