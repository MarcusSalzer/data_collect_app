import 'package:data_collector_app/data_util.dart';
import 'package:flutter/material.dart';

class HistoryListTile extends StatelessWidget {
  final DataSample dataSamp;

  const HistoryListTile({super.key, required this.dataSamp});

  final VerticalDivider divider = const VerticalDivider(
    width: 3,
    thickness: 1,
    indent: 1,
    endIndent: 1,
    color: Colors.grey,
  );

  @override
  Widget build(BuildContext context) {
    final dataFields = dataSamp.data.map((e) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: SelectionArea(child: Text(e.toString())),
        ),
      );
    }).toList();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: IntrinsicHeight(
        child: Row(children: [
          SizedBox(
            width: 200,
            child: SelectionArea(
                child: Text(dataSamp.timestamp.toString().split(".")[0])),
          ),
          divider,
          ...dataFields,
          divider,
          SizedBox(
            width: 120,
            child: IconButton(
              onPressed: () {
                print("TODO");
                throw UnimplementedError("TODO");
                // Provider.of<DataModel>(context, listen: false)
                //     .removeSample(dataSamp);
              },
              icon: const Icon(Icons.delete_forever),
            ),
          )
        ]),
      ),
    );
  }
}
