import 'package:flutter/material.dart';

enum ColorKey {
  // item 0: default/base color
  base(light: Colors.grey, dark: Color(0xFFAAAAAA)),
  // Nice colors
  red(light: Colors.red, dark: Color.fromARGB(255, 255, 83, 83)),
  green(light: Colors.green, dark: Color(0xFF66FF88)),
  blue(light: Colors.blue, dark: Color(0xFF42A5FF)),
  amber(light: Colors.amber, dark: Color(0xFFFFCABB)),
  orange(light: Colors.orange, dark: Color(0xFFFFDA90)),
  cyan(light: Colors.cyan, dark: Color.fromARGB(255, 150, 212, 223)),
  purple(light: Colors.purple, dark: Color.fromARGB(255, 180, 67, 200));

  final Color light;
  final Color dark;

  const ColorKey({required this.light, required this.dark});

  // color based on the current theme
  Color inContext(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }

  int asInt() {
    return light.toARGB32();
  }
}

final colorKeysByName = Map.fromEntries(ColorKey.values.map((e) => MapEntry(e.name, e)));

/// Allow nicely distributed groups of colors
class ComputedColors {
  const ComputedColors();
  static const nBaseHues = 9;

  List<HSLColor> baseHues() {
    const dStep = 360 / nBaseHues;
    return List.generate(nBaseHues, (i) => HSLColor.fromAHSL(1.0, i * dStep, 0.7, 0.5));
  }
}

class ColorEngine {
  static const defaults = {
    "amber": Colors.amber,
    "blue": Colors.blue,
    "cyan": Colors.cyan,
    "green": Colors.green,
    "grey": Colors.grey,
    "orange": Colors.orange,
    "pink": Colors.pink,
    "red": Colors.red,
  };
  static const defaultColor = Colors.grey;

  static Color spread(
    Color base,
    int index,
    int count,
    double spreadFactor, // [0, 1]
  ) {
    final hsl = HSLColor.fromColor(base);

    // center around base
    final mid = (count - 1) / 2;
    final offset = index - mid;
    final norm = offset / (count == 1 ? 1 : mid);

    final hueShift = spreadFactor * 20 * norm; // degrees
    final lightShift = spreadFactor * 0.15 * norm; // lightness

    return hsl
        .withHue((hsl.hue + hueShift) % 360)
        .withLightness((hsl.lightness + lightShift).clamp(0.15, 0.85))
        .toColor();
  }
}

class CategoryColorContext {
  final Map<int, CategoryRenderInfo> _info;

  CategoryColorContext(this._info);

  Color colorFor({required int categoryId, required int itemId, required double spread}) {
    final info = _info[categoryId]!;
    final index = info.itemIndex[itemId]!;
    return ColorEngine.spread(info.baseColor, index, info.count, spread);
  }
}

class CategoryRenderInfo {
  final Color baseColor;
  final int count;
  final Map<int, int> itemIndex;

  CategoryRenderInfo({required this.baseColor, required this.count, required this.itemIndex});
}

// CategoryColorContext buildColorContext<T>({
//   required Iterable<T> items,
//   required int Function(T) categoryIdOf,
//   required int Function(T) itemIdOf,
// }) {
//   final itemsByCat = <int, List<T>>{};

//   for (final item in items) {
//     final catId = categoryIdOf(item);
//     itemsByCat.putIfAbsent(catId, () => []).add(item);
//   }

//   final info = <int, CategoryRenderInfo>{};

//   itemsByCat.forEach((catId, catItems) {
//     final cat = _byId[catId]!; // your cached category

//     final indexMap = <int, int>{};
//     for (int i = 0; i < catItems.length; i++) {
//       indexMap[itemIdOf(catItems[i])] = i;
//     }

//     info[catId] = CategoryRenderInfo(baseColor: cat.color, count: catItems.length, itemIndex: indexMap);
//   });

//   return CategoryColorContext(info);
// }
