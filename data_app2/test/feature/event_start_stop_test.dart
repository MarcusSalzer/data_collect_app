import 'package:data_app2/app_state.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/view_models/event_create_vm.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_util/dummy_app.dart';

void main() {
  late final AppState app;
  setUpAll(() async {
    app = await getDummyApp();
  });
  test('can start an event', () async {
    final vm = EventCreateViewVM(app);

    await vm.addEventByName('TestEvent1232');
    final typ = app.evtTypeManager.resolveByName('TestEvent1232');
    expect(typ, isNotNull);
    final loaded = (await app.db.evts.latest(1)).first;
    expect(loaded.typeId, typ!.id);
  });
  test('can stop an event', () async {
    final vm = EventCreateViewVM(app);

    await vm.addEventByName('TestEvent1232');
    final t = LocalDateTime.now();
    await vm.stopEvent();
    final loaded = (await app.db.evts.latest(1)).first;
    expect(loaded.end, isNotNull);
    expect(loaded.end?.asUtcWithLocalValue.difference(t.asUtcWithLocalValue).inSeconds, lessThan(1));
  });
}
