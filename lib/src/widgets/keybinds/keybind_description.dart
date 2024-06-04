// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/widgets/keybinds/describe_keys.dart";

import "package:gallery/src/widgets/keybinds/single_activator_description.dart";

Map<SingleActivator, Null Function()> keybindDescription(
  BuildContext context,
  List<String> desc,
  String pageName,
  void Function() focusMain,
) {
  final theme = Theme.of(context);
  final l10n = AppLocalizations.of(context)!;

  return {
    const SingleActivator(LogicalKeyboardKey.keyK, shift: true, control: true):
        () {
      focusMain();
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: theme.dialogBackgroundColor.withOpacity(0.5),
          title: Text(l10n.keybindsFor(pageName)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              children: [
                ...ListTile.divideTiles(
                  context: context,
                  tiles: desc.map(
                    (e) => ListTile(
                      title: Text(e),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: ListTile(
                    title: Text(
                      describeKey(
                        SingleActivatorDescription(
                          l10n.keybindsDialog,
                          const SingleActivator(
                            LogicalKeyboardKey.keyK,
                            shift: true,
                            control: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  };
}
