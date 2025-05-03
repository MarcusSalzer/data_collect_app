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
                    final (startTxt, _) = eventTimeFmt(evt);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(startTxt),
                        ),
                        Expanded(child: Text(evt.name)),
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
    return Container(
      padding: EdgeInsets.all(8),
      decoration: ShapeDecoration(
        color: thm.colorScheme.secondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Quick start",
                  style: TextStyle(fontSize: 25),
                ),
                IconButton(
                  onPressed: () {
                    Provider.of<EventModel>(context, listen: false)
                        .refreshCounts();
                  },
                  icon: Icon(Icons.refresh),
                )
              ],
            ),
          ),
          Consumer<EventModel>(
            builder: (context, evm, child) {
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: evm
                    .eventSuggestions()
                    .map(
                      (s) => ActionChip(
                        label: Text(s),
                        onPressed: () {
                          // add event
                          evm.addEvent(s, start: DateTime.now());
                        },
                      ),
                    )
                    .toList(),
              );
            },
          )
        ],
      ),
    );
  }
}

// Future<DateTime?> showCustomDateTimePicker(BuildContext context) async {
//   DateTime selectedDate = DateTime.now();
//   TimeOfDay selectedTime = TimeOfDay.now();

//   return await showModalBottomSheet<DateTime>(
//     context: context,
//     isScrollControlled: true,
//     builder: (context) {
//       return StatefulBuilder(
//         builder: (context, setState) {
//           bool is24HourFormat = MediaQuery.of(context).alwaysUse24HourFormat;
//           int hour = selectedTime.hourOfPeriod; // 12-hour format hour
//           int minute = selectedTime.minute;
//           bool isPM = selectedTime.period == DayPeriod.pm;

//           return Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text("Select Date & Time",
//                     style:
//                         TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

//                 // Date Picker
//                 CalendarDatePicker(
//                   initialDate: selectedDate,
//                   firstDate: DateTime(2000),
//                   lastDate: DateTime(2100),
//                   onDateChanged: (date) {
//                     setState(() => selectedDate = date);
//                   },
//                 ),

//                 SizedBox(height: 16),

//                 // Time Picker Section
//                 Text("Select Time",
//                     style:
//                         TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),

//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     // Hour Picker
//                     NumberPicker(
//                       minValue: is24HourFormat ? 0 : 1,
//                       maxValue: is24HourFormat ? 23 : 12,
//                       value: is24HourFormat ? selectedTime.hour : hour,
//                       zeroPad: true,
//                       onChanged: (value) {
//                         setState(() {
//                           if (is24HourFormat) {
//                             selectedTime = TimeOfDay(
//                                 hour: value, minute: selectedTime.minute);
//                           } else {
//                             hour = value;
//                             selectedTime = TimeOfDay(
//                                 hour: hour + (isPM ? 12 : 0),
//                                 minute: selectedTime.minute);
//                           }
//                         });
//                       },
//                     ),
//                     Text(":", style: TextStyle(fontSize: 24)),

//                     // Minute Picker
//                     NumberPicker(
//                       minValue: 0,
//                       maxValue: 59,
//                       value: minute,
//                       zeroPad: true,
//                       onChanged: (value) {
//                         setState(() {
//                           minute = value;
//                           selectedTime = TimeOfDay(
//                               hour: selectedTime.hour, minute: minute);
//                         });
//                       },
//                     ),

//                     // AM/PM Toggle (only for 12-hour format)
//                     if (!is24HourFormat) ...[
//                       SizedBox(width: 16),
//                       ToggleButtons(
//                         isSelected: [!isPM, isPM],
//                         onPressed: (index) {
//                           setState(() {
//                             isPM = index == 1;
//                             selectedTime = TimeOfDay(
//                                 hour: hour + (isPM ? 12 : 0),
//                                 minute: selectedTime.minute);
//                           });
//                         },
//                         children: [Text("AM"), Text("PM")],
//                       ),
//                     ],
//                   ],
//                 ),

//                 SizedBox(height: 16),
//                 TextButton(
//                     onPressed: () {
//                       Navigator.pop(
//                         context,
//                       );
//                     },
//                     child: Text("Cancel")),

//                 // Confirm Button
//                 ElevatedButton(
//                   onPressed: () {
//                     Navigator.pop(
//                       context,
//                       DateTime(
//                         selectedDate.year,
//                         selectedDate.month,
//                         selectedDate.day,
//                         selectedTime.hour,
//                         selectedTime.minute,
//                       ),
//                     );
//                   },
//                   child: Text("Confirm"),
//                 ),
//               ],
//             ),
//           );
//         },
//       );
//     },
//   );
// }
