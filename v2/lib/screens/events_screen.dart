// ignore_for_file: avoid_print

import 'package:datacollectv2/app_state.dart';
import 'package:datacollectv2/event_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text('Events')),
      body: ChangeNotifierProvider<EventModel>(
        create: (_) => EventModel(appState.db),
        child: Column(
          children: [
            Expanded(child: EventAddWidget()),
            Expanded(child: EventHistoryDisplay()),
          ],
        ),
      ),
    );
  }
}

class EventHistoryDisplay extends StatelessWidget {
  const EventHistoryDisplay({super.key});
  final int n = 10;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "History",
          style: TextStyle(fontSize: 20),
        ),
        Expanded(
          child: Consumer<EventModel>(
            builder: (context, evtModel, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(evtModel.evtCount != null
                      ? "has ${evtModel.evtCount} events"
                      : "loading..."),
                  Expanded(
                    child: ListView.builder(
                        itemCount: evtModel.events.length,
                        itemBuilder: (context, i) {
                          final evt = evtModel.events[i];
                          final start = evt.start;
                          final end = evt.end;
                          var subt =
                              '${start?.hour ?? "__"}:${start?.minute ?? "__"} - ${end?.hour ?? "__"}:${end?.minute ?? "__"}';
                          return ListTile(
                            title: Text(evt.name),
                            subtitle: subt.isNotEmpty ? Text(subt) : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    print("todo");
                                  },
                                  icon: Icon(Icons.edit),
                                ),
                                SizedBox(width: 10),
                                IconButton(
                                  onPressed: () {
                                    print("todo");
                                  },
                                  icon: Icon(Icons.delete_forever),
                                ),
                              ],
                            ),
                          );
                        }),
                  )
                ],
              );
            },
          ),
        )
      ],
    );
  }
}

class EventAddWidget extends StatefulWidget {
  const EventAddWidget({super.key});

  @override
  State<EventAddWidget> createState() => _EventAddWidgetState();
}

class _EventAddWidgetState extends State<EventAddWidget> {
  final _formKey = GlobalKey<FormState>();

  final _nameTec = TextEditingController();

  DateTime? newStart;

  @override
  Widget build(BuildContext context) {
    final evtModelprov = Provider.of<EventModel>(context, listen: false);
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 30),
        child: Column(
          children: [
            // previous event confirm:
            Consumer<EventModel>(builder: (context, evm, child) {
              // if there is a previous event: display it and allow stopping
              if (evm.events.isNotEmpty && evm.events.first.end == null) {
                final evt = evm.events.first;
                return SizedBox(
                  height: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                          width: 100,
                          child:
                              Text("${evt.start?.hour}:${evt.start?.minute}")),
                      Expanded(child: Text(evt.name)),
                      TextButton.icon(
                        onPressed: () {
                          evt.end = DateTime.now();
                          evm.saveEvent(evt);
                        },
                        label: Text("stop"),
                        icon: Icon(Icons.stop),
                      )
                    ],
                  ),
                );
              } else {
                return SizedBox(height: 100);
              }
            }),

            SizedBox(height: 50),
            // add new event:
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: TextButton(
                      onPressed: () {
                        print("todo: time picker");
                      },
                      child: Text("Now")),
                ),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(hintText: "start"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "required";
                      } else {
                        return null;
                      }
                    },
                    controller: _nameTec,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // start event at picked time (or now)
                        evtModelprov.addEvent(_nameTec.text,
                            start: newStart ?? DateTime.now());
                        print("added start!");
                        _nameTec.clear();
                      }
                    },
                    label: Text("Add"),
                    icon: Icon(Icons.add),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameTec.dispose();
    super.dispose();
  }
}
