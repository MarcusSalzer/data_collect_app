import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final Function action;
  final String title;
  final String actionName;
  const ConfirmDialog({required this.title, required this.action, this.actionName = "confirm", super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: EdgeInsets.all(20),
      title: Text(title),
      children: [
        Row(
          children: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("cancel"),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await action();
              },
              label: Text(actionName),
              icon: Icon(Icons.warning),
            ),
          ],
        ),
      ],
    );
  }
}
