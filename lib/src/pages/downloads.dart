// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/pages/senitel.dart';
import 'package:gallery/src/booru/downloader/downloader.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/schemas/download_file.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  final SkeletonState skeletonState = SkeletonState(kDownloadsDrawerIndex);

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

    skeletonState.dispose();

    super.dispose();
  }

  void _refresh() {
    if (refreshController != null) {
      refreshController!.forward(from: 0);
    }

    downloader.markStale();
  }

  int _inProcess() => isar().files.filter().isFailedEqualTo(false).countSync();

  @override
  Widget build(BuildContext context) {
    return makeSkeleton(
        context, AppLocalizations.of(context)!.downloadsPageName, skeletonState,
        appBarActions: [
          Badge(
            offset: Offset.zero,
            alignment: Alignment.topLeft,
            isLabelVisible: _files != null ? _files!.isNotEmpty : false,
            label: Text(
                "${_inProcess().toString()}/${_files == null ? 0 : _files!.length.toString()}"),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                  onTap: () {
                    if (deleteController != null) {
                      deleteController!.forward(from: 0);
                    }
                    downloader.removeFailed();
                  },
                  child: const Icon(Icons.close).animate(
                      onInit: (controller) => deleteController = controller,
                      effects: const [FlipEffect(begin: 1, end: 0)],
                      autoPlay: false)),
              PopupMenuItem(
                  onTap: _refresh,
                  child: const Icon(Icons.refresh).animate(
                      onInit: (controller) => refreshController = controller,
                      effects: const [RotateEffect()],
                      autoPlay: false)),
              PopupMenuItem(
                  onTap: downloader.restart,
                  child: const Icon(Icons.start_outlined)),
            ],
          ),
        ],
        itemCount: _files != null ? _files!.length : 0,
        children:
            _files == null || _files!.isEmpty ? [const EmptyWidget()] : null,
        builder: _files == null || _files!.isEmpty
            ? null
            : (context, indx) => ListTile(
                  onLongPress: () {
                    var file = _files![indx];
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
                                      child: Text(
                                          AppLocalizations.of(context)!.no)),
                                  TextButton(
                                      onPressed: () {
                                        downloader.retry(file);
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                          AppLocalizations.of(context)!.yes)),
                                ],
                                title: Text(downloader.downloadAction(file)),
                                content: Text(file.name),
                              );
                            }));
                  },
                  title: Text("${_files![indx].site}: ${_files![indx].name}"),
                  subtitle: Text(downloader.downloadDescription(_files![indx])),
                ));
  }
}
