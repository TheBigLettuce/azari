// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:math";

import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

class EmptyWidget extends StatelessWidget {
  const EmptyWidget({
    super.key,
    this.error,
    this.overrideEmpty,
    required this.gridSeed,
  });

  final String? error;
  final String? overrideEmpty;
  final int gridSeed;

  static String unwrapDioError(Object? error) {
    if (error == null) {
      return "";
    }

    if (error is DioException) {
      if (error.type == DioExceptionType.unknown) {
        return error.error.toString();
      }

      final response = error.response;
      if (response == null) {
        return error.message ?? error.toString();
      }

      return "${response.statusCode}${response.statusMessage != null ? ' ${response.statusMessage}' : ''}";
    }

    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: error != null
                    ? "(ﾟヘﾟ)？" "\n"
                    : "${chooseKaomoji(gridSeed)}\n",
                style: TextStyle(
                  fontSize: 14 * 2,
                  color: error == null ? null : colorScheme.error,
                ),
              ),
              TextSpan(
                text: overrideEmpty ??
                    (error == null
                        ? "${l10n.emptyValue}..."
                        : "${l10n.error} — $error"),
                style: TextStyle(
                  overflow: TextOverflow.ellipsis,
                  color:
                      error == null ? null : colorScheme.error.withOpacity(0.6),
                  fontStyle: error != null ? null : FontStyle.italic,
                  fontSize: error != null ? 14 * 2 : null,
                ),
              ),
            ],
          ),
          maxLines: error != null ? 4 : 2,
          textAlign: TextAlign.center,
          style: TextStyle(
            overflow: TextOverflow.ellipsis,
            color: colorScheme.secondary.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}

String chooseKaomoji(int seed) => emojis[Random(seed).nextInt(emojis.length)];

const List<String> emojis = [
  "щ(゜ロ゜щ)",
  "(´⊙o⊙`；)",
  "(´⊙ω⊙`)！",
  "(´･艸･｀)",
  "Σ(・Д・)!?",
  "(ﾟヘﾟ)？",
  "ʅฺ(・ω・。)ʃฺ？？",
  "｢(ﾟﾍﾟ)",
  r"┻━┻ ︵ ¯\ (ツ)/¯ ︵ ┻━┻",
  "┐(‘～`；)┌",
  "╰(　´◔　ω　◔ `)╯",
  "ㄟ( θ﹏θ)厂",
];
