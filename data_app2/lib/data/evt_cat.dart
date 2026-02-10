import 'dart:ui';

import 'package:data_app2/contracts/data.dart';
import 'package:data_app2/util/colors.dart';

/// Data class for event categories
class EvtCatDraft extends Draft<EvtCatRec> {
  EvtCatDraft(this.name, [this.color = ColorEngine.defaultColor]);

  // === fields ===
  String name;
  Color color;

  EvtCatDraft copyWith({String? name}) {
    return EvtCatDraft(name ?? this.name);
  }

  @override
  toRec(int id) {
    return EvtCatRec(id, name, color);
  }

  @override
  bool operator ==(Object other) {
    return other is EvtCatDraft && other.name == name && other.color == color;
  }

  @override
  int get hashCode => name.hashCode;
}

/// Data class for persisted event categories
class EvtCatRec implements Identifiable {
  final String name;

  EvtCatRec(this.id, this.name, [this.color = ColorEngine.defaultColor]);
  @override
  final int id;
  final Color color;

  @override
  EvtCatDraft toDraft() {
    return EvtCatDraft(name, color);
  }
}
