import 'dart:collection';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/app_prefs.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/screens/events/complete_export_screen.dart';
import 'package:data_app2/screens/events/evt_detail_screen.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:data_app2/view_models/evt_create_vm.dart';
import 'package:data_app2/widgets/evt_create_menu.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.select<AppState, AppPrefs>((a) => a.prefs);

    return DefaultTabController(
      length: 2,
      child: ChangeNotifierProvider<EvtCreateVm>(
        create: (createCtx) {
          final app = createCtx.read<AppState>();
          return EvtCreateVm(app.db, app.evtTypeManager, prefs.autoLowerCase)..load();
        },
        child: Builder(
          builder: (context) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Events'),
                actions: [
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => CompleteExportScreen()));
                    },
                    child: Padding(padding: const EdgeInsets.all(8.0), child: Text("Export")),
                  ),
                ],
                bottom: TabBar(
                  tabs: [
                    const Tab(text: "add"),
                    const Tab(text: "history"),
                  ],
                ),
              ),
              body: TabBarView(children: [EvtCreateMenu(), EvtHistoryList()]),
            );
          },
        ),
      ),
    );
  }
}

class EvtHistoryList extends StatelessWidget {
  final GroupFreq? headingMode;

  const EvtHistoryList({super.key, this.headingMode = GroupFreq.day});

  String? _getHeading(List<EvtRec> evts, int i) {
    if (headingMode == null) {
      return null;
    }
    var doHeading = false;
    if (i == 0) {
      doHeading = true;
    } else {
      final cur = evts[i].start?.asUtcWithLocalValue;
      final pre = evts[i - 1].start?.asUtcWithLocalValue;
      switch (headingMode) {
        case GroupFreq.day:
          doHeading = cur?.day != pre?.day;
          break;
        case GroupFreq.week:
          doHeading = cur?.startOfweek != pre?.startOfweek;
          break;
        case GroupFreq.month:
          doHeading = cur?.startOfMonth != pre?.startOfMonth;
          break;
        case null:
          return null;
      }
    }

    return doHeading ? Fmt.verboseDate(evts[i].start?.asUtcWithLocalValue, f: headingMode) : null;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EvtCreateVm>();
    // events are stored chronological, reverse the list for display
    // this also affects headings
    final evts = vm.evts.reversed.toList();
    if (evts.isEmpty) {
      return Center(child: Text("No events"));
    }
    return Padding(
      padding: const EdgeInsets.all(4),
      child: ListView.builder(
        itemCount: vm.evts.length,
        itemBuilder: (context, i) {
          return _EventListTile(evt: evts[i], heading: _getHeading(evts, i), reloadAction: vm.load);
        },
      ),
    );
  }
}

class _EventListTile extends StatelessWidget {
  const _EventListTile({required this.evt, this.heading, required this.reloadAction});

  final EvtRec evt;
  final String? heading;
  final Function reloadAction;

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context, listen: false);
    final (startText, endText) = Fmt.eventTimes(evt);
    final wdStart = Fmt.dayAbbr(evt.start?.asUtcWithLocalValue);
    final wdEnd = (evt.end?.asUtcWithLocalValue.day != evt.start?.asUtcWithLocalValue.day)
        ? Fmt.dayAbbr(evt.end?.asUtcWithLocalValue)
        : null;

    final dur = evt.duration;
    final durTxt = " (${Fmt.durationHmVerbose(dur)})";
    final typ = app.evtTypeManager.typeFromId(evt.typeId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (heading != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.blueGrey)),
              ),
              child: Center(
                child: Text(heading ?? "---", style: TextStyle(color: Colors.grey)),
              ),
            ),
          ),
        ListTile(
          title: Text("${typ?.name}$durTxt", style: TextStyle(color: app.colorFor(typ))),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              spacing: 4,
              children: [
                Text(wdStart, style: TextStyle(color: Colors.blueGrey)),
                Text(startText),
                Text(" - "),
                if (wdEnd != null) Text(wdEnd, style: TextStyle(color: Colors.blueGrey)),
                Text(endText),
              ],
            ),
          ),
          onTap: () {
            _openDetail(context);
          },
        ),
      ],
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => EvtDetailScreen(evt))).then((_) {
      // When the detail view is popped, data might have changed
      reloadAction();
    });
  }
}
