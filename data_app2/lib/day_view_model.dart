import 'package:data_app2/db_service.dart';
import 'package:flutter/material.dart';

class DayViewModel extends ChangeNotifier {
  List<Event> _events = [];

  List<MapEntry<String, Duration>> tpe = [];
  List<Event> get events => _events;

  DayViewModel({List<Event>? events}) {
    _events = events ?? [];
    // tpe = timePerEvent(_events, limit: 16);
  }
}
