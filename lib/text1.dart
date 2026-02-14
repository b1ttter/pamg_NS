import 'package:flutter/material.dart';

class Text1 extends StatelessWidget {
  @override
  const Text1(this.text, {super.key});
  final String text;

  Widget build(context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 24,
        color: const Color.fromARGB(255, 0, 0, 0),
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}