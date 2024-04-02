// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/tags/booru_tagging.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/net/downloader.dart';
import 'package:gallery/src/widgets/image_view/image_view.dart';
import 'package:gallery/src/db/schemas/booru/favorite_booru.dart';
import 'package:logging/logging.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qrscan/qrscan.dart';

import '../../../db/schemas/booru/post.dart';
import '../../booru/booru_grid_actions.dart';
import '../../../interfaces/booru/booru_api.dart';
import '../../../db/schemas/downloader/download_file.dart';
import '../../../db/schemas/settings/settings.dart';

class SinglePost extends StatefulWidget {
  final TagManager tagManager;
  final Widget? overrideLeading;

  const SinglePost({
    super.key,
    required this.tagManager,
    this.overrideLeading,
  });

  @override
  State<SinglePost> createState() => _SinglePostState();
}

class _SinglePostState extends State<SinglePost> {
  late final Dio client;
  late final BooruAPI booruApi;

  final controller = TextEditingController();
  final menuController = MenuController();

  List<Widget> menuItems = [];
  bool inProcessLoading = false;

  AnimationController? arrowSpinningController;

  @override
  void initState() {
    super.initState();

    final booru = Settings.fromDb().selectedBooru;
    client = BooruAPI.defaultClientForBooru(booru);
    booruApi = BooruAPI.fromEnum(booru, client, EmptyPageSaver());
  }

  @override
  void dispose() {
    arrowSpinningController = null;
    controller.dispose();
    client.close(force: true);

    super.dispose();
  }

  void _launch(Color overlayColor,
      [Booru? replaceBooru, int? replaceId]) async {
    if (inProcessLoading) {
      return;
    }

    inProcessLoading = true;

    BooruAPI booru;
    if (replaceBooru != null) {
      booru = BooruAPI.fromEnum(replaceBooru, client, EmptyPageSaver());
    } else {
      booru = booruApi;
    }

    try {
      arrowSpinningController?.repeat();

      final Post value;

      if (replaceId != null) {
        value = await booru.singlePost(replaceId);
      } else {
        final n = int.tryParse(controller.text);
        if (n == null) {
          throw AppLocalizations.of(context)!.notANumber(controller.text);
        }

        value = await booru.singlePost(n);
      }

      final key = GlobalKey<ImageViewState>();

      final favoritesWatcher = FavoriteBooru.watch((event) {
        key.currentState?.setState(() {});
      });

      // ignore: use_build_context_synchronously
      ImageView.launchWrapped(
        context,
        1,
        (_) => value,
        overlayColor,
        key: key,
        download: (_) {
          Downloader.g.add(
              DownloadFile.d(
                  url: value.fileDownloadUrl(),
                  site: booru.booru.url,
                  name: value.filename(),
                  thumbUrl: value.previewUrl),
              Settings.fromDb());
        },
        actions: (p) => [
          BooruGridActions.favorites(context, p),
          BooruGridActions.download(context, booru.booru)
        ],
      ).then((value) => favoritesWatcher.cancel());
    } catch (e, trace) {
      try {
        // ignore: use_build_context_synchronously
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
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: menuItems,
      controller: menuController,
      child: SearchBar(
        hintText: AppLocalizations.of(context)!.goPostHint,
        controller: controller,
        // leading: widget.overrideLeading ?? const Icon(Icons.search),
        trailing: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              controller.text = "";
            },
          ),
          IconButton(
              onPressed: () {
                final color =
                    Theme.of(context).colorScheme.background.withOpacity(0.5);

                Permission.camera.request().then((value) {
                  if (!value.isGranted) {
                    Navigator.push(
                        context,
                        DialogRoute(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(AppLocalizations.of(context)!.error),
                              content: Text(AppLocalizations.of(context)!
                                  .cameraPermQrCodeErr),
                            );
                          },
                        ));
                  } else {
                    () async {
                      final value = await scan();
                      if (value == null) {
                        return;
                      }

                      if (RegExp(r"^[0-9]").hasMatch(value)) {
                        controller.text = value;
                      } else {
                        try {
                          final f = value.split("_");
                          _launch(
                              color, Booru.fromPrefix(f[0])!, int.parse(f[1]));
                        } catch (_) {}
                      }
                    }();
                  }
                });
              },
              icon: const Icon(Icons.qr_code_scanner_rounded)),
          IconButton(
            icon: const Icon(Icons.content_paste),
            onPressed: () async {
              try {
                final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
                if (clipboard == null ||
                    clipboard.text == null ||
                    clipboard.text!.isEmpty) {
                  return;
                }

                final numbers = RegExp(r'\d+')
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
            onPressed: () => _launch(
                Theme.of(context).colorScheme.background.withOpacity(0.5)),
          )
        ],
      ),
    );
  }
}
