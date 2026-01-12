import 'package:data_app2/app_state.dart';
import 'package:data_app2/view_models/event_create_vm.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:data_app2/local_datetime.dart';
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
    final evtModelprov = Provider.of<EventCreateViewVM>(context, listen: false);
    final app = Provider.of<AppState>(context, listen: false);
    return Consumer<EventCreateViewVM>(
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
                Builder(
                  builder: (context) {
                    // if there is a previous event: display it and allow stopping
                    if (evm.events.isNotEmpty && evm.events.last.end == null) {
                      final evt = evm.events.last;
                      final (startTxt, _) = Fmt.eventTimes(evt);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SizedBox(width: 100, child: Text(startTxt)),
                          Expanded(
                            child: Text(
                              app.evtTypeManager
                                      .resolveById(evt.typeId)
                                      ?.name ??
                                  "unknown",
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              evt.end = LocalDateTime.now();
                              evm.updateEvent(evt);
                            },
                            label: Text("stop"),
                            icon: Icon(Icons.stop),
                          ),
                        ],
                      );
                    } else {
                      return Text("No current event");
                    }
                  },
                ),

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
                          evtModelprov.addEventByName(
                            // trim input
                            _nameTec.text.trim(),
                            start: DateTime.now(),
                          );
                          _nameTec.clear();
                        }
                      },
                      label: Text("start"),
                      icon: Icon(Icons.add),
                    ),
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
    // final thm = Theme.of(context);
    final app = Provider.of<AppState>(context, listen: false);

    return Consumer<EventCreateViewVM>(
      builder: (context, evm, child) {
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: evm.eventSuggestions().map((s) {
            final et = app.evtTypeManager.resolveById(s);
            final name = et?.name ?? "unknown";
            return ActionChip(
              label: Text(name),
              onPressed: () {
                // add event
                evm.addEventByName(name, start: DateTime.now());
              },
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: et?.color.inContext(context) ?? Colors.grey,
                ),
                borderRadius: BorderRadiusGeometry.all(Radius.circular(6)),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
