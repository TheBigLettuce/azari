// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../home.dart";

mixin _BeforeYouContinueDialogMixin {
  void maybeBeforeYouContinueDialog(
    BuildContext context,
    SettingsData settings,
  ) {
    if (settings.path.isEmpty) {
      WidgetsBinding.instance.scheduleFrameCallback(
        (timeStamp) {
          Navigator.push(
            context,
            DialogRoute<void>(
              context: context,
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;

                return AlertDialog(
                  title: Text(l10n.beforeYouContinueTitle),
                  content: Text(l10n.needChooseDirectory),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(l10n.later),
                    ),
                    TextButton(
                      onPressed: () {
                        SettingsService.db().chooseDirectory(
                          (e) {},
                          emptyResult: l10n.emptyResult,
                          pickDirectory: l10n.pickDirectory,
                          validDirectory: l10n.chooseValidDirectory,
                        );
                        Navigator.pop(context);
                      },
                      child: Text(l10n.choose),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
    }
  }
}
