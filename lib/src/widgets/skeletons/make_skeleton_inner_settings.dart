import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../gesture_dead_zones.dart';
import '../keybinds/describe_keys.dart';
import '../keybinds/keybind_description.dart';
import '../keybinds/single_activator_description.dart';
import 'skeleton_state.dart';
import 'wrap_app_bar_action.dart';

Widget makeSkeletonInnerSettings(BuildContext context, String pageDescription,
    SkeletonState state, List<Widget> children,
    {List<Widget>? appBarActions}) {
  Map<SingleActivatorDescription, Null Function()> bindings = {
    SingleActivatorDescription(AppLocalizations.of(context)!.back,
        const SingleActivator(LogicalKeyboardKey.escape)): () {
      Navigator.pop(context);
    },
  };
  final insets = MediaQuery.viewPaddingOf(context);

  return CallbackShortcuts(
      bindings: {
        ...bindings,
        ...keybindDescription(context, describeKeys(bindings), pageDescription,
            () {
          state.mainFocus.requestFocus();
        })
      },
      child: Focus(
        autofocus: true,
        focusNode: state.mainFocus,
        child: Scaffold(
          drawerEnableOpenDragGesture:
              MediaQuery.systemGestureInsetsOf(context) == EdgeInsets.zero,
          body: gestureDeadZones(context,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar.large(
                    expandedHeight: 160,
                    flexibleSpace: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: FlexibleSpaceBar(
                          title: Text(
                            pageDescription,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        )),
                        if (appBarActions != null)
                          ...appBarActions.map((e) => wrapAppBarAction(e))
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.only(bottom: insets.bottom),
                    sliver:
                        SliverList(delegate: SliverChildListDelegate(children)),
                  )
                ],
              )),
        ),
      ));
}
