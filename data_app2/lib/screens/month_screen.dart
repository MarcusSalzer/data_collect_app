import 'package:data_app2/extensions.dart';
import 'package:flutter/material.dart';

class MonthScreen extends StatelessWidget {
  const MonthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final days = get_days(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: Text("Calendar"),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.keyboard_double_arrow_left),
              ),
              Center(child: Text(DateTime.now().month.toString())),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.keyboard_double_arrow_right),
              ),
            ],
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7),
              itemCount: 35,
              itemBuilder: (context, index) {
                return Container(
                    padding: EdgeInsets.all(4.0),
                    child: Center(child: Text(days[index].toString())));
              },
            ),
          ),
        ],
      ),
    );
  }

  // TODO move to datetime util file
  get_days(DateTime month) {
    final offset = -month.monthFirstWeekday;
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    return List.generate(35, (i) => 1 + (i + offset) % days);
  }
}
