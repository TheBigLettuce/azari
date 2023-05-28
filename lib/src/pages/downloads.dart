// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/pages/senitel.dart';
import 'package:gallery/src/booru/downloader/downloader.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/schemas/download_file.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:isar/isar.dart';

import '../keybinds/keybinds.dart';

class Downloads extends StatefulWidget {
  const Downloads({super.key});

  @override
  State<Downloads> createState() => _DownloadsState();
}

class _DownloadsState extends State<Downloads> {
  List<File>? _files;
  late final StreamSubscription<void> _updates;
  final Downloader downloader = Downloader();

  FocusNode mainFocus = FocusNode();

  AnimationController? refreshController;
  AnimationController? deleteController;

  @override
  void initState() {
    super.initState();

    downloader.markStale();

    _updates = isar().files.watchLazy(fireImmediately: true).listen((_) async {
      var filesInProgress = await isar()
          .files
          .filter()
          .inProgressEqualTo(true)
          .sortByDateDesc()
          .findAll();
      var files = await isar()
          .files
          .filter()
          .inProgressEqualTo(false)
          .sortByDateDesc()
          .findAll();
      filesInProgress.addAll(files);
      setState(() {
        _files = filesInProgress;
      });
    });
  }

  @override
  void dispose() {
    _updates.cancel();

    mainFocus.dispose();

    super.dispose();
  }

  // ignore: prefer_void_to_null
  Null _refresh() {
    if (refreshController != null) {
      refreshController!.forward(from: 0);
    }

    downloader.markStale();
  }

  int _inProcess() => isar().files.filter().isFailedEqualTo(false).countSync();

  @override
  Widget build(BuildContext context) {
    Map<SingleActivatorDescription, Null Function()> bindings = {
      const SingleActivatorDescription(
          "Back", SingleActivator(LogicalKeyboardKey.escape)): () {
        popUntilSenitel(context);
      },
      const SingleActivatorDescription("Refresh and mark stale downloads",
          SingleActivator(LogicalKeyboardKey.f5)): _refresh,
      ...digitAndSettings(context, kDownloadsDrawerIndex)
    };

    return makeSkeleton(
        context,
        kDownloadsDrawerIndex,
        "Downloads",
        mainFocus,
        bindings,
        AppBar(
          title: Text(
            _files == null
                ? "Downloads"
                : _files!.isEmpty
                    ? "Downloads (empty)"
                    : "Downloads (${_inProcess().toString()}/${_files!.length.toString()})",
          ),
          actions: [
            IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))
                .animate(
                    onInit: (controller) => refreshController = controller,
                    effects: const [RotateEffect()],
                    autoPlay: false),
            IconButton(
                    onPressed: () {
                      if (deleteController != null) {
                        deleteController!.forward(from: 0);
                      }
                      downloader.removeFailed();
                    },
                    icon: const Icon(Icons.close))
                .animate(
                    onInit: (controller) => deleteController = controller,
                    effects: const [FlipEffect(begin: 1, end: 0)],
                    autoPlay: false)
          ],
        ),
        _files == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView.builder(
                itemCount: _files!.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onLongPress: () {
                      var file = _files![index];
                      Navigator.push(
                          context,
                          DialogRoute(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  actions: [
                                    TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text("no")),
                                    TextButton(
                                        onPressed: () {
                                          downloader.retry(file);
                                          Navigator.pop(context);
                                        },
                                        child: const Text("yes")),
                                  ],
                                  title: Text(downloader.downloadAction(file)),
                                  content: Text(file.name),
                                );
                              }));
                    },
                    title:
                        Text("${_files![index].site}: ${_files![index].name}"),
                    subtitle:
                        Text(downloader.downloadDescription(_files![index])),
                  );
                },
              ));
  }
}
