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
import 'package:gallery/src/net/downloader.dart';
import 'package:gallery/src/pages/image_view.dart';
import 'package:gallery/src/db/schemas/favorite_booru.dart';
import 'package:gallery/src/widgets/notifiers/booru_api.dart';
import 'package:gallery/src/widgets/notifiers/tag_manager.dart';
import 'package:logging/logging.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../db/schemas/post.dart';
import 'grid/actions/booru_grid.dart';
import '../interfaces/booru.dart';
import '../db/initalize_db.dart';
import '../db/state_restoration.dart';
import '../db/schemas/download_file.dart';
import '../db/schemas/settings.dart';

class SinglePost extends StatefulWidget {
  final FocusNode focus;
  final TagManager tagManager;

  const SinglePost({super.key, required this.focus, required this.tagManager});

  @override
  State<SinglePost> createState() => _SinglePostState();
}

class _SinglePostState extends State<SinglePost> {
  final defaultBooru = BooruAPI.fromSettings();
  final controller = TextEditingController();
  final menuController = MenuController();

  List<Widget> menuItems = [];
  bool inProcessLoading = false;

  AnimationController? arrowSpinningController;

  @override
  void dispose() {
    arrowSpinningController = null;
    controller.dispose();
    defaultBooru.close();

    super.dispose();
  }

  void _launch([Booru? replaceBooru, int? replaceId]) async {
    if (inProcessLoading) {
      return;
    }

    inProcessLoading = true;

    BooruAPI booru;
    if (replaceBooru != null) {
      booru = BooruAPI.fromEnum(replaceBooru, page: null);
    } else {
      booru = defaultBooru;
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

      Color overlayColor =
          Theme.of(context).colorScheme.background.withOpacity(0.5);

      final key = GlobalKey<ImageViewState>();

      final favoritesWatcher = Dbs.g.main.favoriteBoorus
          .watchLazy(fireImmediately: false)
          .listen((event) {
        key.currentState?.setState(() {});
      });

      // ignore: use_build_context_synchronously
      Navigator.push(context, MaterialPageRoute(
        builder: (context) {
          return ImageView(
            key: key,
            registerNotifiers: [
              (child) => TagManagerNotifier(
                  tagManager: widget.tagManager, child: child),
              (child) => BooruAPINotifier(api: booru, child: child),
            ],
            updateTagScrollPos: (_, __) {},
            download: (_) {
              Downloader.g.add(
                  DownloadFile.d(
                      url: value.fileDownloadUrl(),
                      site: booru.booru.url,
                      name: value.filename(),
                      thumbUrl: value.previewUrl),
                  Settings.fromDb());
            },
            cellCount: 1,
            addIcons: (p) => [
              BooruGridActions.favorites(context, p),
              BooruGridActions.download(context, booru)
            ],
            scrollUntill: (_) {},
            onExit: () {},
            focusMain: () {},
            startingCell: 0,
            getCell: (_) => value,
            onNearEnd: () {
              return Future.value(1);
            },
            systemOverlayRestoreColor: overlayColor,
          );
        },
      )).then((_) {
        favoritesWatcher.cancel();
      });
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

    if (replaceBooru != null) {
      booru.close();
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
              onPressed: () {
                Permission.camera.request().then((value) {
                  if (!value.isGranted) {
                    Navigator.push(
                        context,
                        DialogRoute(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text("Error"),
                              content: Text(
                                  "Camera permission should be granted for reading the QR codes."),
                            );
                          },
                        ));
                  } else {
                    Navigator.push(
                        context,
                        DialogRoute(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              content: SizedBox(
                                width: 320,
                                height: 320,
                                child: MobileScanner(onDetect: (capture) {
                                  if (capture.barcodes.isNotEmpty) {
                                    final value =
                                        capture.barcodes.first.rawValue;
                                    if (value != null) {
                                      if (RegExp(r"^[0-9]").hasMatch(value)) {
                                        controller.text = value;
                                      } else {
                                        try {
                                          final f = value.split("_");
                                          _launch(Booru.fromPrefix(f[0])!,
                                              int.parse(f[1]));
                                        } catch (_) {}
                                      }
                                    }
                                  }
                                  Navigator.pop(context);
                                }),
                              ),
                            );
                          },
                        ));
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
            onPressed: () => _launch(),
          )
        ],
      ),
    );
  }
}
