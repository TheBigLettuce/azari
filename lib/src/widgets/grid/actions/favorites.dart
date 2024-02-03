// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

import '../callback_grid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

abstract class FavoritesActions {
  static GridAction<T> addToGroup<T>(
      BuildContext context,
      String? Function(List<T>) initalValue,
      void Function(List<T>, String, bool) onSubmitted) {
    return GridAction(
      Icons.group_work_outlined,
      (selected) {
        if (selected.isEmpty) {
          return;
        }

        Navigator.of(context, rootNavigator: true).push(DialogRoute(
          context: context,
          builder: (context) {
            return _GroupDialogWidget<T>(
              initalValue: initalValue,
              onSubmitted: onSubmitted,
              selected: selected,
            );
          },
        ));
      },
      false,
    );
  }
}

class _GroupDialogWidget<T> extends StatefulWidget {
  final List<T> selected;
  final String? Function(List<T>) initalValue;
  final void Function(List<T>, String, bool) onSubmitted;

  const _GroupDialogWidget({
    super.key,
    required this.initalValue,
    required this.onSubmitted,
    required this.selected,
  });

  @override
  State<_GroupDialogWidget<T>> createState() => __GroupDialogWidgetState();
}

class __GroupDialogWidgetState<T> extends State<_GroupDialogWidget<T>> {
  bool toPin = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppLocalizations.of(context)!.group,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            autofocus: true,
            initialValue: widget.initalValue(widget.selected),
            onFieldSubmitted: (value) {
              widget.onSubmitted(widget.selected, value, toPin);
            },
          ),
          SwitchListTile(
              // controlAffinity: ListTileControlAffinity.leading,
              title: const Text("Pin"), // TODO: change
              value: toPin,
              onChanged: (b) {
                toPin = b;

                setState(() {});
              })
        ],
      ),
      // actions: [

      // ],
    );
  }
}
