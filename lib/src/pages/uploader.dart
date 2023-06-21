import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/keybinds/keybinds.dart';
import 'package:gallery/src/pages/senitel.dart';
import 'package:gallery/src/pages/upload_info.dart';
import 'package:gallery/src/schemas/upload_files.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/gallery/uploader/uploader.dart' as impl;

class Uploader extends StatefulWidget {
  const Uploader({super.key});

  @override
  State<Uploader> createState() => _UploaderState();
}

class _UploaderState extends State<Uploader> {
  List<UploadFilesStack> stack = [];
  late StreamSubscription<void> update;

  final SkeletonState skeletonState = SkeletonState(kUploadsDrawerIndex);

  @override
  void initState() {
    super.initState();

    update = impl.Uploader()
        .uploadsDb
        .uploadFilesStacks
        .watchLazy(fireImmediately: true)
        .listen((event) {
      setState(() {
        stack = impl.Uploader().getStack();
      });
    });
  }

  @override
  void dispose() {
    update.cancel();
    skeletonState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return makeSkeleton(
        context, AppLocalizations.of(context)!.uploadPageName, skeletonState,
        children: stack.isEmpty ? [const EmptyWidget()] : null,
        itemCount: stack.length,
        builder: stack.isEmpty
            ? null
            : (context, indx) {
                var upload = stack[indx];
                return ListTile(
                  title: Text("Number of files: ${upload.count.toString()}"),
                  subtitle: Text("${upload.time}: ${upload.status.string}"),
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return UploadInfo(
                        stateId: upload.stateId,
                        status: upload.status,
                      );
                    }));
                  },
                );
              });
  }
}
