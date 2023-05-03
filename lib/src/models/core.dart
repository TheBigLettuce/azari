import 'package:flutter/material.dart';

abstract class CoreModel<T> extends ChangeNotifier {
  Future refresh();

  Future delete(int indx);

  Future<List<T>> fetchRes();
}
