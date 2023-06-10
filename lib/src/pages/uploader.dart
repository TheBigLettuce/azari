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
  FocusNode focus = FocusNode();
  List<UploadFilesStack> stack = [];
  late StreamSubscription<void> update;

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
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Map<SingleActivatorDescription, Null Function()> bindings = {
      SingleActivatorDescription(AppLocalizations.of(context)!.back,
          const SingleActivator(LogicalKeyboardKey.escape)): () {
        popUntilSenitel(context);
      },
      ...digitAndSettings(context, kUploadsDrawerIndex)
    };
    return makeSkeleton(
        context,
        kUploadsDrawerIndex,
        AppLocalizations.of(context)!.uploadPageName,
        focus,
        bindings,
        AppBar(
          title: Text(AppLocalizations.of(context)!.uploadPageName),
        ),
        stack.isEmpty
            ? const EmptyWidget()
            : ListView.builder(
                itemCount: stack.length,
                itemBuilder: (context, indx) {
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
                },
              ));
  }
}
