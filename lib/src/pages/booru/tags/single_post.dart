// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/post_tags.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/booru/post.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/widgets/image_view/image_view.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:logging/logging.dart";

class SinglePost extends StatefulWidget {
  const SinglePost({
    super.key,
    required this.tagManager,
    this.overrideLeading,
    required this.db,
  });

  final TagManager tagManager;
  final Widget? overrideLeading;

  final FavoritePostSourceService db;

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

    final booru = SettingsService.db().current.selectedBooru;
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

  Future<void> _launch(
    DownloadManager downloadManager,
    AppLocalizations l10n,
    PostTags postTags, [
    Booru? replaceBooru,
    int? replaceId,
  ]) {
    if (inProcessLoading) {
      return Future.value();
    }

    inProcessLoading = true;

    BooruAPI booru;
    if (replaceBooru != null) {
      booru = BooruAPI.fromEnum(replaceBooru, client);
    } else {
      booru = booruApi;
    }

    unawaited(arrowSpinningController?.repeat());

    void onThen(Post p) {
      ImageView.launchWrapped(
        context,
        1,
        (__) => p.content(),
        download: (_) => p.download(downloadManager, postTags),
      );
    }

    void onError(dynamic e, StackTrace trace) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }

      Logger.root.warning("SinglePost _launch", e, trace);
    }

    void onWhenComplete() {
      arrowSpinningController
        ?..stop()
        ..reverse();

      inProcessLoading = false;
    }

    if (replaceId != null) {
      return booru
          .singlePost(replaceId)
          .then(onThen)
          .onError(onError)
          .whenComplete(onWhenComplete);
    } else {
      final n = int.tryParse(controller.text);
      if (n == null) {
        throw l10n.notANumber(controller.text);
      }

      return booru
          .singlePost(n)
          .then(onThen)
          .onError(onError)
          .whenComplete(onWhenComplete);
    }
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
    final l10n = AppLocalizations.of(context)!;
    final downloadManager = DownloadManager.of(context);
    final postTags = PostTags.fromContext(context);

    return MenuAnchor(
      menuChildren: menuItems,
      controller: menuController,
      child: SearchBar(
        elevation: const WidgetStatePropertyAll(0),
        hintText: AppLocalizations.of(context)!.goPostHint,
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
            onPressed: () => _launch(downloadManager, l10n, postTags),
          ),
        ],
      ),
    );
  }
}
