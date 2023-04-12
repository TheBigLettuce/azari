import 'package:flutter/material.dart';

import 'cell.dart';
import 'data.dart';

class CellImageWidget<T extends Cell> extends StatefulWidget {
  final T _data;
  final Null Function(BuildContext context, T cell) onPressed;
  //final double _ext;

  const CellImageWidget({Key? key, required T cell, required this.onPressed})
      : _data = cell,
        //_ext = extend,
        super(key: key);

  @override
  State<CellImageWidget> createState() => _CellImageWidgetState();
}

class _CellImageWidgetState<T extends Cell> extends State<CellImageWidget<T>> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: widget._data.getFile(),
        builder: ((context, snapshot) {
          if (snapshot.hasData) {
            var data = snapshot.data as CellData;

            return InkWell(
              splashColor: Colors.indigo,
              //focusColor: Colors.purple,
              hoverColor: Colors.indigoAccent,
              borderRadius: BorderRadius.circular(15.0),
              onTap: () {
                widget.onPressed(context, widget._data);
              },
              child: Card(
                  elevation: 0,
                  child: ClipPath(
                    clipper: ShapeBorderClipper(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0))),
                    child: Stack(
                      children: [
                        Image.memory(data.thumb),
                        Container(
                          alignment: Alignment.bottomCenter,
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                Colors.black.withAlpha(50),
                                Colors.black12,
                                Colors.black45
                              ])),
                          child: Text(
                            data.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )),
            );
          } else if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          } else {
            return const CircularProgressIndicator();
          }
        }));
  }
}
