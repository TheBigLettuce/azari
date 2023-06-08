import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/keybinds/keybinds.dart';
import 'package:gallery/src/pages/senitel.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Uploader extends StatefulWidget {
  const Uploader({super.key});

  @override
  State<Uploader> createState() => _UploaderState();
}

class _UploaderState extends State<Uploader> {
  FocusNode focus = FocusNode();

  @override
  void dispose() {
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
        Container());
  }
}
