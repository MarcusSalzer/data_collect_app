import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/repos/blob_repos.dart';
import 'package:flutter/foundation.dart';

/// Loads and keeps blobs for certain events.
class BlobForEvtCache extends ChangeNotifier {
  final BlobRepo _repo;
  final Iterable<EvtRec>? Function() getEvts;
  BlobForEvtCache(this._repo, this.getEvts);

  // --- state ---
  Map<int, List<UserBlobRec>>? byEvt;

  List<UserBlobRec>? forEvt(int evtId) => byEvt?[evtId];

  /// Load all for the events.
  void load() async {
    final evtIds = getEvts()?.map((e) => e.id).toSet();
    if (evtIds == null) {
      return; // events not loaded yet
    }
    final blobs = await _repo.allWithEvtLink();

    // build the map
    final map = <int, List<UserBlobRec>>{};
    for (final b in blobs) {
      if (b.eventId case int evtId) {
        if (evtIds.contains(evtId)) {
          map.putIfAbsent(evtId, () => []).add(b);
        }
      }
    }
    byEvt = map;
    notifyListeners();
  }
}
