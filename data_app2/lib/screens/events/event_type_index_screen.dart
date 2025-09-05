import 'package:data_app2/app_state.dart';
import 'package:data_app2/event_type_index_view_model.dart';
import 'package:data_app2/screens/events/event_type_detail_screen.dart';
import 'package:data_app2/screens/events/event_type_overview_screen.dart';
import 'package:data_app2/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventTypeIndexScreen extends StatelessWidget {
  const EventTypeIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EventTypeIndexViewModel>(
      create: (_) {
        final app = Provider.of<AppState>(context, listen: false);
        return EventTypeIndexViewModel(app)..load();
      },
      child: Builder(
        builder: (context) {
          return Consumer<EventTypeIndexViewModel>(
            builder: (context, vm, child) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Event types'),
                ),
                floatingActionButton: FloatingActionButton(
                  child: Icon(Icons.add),
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                      MaterialPageRoute(
                        builder: (context) => EventTypeDetailScreen(null),
                      ),
                    )
                        .then((_) {
                      // reload data
                      vm.load();
                    });
                  },
                ),
                body: Builder(
                  builder: (context) {
                    final evtFreqs = vm.evtFreqs?.entries.toList();

                    if (evtFreqs == null) {
                      return Center(child: Text("Loading..."));
                    }
                    if (evtFreqs.isEmpty) {
                      return Center(child: Text("No event types"));
                    }
                    final danglingTypeRefs = vm.danglingTypeRefs;
                    if (danglingTypeRefs.isNotEmpty) {
                      return Column(
                        children: [
                          DanglingTypeRefsWarningBox(danglingTypeRefs),
                          Expanded(child: EvtTypeList()),
                        ],
                      );
                    }
                    return EvtTypeList();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DanglingTypeRefsWarningBox extends StatelessWidget {
  final Iterable<int> danglingTypeRefs;

  const DanglingTypeRefsWarningBox(this.danglingTypeRefs, {super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.brown,
      padding: EdgeInsets.all(8),
      child: Column(
        spacing: 12,
        children: [
          Text(
            "We have dangling type references",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            danglingTypeRefs.toString(),
            style: TextStyle(fontFamily: "monospace"),
          ),
          Text("Try importing the correct types, or make new ones to override"),
        ],
      ),
    );
  }
}

class EvtTypeList extends StatelessWidget {
  const EvtTypeList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<EventTypeIndexViewModel>(context, listen: false);
    final evtTypes = vm.typesSorted;
    return ListView.builder(
      itemCount: evtTypes.length,
      itemBuilder: (context, index) {
        final typeRec = evtTypes[index];
        final count = vm.evtFreqs?[typeRec.id] ?? 0;

        return ListTile(
          title: Text(
            typeRec.name,
            style: TextStyle(color: typeRec.color.inContext(context)),
          ),
          subtitle: Text(
            count.toString(),
          ),
          onTap: () {
            final typeId = typeRec.id;
            if (typeId != null) {
              Navigator.of(context)
                  .push(
                MaterialPageRoute(
                  builder: (context) => EventTypeOverviewScreen(typeId),
                ),
              )
                  .then((_) {
                // reload data
                vm.load();
              });
            } else {
              simpleSnack(context, "error: cannot find type $typeId");
            }
          },
        );
      },
    );
  }
}
