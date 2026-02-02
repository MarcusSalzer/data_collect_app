import 'package:data_app2/contracts/data.dart';

/// Data class for event categories
class EvtCatDraft extends Draft<EvtCatRec> {
  EvtCatDraft(this.name);

  // === fields ===
  final String name;

  // TODO color
  // final dynamic color;

  EvtCatDraft copyWith({String? name}) {
    return EvtCatDraft(name ?? this.name);
  }

  @override
  toRec(int id) {
    return EvtCatRec(id, name);
  }
}

/// Data class for persisted event categories
class EvtCatRec implements Identifiable {
  final String name;

  EvtCatRec(this.id, this.name);
  @override
  final int id;

  @override
  EvtCatDraft toDraft() {
    return EvtCatDraft(name);
  }
}
