// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/typedefs.dart";
import "package:flutter/material.dart";

extension SafeModeRadioDialogExt on BuildContext {
  void openSafeModeDialog(
    SettingsService settingsService,
    void Function(SafeMode?) onPressed, [
    SafeMode? defaultValue,
  ]) {
    final l10n = AppLocalizations.of(this)!;

    // void defaultOnPressed(SafeMode? value) {
    //   final db = DatabaseConnectionNotifier.of(this);

    //   Navigator.of(this, rootNavigator: true).push<void>(
    //     MaterialPageRoute(
    //       builder: (context) => BooruRestoredPage(
    //         db: db,
    //         booru: booru,
    //         tags: tags,
    //         saveSelectedPage: (_) {},
    //         wrapScaffold: true,
    //         overrideSafeMode: value,
    //       ),
    //     ),
    //   );
    // }

    radioDialog<SafeMode>(
      this,
      SafeMode.values.map((e) => (e, e.translatedString(l10n))),
      defaultValue ?? settingsService.current.safeMode,
      onPressed,
      title: l10n.chooseSafeMode,
      allowSingle: true,
    );
  }
}

void radioDialog<T>(
  BuildContext context,
  Iterable<(T, String)> values,
  T groupValue,
  void Function(T? value) onChanged, {
  required String title,
  bool allowSingle = false,
}) {
  Navigator.of(
    context,
    rootNavigator: true,
  ).push(
    DialogRoute<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(context.l10n().back),
            ),
          ],
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: values
                  .map(
                    (e) => RadioListTile(
                      shape: const BeveledRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                      ),
                      value: e.$1,
                      title: Text(e.$2),
                      groupValue: groupValue,
                      toggleable: allowSingle,
                      onChanged: (value) {
                        Navigator.pop(context);
                        onChanged(allowSingle ? value ?? groupValue : value);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    ),
  );
}
