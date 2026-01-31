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
  EvtCatRec toRec(int id) {
    return EvtCatRec(id, name);
  }
}

/// Data class for persisted event categories
class EvtCatRec extends EvtCatDraft implements Identifiable {
  EvtCatRec(this.id, super.name);
  @override
  final int id;

  EvtCatDraft toDraft() {
    return EvtCatDraft(name);
  }
}
