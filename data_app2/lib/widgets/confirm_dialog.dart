import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final Function action;
  final String title;
  const ConfirmDialog({
    required this.title,
    required this.action,
    super.key,
  });

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
                child: Text("cancel")),
            ElevatedButton.icon(
              onPressed: () async {
                await action();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              label: Text("confirm"),
              icon: Icon(Icons.warning),
            ),
          ],
        ),
      ],
    );
  }
}
