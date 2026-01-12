import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/summary_with_period_aggs.dart';
import 'package:data_app2/screens/events/multi_summary_export_screen.dart';
import 'package:data_app2/user_events.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:data_app2/util/process_state.dart';
import 'package:data_app2/view_models/multi_evt_summary_vm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

/// a table with a row per period, and a column per aggregated type
// ignore: unused_element
class _SummaryTableVerticalOnly extends StatelessWidget {
  final double colWidth = 100;
  final SummaryWithPeriodAggs data;
  const _SummaryTableVerticalOnly(this.data);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(width: colWidth + 20, child: Text(data.f.name)),
            ...data.typeRecs.map(
              (t) => SizedBox(
                width: colWidth,
                child: Text(
                  t.name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: data.aggs.length,
            itemBuilder: (context, idx) {
              final a = data.aggs[idx];
              final tTxt = Fmt.date(a.dt);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: colWidth + 20, child: Text(tTxt)),
                  ...a.agg.map(
                    (d) => SizedBox(
                      width: colWidth,
                      child: Text(d.inMinutes.toString()),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _Grid extends TwoDimensionalScrollView {
  const _Grid({required super.delegate});

  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset verticalOffset,
    ViewportOffset horizontalOffset,
  ) {
    // TODO: implement buildViewport
    throw UnimplementedError();
  }
}

/// a table with a row per period, and a column per aggregated type
/// NOTE: only totals
class _SummaryTableTotals extends StatelessWidget {
  final double colWidth = 120;
  final SummaryWithPeriodAggs data;
  const _SummaryTableTotals(this.data);

  @override
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        spacing: 8,
        children: [
          Row(
            children: [
              SizedBox(
                width: colWidth,
                child: Text(
                  data.f.name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                width: colWidth,
                child: Text(
                  "Total",
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: data.aggs.length,
              itemBuilder: (context, idx) {
                final a = data.aggs[idx];
                final tTxt = Fmt.date(a.dt);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: colWidth, child: Text(tTxt)),
                      SizedBox(
                        width: colWidth,
                        child: Text(
                          Fmt.durationHmVerbose(a.total()),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MultiEvtTypeSummaryScreen extends StatelessWidget {
  final Iterable<int> typeIds;

  const MultiEvtTypeSummaryScreen({super.key, required this.typeIds});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MultiEvtSummaryVM(
        typeIds,
        Provider.of<AppState>(context, listen: false),
        // start loading data when created
      )..load(),
      child: Consumer<MultiEvtSummaryVM>(
        builder: (context, vm, child) {
          if (vm.state case Loading()) {
            return Scaffold(
              appBar: AppBar(title: Text("Summary")),
              body: Center(child: Text("Loading...")),
            );
          } else if (vm.state case Ready(:final data)) {
            return Scaffold(
              appBar: AppBar(
                title: Text("Summary"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => MultiSummaryExportScreen(data),
                        ),
                      );
                    },
                    child: Text("Export"),
                  ),
                ],
              ),

              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total ${data.nEvt} instances"),
                    Divider(),
                    // ----- List aggregated types -----
                    ConstrainedBox(
                      // prevent filling screen with this, leaving room for data table
                      constraints: BoxConstraints.loose(Size.fromHeight(200)),
                      child: SingleChildScrollView(
                        child: TypeRecShortList(typeRecs: data.typeRecs),
                      ),
                    ),
                    Divider(),
                    RadioGroup<GroupFreq>(
                      groupValue: vm.freq,
                      onChanged: vm.setFreq,
                      child: Wrap(
                        children: GroupFreq.values
                            .map(
                              (f) => Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Radio(value: f),
                                    Text(f.name),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    Divider(),
                    // ----- full data list -----
                    _SummaryTableTotals(data),
                    // Expanded(child: FrozenGrid(rows: 100, cols: 10)),
                  ],
                ),
              ),
            );
          }
          return Center(child: Text("Unknown error"));
        },
      ),
    );
  }
}

/// List showing a few typerecs and their color
class TypeRecShortList extends StatelessWidget {
  const TypeRecShortList({super.key, required this.typeRecs});

  final List<EvtTypeRec> typeRecs;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: typeRecs
          .map(
            (t) => Row(
              spacing: 8,
              children: [
                CircleAvatar(
                  backgroundColor: t.color.inContext(context),
                  radius: 5,
                ),
                Text(t.name),
              ],
            ),
          )
          .toList(),
    );
  }
}
