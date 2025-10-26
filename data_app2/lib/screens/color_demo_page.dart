import 'package:data_app2/colors.dart';
import 'package:flutter/material.dart';

class ColorDemoPage extends StatelessWidget {
  ColorDemoPage({super.key});

  static const colorComp = ComputedColors();

  final List<Color> baseHues =
      colorComp.baseHues().map((c) => c.toColor()).toList();

  /// Generate N hue variants around the base color.
  List<Color> generateVariants(Color base, {int count = 5}) {
    final hsl = HSLColor.fromColor(base);
    return List.generate(count, (i) {
      final shift = (i - (count - 1) / 2) * 8.0;
      return hsl.withHue((hsl.hue + shift) % 360).toColor();
    });
  }

  /// Accent: brighter + more saturated
  Color computeAccent(Color base) {
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness((hsl.lightness * 1.2).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation * 1.3).clamp(0.0, 1.0))
        .toColor();
  }

  /// Background: darker in dark mode, lighter in light mode
  Color computeBackground(Color base, Brightness brightness) {
    final hsl = HSLColor.fromColor(base);
    if (brightness == Brightness.dark) {
      return hsl.withLightness((hsl.lightness * 0.2).clamp(0.0, 1.0)).toColor();
    } else {
      return hsl.withLightness((hsl.lightness * 1.8).clamp(0.0, 1.0)).toColor();
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(title: const Text("Color Variants Demo")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: baseHues.map((base) {
            final variants = generateVariants(base);
            return Expanded(
              child: Row(
                children: variants.map((variant) {
                  final accent = computeAccent(variant);
                  final background = computeBackground(variant, brightness);
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: background,
                        border: Border.all(color: accent, width: 4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          "Bkg\nAcc",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
