import 'package:flutter/material.dart';

class DayScreen extends StatefulWidget {
  final DateTime dt;
  const DayScreen(this.dt, {super.key});

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  late DateTime dt;
  @override
  void initState() {
    dt = widget.dt;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(dt.toString()),
      ),
    );
  }
}
