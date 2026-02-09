import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/text_search.dart';
import 'package:flutter/material.dart';

class GenericAutocomplete<T extends Object> extends StatelessWidget {
  final List<T> options;
  final void Function(T) onSelected;
  final String Function(T) nameOf;
  final T? initialValue;

  /// Optional custom row widget builder
  final Widget Function(BuildContext context, T option)? optionBuilder;

  final String label;
  final TextSearchMode searchMode;

  const GenericAutocomplete({
    super.key,
    required this.options,
    required this.onSelected,
    required this.nameOf,
    required this.searchMode,
    this.initialValue,
    this.optionBuilder,
    this.label = "Select",
  });

  @override
  Widget build(BuildContext context) {
    final initV = initialValue;
    return Autocomplete<T>(
      initialValue: TextEditingValue(text: initV != null ? nameOf(initV) : ""),
      optionsBuilder: (textEditingValue) {
        final q = textEditingValue.text.trim();

        if (q.isEmpty) return options;
        return textSearchFilter<T>(q, options, searchMode, nameOf);
      },
      displayStringForOption: nameOf,
      onSelected: onSelected,
      optionsViewBuilder: (context, onSelected, filteredOptions) {
        return Material(
          elevation: 4,
          child: SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: filteredOptions.length,
              itemBuilder: (context, i) {
                final opt = filteredOptions.elementAt(i);

                return InkWell(
                  onTap: () => onSelected(opt),
                  child:
                      optionBuilder?.call(context, opt) ??
                      Padding(padding: const EdgeInsets.all(12), child: Text(nameOf(opt))),
                );
              },
            ),
          ),
        );
      },

      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          onFieldSubmitted: (_) => onSubmit(),
        );
      },
    );
  }
}
