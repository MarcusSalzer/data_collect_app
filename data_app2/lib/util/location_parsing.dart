// import 'package:plus_codes/plus_codes.dart';

/// Lat/lng value object used only during parsing
class LatLng {
  const LatLng(this.lat, this.lng);
  final double lat;
  final double lng;
}

/// Try to parse a user-pasted coordinate string.
/// Supports:
///   - Decimal degrees:  "55.7047, 13.1910"  or  "55.7047 13.1910"
///   - DMS:              "55°42'17\"N 13°11'28\"E"
///   - Plus Code (OLC):  "9F7J3W8G+QR"
///   - Map URL:  ".../@55.7047,13.1910,15z/..."
LatLng? tryParseCoordinates(String input) {
  final s = input.trim();
  if (s.isEmpty) return null;

  // Map URL — extract @lat,lng
  final urlMatch = RegExp(r'@(-?\d+\.?\d*),(-?\d+\.?\d*)').firstMatch(s);
  if (urlMatch != null) {
    return _tryLatLng(urlMatch.group(1)!, urlMatch.group(2)!);
  }

  // Plus Code (OLC) — contains a '+' and no '@'
  // if (s.contains('+') && !s.contains('@')) {
  //   try {
  //     final codec = OpenLocationCode();
  //     final area = codec.decode(s);
  //     return LatLng(area.center.latitude, area.center.longitude);
  //   } catch (_) {}
  // }

  // DMS — e.g. 55°42'17"N 13°11'28"E
  final dmsMatch = RegExp(
    r"""(\d+)[°d]\s*(\d+)[''']\s*([\d.]+)[""s]?\s*([NS])\s+(\d+)[°d]\s*(\d+)[''']\s*([\d.]+)[""s]?\s*([EW])""",
    caseSensitive: false,
  ).firstMatch(s);
  if (dmsMatch != null) {
    final lat = _dmsToDecimal(
      dmsMatch.group(1)!,
      dmsMatch.group(2)!,
      dmsMatch.group(3)!,
      dmsMatch.group(4)!,
    );
    final lng = _dmsToDecimal(
      dmsMatch.group(5)!,
      dmsMatch.group(6)!,
      dmsMatch.group(7)!,
      dmsMatch.group(8)!,
    );
    if (lat != null && lng != null) return LatLng(lat, lng);
  }

  // Decimal degrees — "55.7047, 13.1910" or "55.7047 13.1910"
  final parts = s.split(RegExp(r'[,\s]+'));
  if (parts.length == 2) {
    return _tryLatLng(parts[0], parts[1]);
  }

  return null;
}

LatLng? _tryLatLng(String latStr, String lngStr) {
  final lat = double.tryParse(latStr);
  final lng = double.tryParse(lngStr);
  if (lat == null || lng == null) return null;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
  return LatLng(lat, lng);
}

double? _dmsToDecimal(String deg, String min, String sec, String dir) {
  final d = double.tryParse(deg);
  final m = double.tryParse(min);
  final s = double.tryParse(sec);
  if (d == null || m == null || s == null) return null;
  final decimal = d + m / 60 + s / 3600;
  return (dir.toUpperCase() == 'S' || dir.toUpperCase() == 'W') ? -decimal : decimal;
}
