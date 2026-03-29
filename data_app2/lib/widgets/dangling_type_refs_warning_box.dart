import 'package:flutter/material.dart';

class DanglingTypeRefsWarningBox extends StatelessWidget {
  final Iterable<int> danglingTypeRefs;

  const DanglingTypeRefsWarningBox(this.danglingTypeRefs, {super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.brown,
      padding: EdgeInsets.all(8),
      child: Column(
        spacing: 12,
        children: [
          Text("We have dangling type references", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(danglingTypeRefs.toString(), style: TextStyle(fontFamily: "monospace")),
          Text("Try importing the correct types, or make new ones to override"),
        ],
      ),
    );
  }
}
