// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/booru/downloader/downloader.dart';
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/pages/image_view.dart';
import 'package:logging/logging.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../schemas/download_file.dart';

class SinglePost extends StatefulWidget {
  final FocusNode focus;
  const SinglePost(this.focus, {super.key});

  @override
  State<SinglePost> createState() => _SinglePostState();
}

class _SinglePostState extends State<SinglePost> {
  BooruAPI booru = getBooru();
  TextEditingController controller = TextEditingController();
  List<Widget> menuItems = [];
  MenuController menuController = MenuController();

  bool inProcessLoading = false;

  AnimationController? arrowSpinningController;

  @override
  void dispose() {
    arrowSpinningController = null;
    controller.dispose();
    booru.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: menuItems,
      controller: menuController,
      child: SearchBar(
        hintText: AppLocalizations.of(context)!.goPostHint,
        focusNode: widget.focus,
        controller: controller,
        leading: const Icon(Icons.search),
        trailing: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              controller.text = "";
            },
          ),
          IconButton(
            icon: const Icon(Icons.content_paste),
            onPressed: () async {
              try {
                var clipboard = await Clipboard.getData(Clipboard.kTextPlain);
                if (clipboard == null ||
                    clipboard.text == null ||
                    clipboard.text!.isEmpty) {
                  return;
                }

                var numbers = RegExp(r'\d+')
                    .allMatches(clipboard.text!)
                    .map((e) => e.input.substring(e.start, e.end))
                    .toList();
                if (numbers.isEmpty) {
                  return;
                }

                if (numbers.length == 1) {
                  controller.text = numbers.first;
                  return;
                }

                setState(() {
                  menuItems = numbers
                      .map((e) => ListTile(
                            title: Text(e),
                            onTap: () {
                              controller.text = e;
                              menuController.close();
                            },
                          ))
                      .toList();
                });

                menuController.open();
              } catch (e, trace) {
                log("clipboard button in single post",
                    level: Level.WARNING.value, error: e, stackTrace: trace);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward).animate(
                onInit: (controller) => arrowSpinningController = controller,
                effects: const [RotateEffect()],
                autoPlay: false),
            onPressed: () async {
              if (inProcessLoading) {
                return;
              }

              inProcessLoading = true;

              try {
                if (arrowSpinningController != null) {
                  arrowSpinningController!.repeat();
                }

                var n = int.tryParse(controller.text);
                if (n == null) {
                  throw AppLocalizations.of(context)!
                      .notANumber(controller.text);
                }

                Color overlayColor =
                    Theme.of(context).colorScheme.background.withOpacity(0.5);

                var value = await booru.singlePost(n);

                // ignore: use_build_context_synchronously
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) {
                    return ImageView(
                      updateTagScrollPos: (_, __) {},
                      download: (_) {
                        Downloader().add(File.d(value.downloadUrl(),
                            booru.domain, value.filename()));
                      },
                      cellCount: 1,
                      scrollUntill: (_) {},
                      startingCell: 0,
                      getCell: (_) => value,
                      onNearEnd: () {
                        return Future.value(1);
                      },
                      systemOverlayRestoreColor: overlayColor,
                    );
                  },
                ));
              } catch (e, trace) {
                try {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.toString())));
                } catch (_) {}

                log("going to a post in single post",
                    level: Level.SEVERE.value, error: e, stackTrace: trace);
              }

              if (arrowSpinningController != null) {
                arrowSpinningController!.stop();
                arrowSpinningController!.reverse();
              }

              inProcessLoading = false;
            },
          )
        ],
      ),
    );
  }
}
