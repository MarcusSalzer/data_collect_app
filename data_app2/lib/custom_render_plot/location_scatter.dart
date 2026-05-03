import 'dart:math';
import 'package:data_app2/data/location.dart';
import 'package:data_app2/location_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ---- Projection helpers ----

// ---------------------------------------------------------------------------
// Projection helpers
// ---------------------------------------------------------------------------

double _mercatorY(double latDeg) {
  final latRad = latDeg * pi / 180;
  return (pi - log(tan(pi / 4 + latRad / 2))) / (2 * pi);
}

double _mercatorX(double lngDeg) => (lngDeg + 180) / 360;

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class LocationScatterMap extends StatefulWidget {
  const LocationScatterMap({super.key});

  @override
  State<LocationScatterMap> createState() => _LocationScatterMapState();
}

class _LocationScatterMapState extends State<LocationScatterMap> {
  final _transformController = TransformationController();
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    // The transformation matrix is a 4x4 stored row-major.
    // Entry [0] is the X scale, which equals the uniform zoom factor.
    final newScale = _transformController.value.getMaxScaleOnAxis();
    if (newScale != _scale) {
      setState(() => _scale = newScale);
    }
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<LocationManager>();
    final locations = manager.all;

    if (locations.isEmpty) {
      return const Center(child: Text('No locations yet'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return InteractiveViewer(
          transformationController: _transformController,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.5,
          maxScale: 20,
          child: CustomPaint(
            size: size,
            painter: _LocationMapPainter(
              locations: locations,
              theme: Theme.of(context),
              scale: _scale,
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _LocationMapPainter extends CustomPainter {
  _LocationMapPainter({
    required this.locations,
    required this.theme,
    required this.scale,
  });

  final List<LocationRec> locations;
  final ThemeData theme;
  final double scale;

  static const double _padding = 40.0;
  static const double _baseDotRadius = 5.0;
  static const double _baseFontSize = 11.0;
  static const double _minSpan = 0.002;
  static const double _boundaryPadFraction = 0.20;

  // Cached per paint call, derived from bounding box + canvas size
  late double _viewMinX;
  late double _viewMaxX;
  late double _viewMinY;
  late double _viewMaxY;
  late double _drawW;
  late double _drawH;

  Offset _project(double px, double py) {
    final cx = _padding + (px - _viewMinX) / (_viewMaxX - _viewMinX) * _drawW;
    final cy = _padding + (py - _viewMinY) / (_viewMaxY - _viewMinY) * _drawH;
    return Offset(cx, cy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final colorScheme = theme.colorScheme;

    // ---- Project all locations ----
    final projected = locations.map((loc) {
      return (loc: loc, x: _mercatorX(loc.lng), y: _mercatorY(loc.lat));
    }).toList();

    // ---- Bounding box in projected space ----
    final xs = projected.map((p) => p.x).toList();
    final ys = projected.map((p) => p.y).toList();
    final rawMinX = xs.reduce(min);
    final rawMaxX = xs.reduce(max);
    final rawMinY = ys.reduce(min);
    final rawMaxY = ys.reduce(max);

    // Enforce minimum span so a single point doesn't collapse
    final spanX = max(rawMaxX - rawMinX, _minSpan);
    final spanY = max(rawMaxY - rawMinY, _minSpan);

    // Re-centre the span if it was clamped (single point case)
    final centreX = (rawMinX + rawMaxX) / 2;
    final centreY = (rawMinY + rawMaxY) / 2;
    final clampedMinX = min(rawMinX, centreX - spanX / 2);
    final clampedMaxX = max(rawMaxX, centreX + spanX / 2);
    final clampedMinY = min(rawMinY, centreY - spanY / 2);
    final clampedMaxY = max(rawMaxY, centreY + spanY / 2);

    // 20% breathing room on each side
    final padX = spanX * _boundaryPadFraction;
    final padY = spanY * _boundaryPadFraction;
    _viewMinX = clampedMinX - padX;
    _viewMaxX = clampedMaxX + padX;
    _viewMinY = clampedMinY - padY;
    _viewMaxY = clampedMaxY + padY;

    _drawW = size.width - _padding * 2;
    _drawH = size.height - _padding * 2;

    // ---- Scale-compensated sizes ----
    final dotRadius = _baseDotRadius / scale;
    final fontSize = _baseFontSize / scale;
    final thinStroke = 0.5 / scale;
    final ringStroke = 1.5 / scale;
    final shadowOffset = Offset(1 / scale, 1 / scale);
    final labelGap = 5.0 / scale;

    // ---- Background ----
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = colorScheme.surfaceContainerLowest,
    );

    // ---- Grid ----
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.4)
      ..strokeWidth = thinStroke;
    for (int i = 1; i < 4; i++) {
      final x = _padding + _drawW * i / 4;
      canvas.drawLine(Offset(x, _padding), Offset(x, size.height - _padding), gridPaint);
      final y = _padding + _drawH * i / 4;
      canvas.drawLine(Offset(_padding, y), Offset(size.width - _padding, y), gridPaint);
    }

    // ---- Border ----
    canvas.drawRect(
      Rect.fromLTWH(_padding, _padding, _drawW, _drawH),
      Paint()
        ..color = colorScheme.outlineVariant
        ..style = PaintingStyle.stroke
        ..strokeWidth = thinStroke,
    );

    // ---- Dots + labels ----
    final dotPaint = Paint()..color = colorScheme.primary;
    final shadowPaint = Paint()..color = Colors.black26;
    final ringPaint = Paint()
      ..color = colorScheme.onPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringStroke;

    final labelStyle = theme.textTheme.labelSmall!.copyWith(
      color: colorScheme.onSurface,
      fontSize: fontSize,
      height: 1.0,
    );

    for (final p in projected) {
      final offset = _project(p.x, p.y);

      // Shadow
      canvas.drawCircle(offset + shadowOffset, dotRadius, shadowPaint);
      // Fill
      canvas.drawCircle(offset, dotRadius, dotPaint);
      // Ring
      canvas.drawCircle(offset, dotRadius, ringPaint);

      // Label
      final tp = TextPainter(
        text: TextSpan(text: p.loc.name, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 120 / scale);

      var labelX = offset.dx + dotRadius + labelGap;
      final labelY = offset.dy - tp.height / 2;

      // Flip to left if label would overflow right edge
      if (labelX + tp.width > size.width - _padding) {
        labelX = offset.dx - dotRadius - labelGap - tp.width;
      }

      tp.paint(canvas, Offset(labelX, labelY));
    }
  }

  @override
  bool shouldRepaint(_LocationMapPainter old) => old.locations != locations || old.scale != scale;
}
