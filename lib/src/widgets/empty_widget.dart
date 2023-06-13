// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EmptyWidget extends StatelessWidget {
  const EmptyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text.rich(
        TextSpan(children: [
          TextSpan(
            text: "${chooseKaomoji()}\n",
            style: const TextStyle(
              fontSize: 14 * 2,
            ),
          ),
          TextSpan(
              text: "${AppLocalizations.of(context)!.emptyValue}...",
              style: const TextStyle(fontStyle: FontStyle.italic)),
        ]),
        maxLines: 2,
        textAlign: TextAlign.center,
        style: TextStyle(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
      ),
    );
  }
}

String chooseKaomoji() {
  List<String> emojis = [
    "щ(゜ロ゜щ)",
    "(´⊙o⊙`；)",
    "(´⊙ω⊙`)！",
    "(´･艸･｀)",
    "Σ(・Д・)!?",
    "(ﾟヘﾟ)？",
    "ʅฺ(・ω・。)ʃฺ？？",
    "｢(ﾟﾍﾟ)",
    "┻━┻ ︵ ¯\ (ツ)/¯ ︵ ┻━┻",
    "┐(‘～`；)┌",
    "╰(　´◔　ω　◔ `)╯",
    "ㄟ( θ﹏θ)厂"
  ];

  var indx = Random().nextInt(emojis.length);

  return emojis[indx];
}
