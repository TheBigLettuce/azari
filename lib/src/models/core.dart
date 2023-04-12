import 'package:flutter/material.dart';

abstract class CoreModel<T> extends ChangeNotifier {
  Future refresh();

  Future<List<T>> fetchRes();
}
