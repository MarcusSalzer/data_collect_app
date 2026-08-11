import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/repos/blob_repos.dart';
import 'package:flutter/foundation.dart';

/// Loads and keeps blobs for certain events.
class BlobForEvtCache extends ChangeNotifier {
  final BlobRepo _repo;

  BlobForEvtCache(this._repo);

  // --- state ---
  Map<int, List<UserBlobRec>>? byEvt;

  List<UserBlobRec>? forEvt(int evtId) => byEvt?[evtId];

  /// Load all for the events.
  void load(Set<int> evtIds) async {
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
