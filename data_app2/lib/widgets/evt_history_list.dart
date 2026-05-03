import 'dart:collection';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/app_prefs.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/data/location.dart';
import 'package:data_app2/evt_type_manager.dart';
import 'package:data_app2/location_manager.dart';
import 'package:data_app2/screens/events/evt_detail_screen.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EvtHistoryList extends StatelessWidget {
  final GroupFreq? headingMode;
  final UnmodifiableListView<EvtRec>? evts;
  final VoidCallback reloadAction; // NOTE: for now not event-specific
  final bool reversed;
  const EvtHistoryList(
    this.evts,
    this.reloadAction, {
    super.key,
    this.reversed = false,
    this.headingMode = GroupFreq.day,
  });

  String? _getHeading(List<EvtRec> evts, int i) {
    if (headingMode == null) {
      return null;
    }
    var doHeading = false;
    if (i == 0) {
      doHeading = true;
    } else {
      final cur = evts[i].start?.asLocal;
      final pre = evts[i - 1].start?.asLocal;
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

    return doHeading ? Fmt.verboseDate(evts[i].start?.asLocal, f: headingMode) : null;
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.select<AppState, AppPrefs>((a) => a.prefs);
    final typMan = context.select<AppState, EvtTypeManager>((a) => a.evtTypeManager);
    final locMan = context.watch<LocationManager>();
    // reverse the list for display
    // doing this outside listview also affects headings
    final evtsShow = reversed ? evts?.reversed.toList() : evts;
    if (evtsShow == null) {
      return Center(child: Text("Loading..."));
    }
    if (evtsShow.isEmpty) {
      return Center(child: Text("No events"));
    }

    return Padding(
      padding: const EdgeInsets.all(4),
      child: ListView.builder(
        itemCount: evtsShow.length,
        itemBuilder: (context, i) {
          final e = evtsShow[i];
          return _EventListTile(
            e,
            typMan.typeFromId(e.typeId),
            typMan.colorForId(e.typeId, prefs.colorSpread),
            location: locMan.fromId(e.locationId),
            heading: _getHeading(evtsShow, i),
            reloadAction: reloadAction,
          );
        },
      ),
    );
  }
}

class _EventListTile extends StatelessWidget {
  const _EventListTile(
    this.evt,
    this.typ,
    this.color, {
    this.heading,
    this.location,
    required this.reloadAction,
  });

  final EvtRec evt;
  final EvtTypeRec? typ;
  final LocationRec? location;
  final String? heading;
  final Color color;
  final VoidCallback reloadAction;

  @override
  Widget build(BuildContext context) {
    final dur = evt.duration;
    final durTxt = " (${Fmt.durationHmVerbose(dur)})";

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
                child: Text(
                  heading ?? "---",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
        ListTile(
          title: Text(
            "${typ?.name}$durTxt",
            style: TextStyle(color: color),
          ),
          subtitle: _makeSubtitle(),
          onTap: () {
            _openDetail(context);
          },
        ),
      ],
    );
  }

  Widget _makeSubtitle() {
    final (startText, endText) = Fmt.eventTimes(evt);
    final wdStart = Fmt.dayAbbr(evt.start?.asLocal);
    final wdEnd = (evt.end?.asLocal.day != evt.start?.asLocal.day) ? Fmt.dayAbbr(evt.end?.asLocal) : null;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: 4,
        children: [
          // Start & end
          Text(wdStart, style: TextStyle(color: Colors.blueGrey)),
          Text(startText),
          Text(" - "),
          if (wdEnd != null) Text(wdEnd, style: TextStyle(color: Colors.blueGrey)),
          Text(endText),
          // Location
          if (location != null)
            Text(
              "@${location?.name}",
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey),
            ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => EvtDetailScreen(evt))).then((_) {
      // When the detail view is popped, data might have changed
      reloadAction();
    });
  }
}
