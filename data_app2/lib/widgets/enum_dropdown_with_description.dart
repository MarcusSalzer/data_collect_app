import 'package:data_app2/screens/settings_screen.dart';
import 'package:flutter/material.dart';

/// Container for a single setting
class SettingContainer extends StatelessWidget {
  final String label;
  final String description;
  final (int, int) flex;

  final Widget child;

  const SettingContainer(this.label, this.description, {required this.child, this.flex = (3, 5), super.key});

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
              Expanded(flex: flex.$2, child: child),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

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
    return SettingContainer(
      label,
      descriptionOf(value),
      child: EnumDropdown<T>(initialValue: value, options: options, onChanged: onChanged),
    );
  }
}
