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
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/image/view.dart';
import 'package:logging/logging.dart';

class SinglePost extends StatefulWidget {
  const SinglePost({super.key});

  @override
  State<SinglePost> createState() => _SinglePostState();
}

class _SinglePostState extends State<SinglePost> {
  TextEditingController controller = TextEditingController();
  List<Widget> menuItems = [];
  MenuController menuController = MenuController();
  FocusNode searchFocus = FocusNode();

  AnimationController? arrowSpinningController;

  @override
  void dispose() {
    arrowSpinningController = null;
    searchFocus.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: menuItems,
      controller: menuController,
      child: SearchBar(
        hintText: "Go to a post",
        focusNode: searchFocus,
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
              try {
                if (arrowSpinningController != null) {
                  arrowSpinningController!.repeat();
                }

                var n = int.tryParse(controller.text);
                if (n == null) {
                  throw "'${controller.text}' is not a number.";
                }

                Color overlayColor =
                    Theme.of(context).colorScheme.background.withOpacity(0.5);

                var value = await getBooru().singlePost(n);

                // ignore: use_build_context_synchronously
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) {
                    return ImageView(
                      updateTagScrollPos: (_, __) {},
                      cellCount: 1,
                      scrollUntill: (_) {},
                      startingCell: 0,
                      getCell: (_) => value.booruCell((tag) {}),
                      onNearEnd: () {
                        return Future.value(1);
                      },
                      restoreSystemOverlay: () =>
                          SystemChrome.setSystemUIOverlayStyle(
                        SystemUiOverlayStyle(
                            systemNavigationBarColor: overlayColor),
                      ),
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
            },
          )
        ],
      ),
    );
  }
}
