import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';

/// Boring, non-specific test data
class TestDummyData {
  static EvtDraft makeEvtDraft(int i) => EvtDraft.inCurrentTZ(
    i,
    start: DateTime(2024, 1, 1).add(Duration(days: i)),
    end: DateTime(2024, 1, 2).add(Duration(days: i)),
  );

  static EvtTypeDraft makeEvtTypeDraft(int i) => EvtTypeDraft('type $i');

  static EvtCatDraft makeEvtCatDraft(int i) => EvtCatDraft('cat $i');
}
