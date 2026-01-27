import 'package:data_app2/isar_models.dart';

/// Data class for event categories
class EvtCatRec {
  // TODO: i will try to avoid nullable ids!
  final int id;
  final String name;

  EvtCatRec(this.id, this.name);
  // TODO color
  // final dynamic color;

  /// Create from Isar record
  factory EvtCatRec.fromIsar(EventCategory cat) {
    return EvtCatRec(cat.id, cat.name);
  }
}
