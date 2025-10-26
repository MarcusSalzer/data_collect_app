import 'package:data_app2/util.dart';
import 'package:flutter/material.dart';

Future<T?> showConfirmSaveBackDialog<T>(BuildContext context,
    {required Future<T> Function() saveAction}) {
  return showDialog<T?>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Save Changes?'),
        content: const Text('Data was updated'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge),
            child: const Text('Discard'),
            onPressed: () {
              simpleSnack(context, "Discarded changes");
              Navigator.of(context).pop(null);
              Navigator.of(context).pop(null);
            },
          ),
          TextButton(
            style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge),
            child: const Text('Save'),
            onPressed: () async {
              final edited = await saveAction();
              if (context.mounted) {
                // close dialog
                Navigator.of(context).pop(edited);
                // exit screen
                Navigator.of(context).pop(edited);
              }
            },
          ),
        ],
      );
    },
  );
}
