import 'package:flutter/material.dart';

void simpleSnack(BuildContext context, String text, {Color? color}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        text,
        style: TextStyle(color: color),
      ),
    ),
  );
}
