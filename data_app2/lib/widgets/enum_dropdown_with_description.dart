import 'package:data_app2/screens/settings_screen.dart';
import 'package:flutter/material.dart';

class EnumDropdownWithDescription<T extends Enum> extends StatelessWidget {
  final T value;
  final List<T> options;
  final ValueChanged<T> onChanged;
  final String Function(T) descriptionOf;

  final String label;

  final (int, int) flex;

  const EnumDropdownWithDescription({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.descriptionOf,
    this.flex = (3, 5),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.primaryContainer,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                flex: flex.$1,
                child: Text(label, style: TextStyle(fontSize: 16)),
              ),
              Expanded(
                flex: flex.$2,
                child: EnumDropdown<T>(
                  initialValue: value,
                  options: options,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              descriptionOf(value),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
