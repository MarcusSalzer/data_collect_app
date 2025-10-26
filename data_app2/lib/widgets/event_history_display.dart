import 'package:data_app2/app_state.dart' show AppState;
import 'package:data_app2/enums.dart';
import 'package:data_app2/extensions.dart';
import 'package:data_app2/fmt.dart';
import 'package:data_app2/screens/events/event_detail_screen.dart';
import 'package:data_app2/user_events.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventHistoryDisplay extends StatelessWidget {
  final List<EvtRec> evts;
  final GroupFreq? headingMode;
  final bool isScrollable;
  final Function reloadAction;

  final bool reverse;

  const EventHistoryDisplay(
    this.evts, {
    this.headingMode,
    required this.isScrollable,
    required this.reloadAction,
    this.reverse = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: ListView.builder(
        itemCount: evts.length,
        reverse: reverse,
        itemBuilder: (context, i) {
          return EventListTile(
            evt: evts[i],
            heading: _getHeading(i),
            reloadAction: reloadAction,
          );
        },
        shrinkWrap: !isScrollable,
        physics: isScrollable
            ? const AlwaysScrollableScrollPhysics() // Allows scrolling
            : const NeverScrollableScrollPhysics(), // Disables its own scrolling
      ),
    );
  }

  String? _getHeading(int i) {
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
        case GroupFreq.week:
          doHeading = cur?.startOfweek != pre?.startOfweek;
        case GroupFreq.month:
          doHeading = cur?.startOfMonth != pre?.startOfMonth;
        case null:
          return null;
      }
    }

    return doHeading
        ? Fmt.verboseDate(evts[i].start?.asLocal, f: headingMode)
        : null;
  }
}

class EventListTile extends StatelessWidget {
  const EventListTile({
    super.key,
    required this.evt,
    this.heading,
    required this.reloadAction,
  });

  final EvtRec evt;
  final String? heading;
  final Function reloadAction;

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context, listen: false);
    final (startText, endText) = Fmt.eventTimes(evt);
    final wdStart = Fmt.dayAbbr(evt.start?.asLocal);
    final wdEnd = (evt.end?.asLocal.day != evt.start?.asLocal.day)
        ? Fmt.dayAbbr(evt.end?.asLocal)
        : null;

    final dur = evt.duration;
    final durTxt = " (${Fmt.durationHM(dur)})";
    final typeRec = app.evtTypeRepo.resolveById(evt.typeId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (heading != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.blueGrey))),
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
            "${typeRec?.name}$durTxt",
            style: TextStyle(color: typeRec?.color.inContext(context)),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  wdStart,
                  style: TextStyle(color: Colors.blueGrey),
                ),
                Text(
                  startText,
                ),
                Text(" - "),
                if (wdEnd != null)
                  Text(
                    wdEnd,
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                Text(
                  endText,
                )
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
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(evt),
      ),
    )
        .then(
      (_) {
        // When the detail view is popped, data might have changed
        reloadAction();
      },
    );
  }
}
