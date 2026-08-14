import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/location.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:flutter/material.dart';

class EvtSubTitle extends StatelessWidget {
  final EvtRec evt;
  final LocationRec? location;

  const EvtSubTitle(this.evt, this.location, {super.key});
  @override
  Widget build(BuildContext context) {
    final (startText, endText) = Fmt.eventTimes(evt);
    final wdStart = Fmt.dayAbbr(evt.start?.asLocal);
    final wdEnd = (evt.end?.asLocal.day != evt.start?.asLocal.day) ? Fmt.dayAbbr(evt.end?.asLocal) : null;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 4,
          children: [
            // Start & end
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 3,
              children: [
                Text(wdStart, style: TextStyle(color: Colors.blueGrey)),
                Text(startText),
                Text("-"),
                if (wdEnd != null) Text(wdEnd, style: TextStyle(color: Colors.blueGrey)),
                Text(endText),
              ],
            ),
            // Location
            if (location != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("\u{1F4CD}"), // Pin emoji
                  Text(
                    "${location?.name}",
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
