// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/gallery/uploader/uploader.dart';
import 'package:gallery/src/keybinds/keybinds.dart';
import 'package:gallery/src/pages/senitel.dart';
import 'package:gallery/src/schemas/upload_files.dart';
import 'package:gallery/src/schemas/upload_files_state.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';

class UploadInfo extends StatefulWidget {
  final int stateId;
  final UploadStatus status;
  const UploadInfo({super.key, required this.stateId, required this.status});

  @override
  State<UploadInfo> createState() => _UploadInfoState();
}

class _UploadInfoState extends State<UploadInfo> {
  FocusNode focus = FocusNode();
  late StreamSubscription<void> update;
  UploadFilesState? state;

  @override
  void initState() {
    super.initState();

    update = Uploader()
        .uploadsDb
        .uploadFilesStates
        .watchObject(widget.stateId, fireImmediately: true)
        .listen((event) {
      if (event == null) {
        Navigator.pop(context);
      } else {
        setState(() {
          state = event;
        });
      }
    });
  }

  @override
  void dispose() {
    update.cancel();
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Map<SingleActivatorDescription, Null Function()> bindings = {
      SingleActivatorDescription(AppLocalizations.of(context)!.back,
          const SingleActivator(LogicalKeyboardKey.escape)): () {
        Navigator.pop(context);
      },
      ...digitAndSettings(context, kUploadsDrawerIndex)
    };
    return makeSkeleton(
      context,
      kUploadsDrawerIndex,
      "Uploads inner",
      focus,
      bindings,
      AppBar(
        title: Text(widget.status == UploadStatus.failed
            ? "Upload (failed)"
            : "Upload info"),
      ),
      state == null
          ? const EmptyWidget()
          : ListView.builder(
              itemCount: state!.upload.length,
              itemBuilder: (context, index) {
                var upload = state!.upload[index];

                return ListTile(
                  title: Text(
                    upload.name!,
                    style: const TextStyle(overflow: TextOverflow.ellipsis),
                    maxLines: 1,
                    softWrap: false,
                  ),
                  subtitle: upload.failReason! == ""
                      ? null
                      : Text(upload.failReason!),
                );
              },
            ),
      overrideOnPop: () => Future.value(true),
    );
  }
}
