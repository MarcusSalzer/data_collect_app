import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/evt_type_manager.dart';
import 'package:data_app2/util/stats.dart';

// abstract class EvtSuggestionEngine {
//   EvtTypeRec get({int n = 20});
// }

class FrequencySuggestionEngine {
  final EvtTypeManager _typeManager;

  FrequencySuggestionEngine(this._typeManager);

  Iterable<EvtTypeRec> get(Iterable evts, {int n = 20}) {
    var counts = valueCounts<int>(evts.map((e) => e.typeId));

    final f = Map.fromEntries(counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
    return f.keys.take(n).map(_typeManager.typeFromId).removeNulls;
  }
}
