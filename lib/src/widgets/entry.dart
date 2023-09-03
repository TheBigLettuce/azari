// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:introduction_screen/introduction_screen.dart';

import '../db/isar.dart';

/// Currently forces the user to choose a directory.
class Entry extends StatelessWidget {
  const Entry({super.key});

  @override
  Widget build(BuildContext context) {
    showDialog(String s) {
      Navigator.of(context).push(DialogRoute(
          context: context,
          builder: (context) => AlertDialog(
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(AppLocalizations.of(context)!.ok))
                ],
                content: Text(s),
              )));
    }

    restore() {
      Navigator.pushReplacementNamed(context, "/booru");
    }

    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: AppLocalizations.of(context)!.pickDirectory,
          bodyWidget: TextButton(
            onPressed: () async {
              for (true;;) {
                if (await chooseDirectory(showDialog)) {
                  break;
                }
              }

              restore();
            },
            child: Text(AppLocalizations.of(context)!.pick),
          ),
        )
      ],
      showDoneButton: false,
      next: Text(AppLocalizations.of(context)!.next),
    );
  }
}
