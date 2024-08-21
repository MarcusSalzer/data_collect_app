// import 'package:flutter/material.dart';

// Future<DateTime?> showDateTimePicker({
//   required BuildContext context,
//   DateTime? initialDate,
// }) async {
//   initialDate ??= DateTime.now();

//   final DateTime? date = await showDatePicker(
//     context: context,
//     initialDate: initialDate,
//     firstDate: DateTime(-1000),
//     lastDate: DateTime(10000),
//   );

//   if (date == null) return null;

//   if (!context.mounted) return date;

//   final TimeOfDay? selectedTime = await showTimePicker(
//     context: context,
//     initialTime: TimeOfDay.fromDateTime(initialDate),
//   );

//   return selectedTime == null
//       ? date
//       : DateTime(
//           date.year,
//           date.month,
//           date.day,
//           selectedTime.hour,
//           selectedTime.minute,
//         );
// }
