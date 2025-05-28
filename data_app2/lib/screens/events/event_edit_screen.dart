import 'package:data_app2/db_service.dart';
import 'package:data_app2/event_model.dart';
import 'package:data_app2/fmt.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventEditScreen extends StatefulWidget {
  final Event _evt;
  const EventEditScreen(this._evt, {super.key});

  @override
  State<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends State<EventEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final Event evt;
  late final EventModel evm;
  late final TextEditingController nameTec;

  @override
  void initState() {
    evm = Provider.of<EventModel>(context, listen: false);
    evt = widget._evt;
    nameTec = TextEditingController(text: evt.name);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final evt = widget._evt;
    final (sdTxt, stTxt) = dateTimeFmt(evt.start);
    final (edTxt, etTxt) = dateTimeFmt(evt.end);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () {
          save();
        }),
        title: const Text("Edit event"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: const Text("Name")),
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: nameTec,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "please enter a name";
                        }
                        return null;
                      },
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
                                    year: dt.year,
                                    month: dt.month,
                                    day: dt.day);
                                // save updated event
                                evm.putEvent(evt);
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
                              evt.start ?? DateTime.now(),
                            ),
                          );
                          if (t != null) {
                            setState(() {
                              evt.start = evt.start?.copyWith(
                                hour: t.hour,
                                minute: t.minute,
                              );
                              // save updated event
                              evm.putEvent(evt);
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
                              evt.end = DateTime.now().copyWith(
                                year: dt.year,
                                month: dt.month,
                                day: dt.day,
                              );
                              // save updated event
                              evm.putEvent(evt);
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
                                evt.end = DateTime.now()
                                    .copyWith(hour: t.hour, minute: t.minute);
                                // save updated event
                                evm.putEvent(evt);
                              });
                            } //
                          },
                          child: Text(etTxt)),
                    ),
                  ],
                ),
              ),
              MenuAnchor(
                builder: (context, controller, child) => IconButton(
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  icon: Icon(Icons.delete_forever),
                ),
                menuChildren: [
                  MenuItemButton(
                    onPressed: () {
                      evm.delete(evt);
                      Navigator.pop(context);
                    },
                    child: Text('Delete'),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> save() async {
    final state = _formKey.currentState;
    if (state == null) return;

    if (state.validate()) {
      setState(() {
        evt.name = nameTec.text;
        // save updated event
        evm.putEvent(evt);
      });
      // then leave page
      Navigator.maybePop(context);
    }
  }

  @override
  void dispose() {
    nameTec.dispose();
    super.dispose();
  }
}
