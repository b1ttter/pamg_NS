import 'package:flutter/material.dart';
import 'package:lab1/FLMap.dart';


var begin = Alignment.topCenter;
var end = Alignment.bottomCenter;
//zmiene dynamiczne a statyczne
//final a const 
//stateless a stateful

class GradientContainer extends StatelessWidget {
const GradientContainer({super.key});

    @override
  Widget build(context) {

  return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: end,
            colors: [
              Color.fromARGB(255, 123, 189, 243),
              Color.fromARGB(255, 0, 0, 0),
            ],
          ),
        ),
        child: MapFl()
      );
  }

}

