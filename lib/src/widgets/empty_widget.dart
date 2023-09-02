// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EmptyWidget extends StatelessWidget {
  final Object? error;
  const EmptyWidget({super.key, this.error});

  String _unwrapError() {
    if (error == null) {
      return "";
    }

    if (error is DioException) {
      final response = (error as DioException).response;
      if (response == null) {
        return (error as DioException).message ?? error.toString();
      }

      return "${response.statusCode}${response.statusMessage != null ? ' ${response.statusMessage}' : ''}";
    }

    return error.toString();
  }

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
              text: error == null
                  ? "${AppLocalizations.of(context)!.emptyValue}..."
                  : "${AppLocalizations.of(context)!.errorHalf} ${_unwrapError()}",
              style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: error != null ? 14 * 2 : null)),
        ]),
        maxLines: 2,
        textAlign: TextAlign.center,
        style: TextStyle(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
      ),
    );
  }
}

String chooseKaomoji() => emojis[Random().nextInt(emojis.length)];

const List<String> emojis = [
  r"щ(゜ロ゜щ)",
  r"(´⊙o⊙`；)",
  r"(´⊙ω⊙`)！",
  r"(´･艸･｀)",
  r"Σ(・Д・)!?",
  r"(ﾟヘﾟ)？",
  r"ʅฺ(・ω・。)ʃฺ？？",
  r"｢(ﾟﾍﾟ)",
  r"┻━┻ ︵ ¯\ (ツ)/¯ ︵ ┻━┻",
  r"┐(‘～`；)┌",
  r"╰(　´◔　ω　◔ `)╯",
  r"ㄟ( θ﹏θ)厂"
];
