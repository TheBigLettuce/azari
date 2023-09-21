// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void radioDialog<T>(BuildContext context, Iterable<(T, String)> values,
    T groupValue, void Function(T? value) onChanged,
    {required String title}) {
  Navigator.push(
      context,
      DialogRoute(
        context: context,
        builder: (context) {
          return AlertDialog(
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context)!.back))
            ],
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: values
                  .map((e) => RadioListTile(
                      shape: const BeveledRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(5))),
                      value: e.$1,
                      title: Text(e.$2),
                      groupValue: groupValue,
                      onChanged: (value) {
                        onChanged(value);
                        Navigator.pop(context);
                      }))
                  .toList(),
            ),
          );
        },
      ));
}
