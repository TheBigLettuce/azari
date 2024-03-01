// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/widgets/notifiers/current_cell.dart';
import 'package:gallery/src/widgets/notifiers/loading_progress.dart';

import '../../../interfaces/cell/cell.dart';
import '../../notifiers/app_bar_visibility.dart';

class ImageViewAppBar<T extends Cell> extends StatelessWidget {
  final List<Widget> stickers;
  final List<Widget> actions;

  const ImageViewAppBar(
      {super.key, required this.stickers, required this.actions});

  @override
  Widget build(BuildContext context) {
    final currentCell = CurrentCellNotifier.of<T>(context);

    return Animate(
        effects: const [
          FadeEffect(begin: 1, end: 0, duration: Duration(milliseconds: 500))
        ],
        autoPlay: false,
        target: AppBarVisibilityNotifier.of(context) ? 0 : 1,
        child: IgnorePointer(
          ignoring: !AppBarVisibilityNotifier.of(context),
          child: Column(
            children: [
              Expanded(
                  child: AppBar(
                bottom: const _BottomLoadIndicator(
                    preferredSize: Size.fromHeight(4),
                    child: SizedBox.shrink()),
                scrolledUnderElevation: 0,
                automaticallyImplyLeading: false,
                leading: const BackButton(),
                title: GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(
                        ClipboardData(text: currentCell.alias(false)));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            AppLocalizations.of(context)!.copiedClipboard)));
                  },
                  child: Text(currentCell.alias(false)),
                ),
                actions: Scaffold.of(context).hasEndDrawer
                    ? [
                        ...actions,
                        IconButton(
                            onPressed: () {
                              Scaffold.of(context).openEndDrawer();
                            },
                            icon: const Icon(Icons.info_outline)),
                      ]
                    : actions,
              )),
              if (stickers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 4,
                    children: stickers,
                  ),
                ),
            ],
          ),
        ));
  }
}

class _BottomLoadIndicator extends PreferredSize {
  const _BottomLoadIndicator({
    required super.preferredSize,
    required super.child,
  });

  @override
  Widget build(BuildContext context) {
    final status = LoadingProgressNotifier.of(context);

    return status == 1
        ? child
        : LinearProgressIndicator(
            minHeight: 4,
            value: status,
          );
  }
}
