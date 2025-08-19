import 'package:data_app2/app_state.dart';
import 'package:data_app2/event_model.dart';
import 'package:data_app2/fmt.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventCreateMenu extends StatefulWidget {
  const EventCreateMenu({super.key});

  @override
  State<EventCreateMenu> createState() => _EventCreateMenuState();
}

class _EventCreateMenuState extends State<EventCreateMenu> {
  final _formKey = GlobalKey<FormState>();
  final _nameTec = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final evtModelprov = Provider.of<EventModel>(context, listen: false);
    final app = Provider.of<AppState>(context, listen: false);
    return Consumer<EventModel>(
      builder: (context, evm, child) {
        if (evm.isLoading) {
          return Center(child: Text("Loading events..."));
        }
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Builder(builder: (context) {
                  // if there is a previous event: display it and allow stopping
                  if (evm.events.isNotEmpty && evm.events.first.end == null) {
                    final evt = evm.events.first;
                    final (startTxt, _) = Fmt.eventTimes(evt);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(startTxt),
                        ),
                        Expanded(
                            child:
                                Text(app.eventName(evt.typeId) ?? "unknown")),
                        TextButton.icon(
                          onPressed: () {
                            evt.end = DateTime.now();
                            evm.putEvent(evt);
                          },
                          label: Text("stop"),
                          icon: Icon(Icons.stop),
                        )
                      ],
                    );
                  } else {
                    return Text("No current event");
                  }
                }),

                SizedBox(height: 10),
                // add new event:
                Row(
                  children: [
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
                    TextButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // start event at picked time (or now)
                          evtModelprov.addEvent(
                            _nameTec.text,
                            start: DateTime.now(),
                          );
                          _nameTec.clear();
                        }
                      },
                      label: Text("start"),
                      icon: Icon(Icons.add),
                    )
                  ],
                ),
                SizedBox(height: 20),
                CommonEventsSuggest(),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nameTec.dispose();
    super.dispose();
  }
}

class CommonEventsSuggest extends StatelessWidget {
  const CommonEventsSuggest({super.key});

  @override
  Widget build(BuildContext context) {
    final thm = Theme.of(context);
    final app = Provider.of<AppState>(context, listen: false);

    return Container(
      padding: EdgeInsets.all(4),
      decoration: ShapeDecoration(
        color: thm.colorScheme.secondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
      ),
      child: Consumer<EventModel>(
        builder: (context, evm, child) {
          return Wrap(
            spacing: 6,
            runSpacing: 6,
            children: evm.eventSuggestions().map(
              (s) {
                final name = app.eventName(s) ?? "unknown";
                return ActionChip(
                  label: Text(name),
                  onPressed: () {
                    // add event
                    evm.addEvent(name, start: DateTime.now());
                  },
                );
              },
            ).toList(),
          );
        },
      ),
    );
  }
}
