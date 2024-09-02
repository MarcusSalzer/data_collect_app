import 'package:data_collector_app/utility/data_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SelectionArea(
                child: Text(
              dataSamp.timestamp.toString().split(".")[0],
              style: Theme.of(context).textTheme.bodySmall,     
            )),
          ),
          divider,
          ...dataFields,
          divider,
          IconButton(
            onPressed: () {
              Provider.of<DataModel>(context, listen: false)
                  .removeSample(dataSamp);
            },
            icon: const Icon(Icons.delete_forever),
          )
        ]),
      ),
    );
  }
}
