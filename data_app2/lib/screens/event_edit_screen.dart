import 'package:data_app2/db_service.dart';
import 'package:data_app2/event_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EventEditScreen extends StatelessWidget {
  final Event _evt;
  const EventEditScreen(this._evt, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit event"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: EventEditForm(_evt),
      ),
    );
  }
}

class EventEditForm extends StatefulWidget {
  final Event _evt;
  const EventEditForm(this._evt, {super.key});

  @override
  State<EventEditForm> createState() => _EventEditFormState();
}

class _EventEditFormState extends State<EventEditForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameTec = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final evt = widget._evt;
    final s = evt.start;
    final e = evt.end;
    final sdTxt = s != null ? DateFormat("yy-MM-dd").format(s) : "__-__-__";
    final stTxt = s != null ? DateFormat("HH:mm").format(s) : "__:__";
    final edTxt = e != null ? DateFormat("yy-MM-dd").format(e) : "__-__-__";
    final etTxt = e != null ? DateFormat("HH:mm").format(e) : "__:__";

    final evm = Provider.of<EventModel>(context, listen: false);

    return Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text("Name")),
                Expanded(
                  flex: 4,
                  child: TextFormField(
                    initialValue: evt.name,
                  ),
                )
              ],
            ),
            // EDIT START
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(child: Text("Start")),
                  Expanded(
                    child: TextButton(
                        onPressed: () async {
                          final dt = await showDatePicker(
                            context: context,
                            firstDate: DateTime(1970),
                            lastDate: DateTime(2222),
                          );
                          if (dt != null) {
                            setState(() {
                              evt.start = evt.start?.copyWith(
                                  year: dt.year, month: dt.month, day: dt.day);
                              // save updated event
                              evm.saveEvent(evt);
                            });
                          }
                        },
                        child: Text(sdTxt)),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final t = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(
                                evt.start ?? DateTime.now()));
                        if (t != null) {
                          setState(() {
                            evt.start = evt.start?.copyWith(
                              hour: t.hour,
                              minute: t.minute,
                            );
                            // save updated event
                            evm.saveEvent(evt);
                          });
                        } //
                      },
                      child: Text(stTxt),
                    ),
                  ),
                ],
              ),
            ),
            // EDIT END
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(child: Text("End")),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final dt = await showDatePicker(
                          context: context,
                          firstDate: DateTime(1970),
                          lastDate: DateTime(2222),
                        );
                        if (dt != null) {
                          setState(() {
                            evt.end = evt.end?.copyWith(
                              year: dt.year,
                              month: dt.month,
                              day: dt.day,
                            );
                            // save updated event
                            evm.saveEvent(evt);
                          });
                        }
                      },
                      child: Text(edTxt),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                        onPressed: () async {
                          final t = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(
                                  evt.end ?? DateTime.now()));
                          if (t != null) {
                            setState(() {
                              evt.end = evt.end
                                  ?.copyWith(hour: t.hour, minute: t.minute);
                              // save updated event
                              evm.saveEvent(evt);
                            });
                          } //
                        },
                        child: Text(etTxt)),
                  ),
                ],
              ),
            ),
          ],
        ));
  }

  @override
  void dispose() {
    _nameTec.dispose();
    super.dispose();
  }
}
