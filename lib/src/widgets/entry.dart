// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../db/schemas/settings.dart';

class Entry extends StatefulWidget {
  const Entry({super.key});

  @override
  State<Entry> createState() => _EntryState();
}

class _EntryState extends State<Entry> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      Navigator.push(
          context,
          DialogRoute(
            context: context,
            builder: (context) {
              return AlertDialog(
                title:
                    Text(AppLocalizations.of(context)!.beforeYouContinueTitle),
                content:
                    Text(AppLocalizations.of(context)!.needChooseDirectory),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(context, "/booru");
                      },
                      child: Text(AppLocalizations.of(context)!.later)),
                  TextButton(
                      onPressed: () {
                        Settings.chooseDirectory((e) {}).then((success) {
                          if (success) {
                            Navigator.pop(context);
                            Navigator.pushReplacementNamed(context, "/booru");
                          }
                        });
                      },
                      child: Text(AppLocalizations.of(context)!.choose))
                ],
              );
            },
          ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
