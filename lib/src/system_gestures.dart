import 'package:flutter/widgets.dart';

Widget gestureDeadZones(BuildContext context,
    {required Widget child, bool left = false, bool right = false}) {
  var systemInsets = MediaQuery.systemGestureInsetsOf(context);
  if (systemInsets == EdgeInsets.zero) {
    return child;
  }

  return Stack(
    children: [
      child,
      if (left)
        Align(
          alignment: Alignment.centerLeft,
          child: AbsorbPointer(
            child: SizedBox(width: systemInsets.left, child: Container()),
          ),
        ),
      if (right)
        Align(
          alignment: Alignment.centerRight,
          child: AbsorbPointer(
            child: SizedBox(width: systemInsets.right, child: Container()),
          ),
        ),
      Align(
        alignment: Alignment.bottomCenter,
        child: AbsorbPointer(
          child: SizedBox(
            height: systemInsets.bottom,
            child: Container(),
          ),
        ),
      )
    ],
  );
}
