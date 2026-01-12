// import 'package:data_app2/day_view_model.dart';
// import 'package:data_app2/db_service.dart';
// import 'package:data_app2/fmt.dart';
// import 'package:data_app2/plots.dart';
// import 'package:data_app2/widgets/events_summary.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class DayScreenOld extends StatefulWidget {
//   final DateTime dt;

//   final List<Event>? events;
//   const DayScreenOld(this.dt, {super.key, this.events});

//   @override
//   State<DayScreenOld> createState() => _DayScreenOldState();
// }

// class _DayScreenOldState extends State<DayScreenOld> {
//   late DateTime dt;
//   @override
//   void initState() {
//     dt = widget.dt;
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => DayViewModel(events: widget.events),
//       child: Scaffold(
//         appBar: AppBar(title: Text(Fmt.verboseDate(dt))),
//         body: Consumer<DayViewModel>(
//           builder: (context, value, child) {
//             if (value.events.isEmpty) {
//               return Center(child: Text("No events"));
//             }
//             return Column(
//               mainAxisSize: MainAxisSize.max,
//               children: [
//                 EventsSummary(
//                   title: Fmt.verboseDate(dt),
//                   tpe: value.tpe,
//                   colors: Colors.primaries,
//                 ),
//                 Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: EventPieChart(
//                       timings: value.tpe,
//                       colors: Colors.primaries,
//                       nTitles: 8,
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
