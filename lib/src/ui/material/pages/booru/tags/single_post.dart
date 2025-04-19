// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/impl/obj/post_impl.dart";
import "package:azari/src/services/services.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:logging/logging.dart";

class SinglePost extends StatefulWidget {
  const SinglePost({
    super.key,
    this.overrideLeading,
  });

  final Widget? overrideLeading;

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

    final booru = const SettingsService().current.selectedBooru;
    client = BooruAPI.defaultClientForBooru(booru);
    booruApi = BooruAPI.fromEnum(booru, client);
  }

  @override
  void dispose() {
    arrowSpinningController = null;
    controller.dispose();
    client.close(force: true);

    super.dispose();
  }

  Future<void> _launch(BuildContext context) {
    final l10n = context.l10n();

    final n = int.tryParse(controller.text);
    if (n == null) {
      throw l10n.notANumber(controller.text);
    }

    return openPostAsync(context, booru: booruApi.booru, postId: n);
  }

  Future<void> _tryClipboard() async {
    try {
      final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboard == null ||
          clipboard.text == null ||
          clipboard.text!.isEmpty) {
        return;
      }

      final numbers = RegExp(r"\d+")
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
            .map(
              (e) => ListTile(
                title: Text(e),
                onTap: () {
                  controller.text = e;
                  menuController.close();
                },
              ),
            )
            .toList();
      });

      menuController.open();
    } catch (e, trace) {
      Logger.root.warning("SinglePost _tryClipboard", e, trace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return MenuAnchor(
      menuChildren: menuItems,
      controller: menuController,
      child: SearchBar(
        elevation: const WidgetStatePropertyAll(0),
        hintText: l10n.goPostHint,
        controller: controller,
        trailing: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: controller.clear,
          ),
          IconButton(
            icon: const Icon(Icons.content_paste),
            onPressed: _tryClipboard,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward).animate(
              onInit: (controller) => arrowSpinningController = controller,
              effects: const [RotateEffect()],
              autoPlay: false,
            ),
            onPressed: DownloadManager.available && LocalTagsService.available
                ? () => _launch(context)
                : null,
          ),
        ],
      ),
    );
  }
}
