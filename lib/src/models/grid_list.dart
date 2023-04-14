import 'core.dart';

import '../cell/cell.dart';

mixin GridList<T extends Cell> on CoreModel {
  final List<T> _list = [];

  //UnmodifiableListView<T> get directories => UnmodifiableListView(_list);

  void replace(List<T> newList) {
    _list.clear();
    _list.addAll(newList);

    notifyListeners();
  }

  bool isListEmpty() => _list.isEmpty;

  List<T> copy() => List.from(_list);

  Future refreshFuture(Future<List<T>> f,
      {Function(Object? error, StackTrace stackTrace) onError =
          _printToConsole}) {
    return f.then((value) {
      replace(value);
    }).onError((e, s) => onError(e, s));
  }
}

void _printToConsole(error, stackTrace) {
  print(error);
}
