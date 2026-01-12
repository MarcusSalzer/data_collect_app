import 'package:data_app2/app_state.dart';
import 'package:data_app2/dialogs/show_confirm_save_back_dialog.dart';
import 'package:data_app2/view_models/event_type_detail_view_model.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:data_app2/user_events.dart';
import 'package:data_app2/util.dart';
import 'package:data_app2/widgets/color_key_palette.dart';
import 'package:data_app2/widgets/confirm_dialog.dart';
import 'package:data_app2/widgets/two_columns.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventTypeDetailScreen extends StatelessWidget {
  final EvtTypeRec? type;

  const EventTypeDetailScreen(this.type, {super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EventTypeDetailViewModel>(
      create: (context) {
        final app = Provider.of<AppState>(context, listen: false);
        return EventTypeDetailViewModel(type, app);
      },
      child: Consumer<EventTypeDetailViewModel>(
        // prevent pop if has unsaved changes
        builder: (context, vm, child) => PopScope(
          canPop: !vm.isDirty,
          onPopInvokedWithResult: (didPop, Object? res) async {
            if (!didPop) {
              showConfirmSaveBackDialog<EvtTypeRec?>(
                context,
                saveAction: () async {
                  final errMsg = await vm.save();
                  if (context.mounted) {
                    if (errMsg != null) {
                      simpleSnack(context, errMsg, color: Colors.red);
                      return null;
                    } else {
                      simpleSnack(context, "Saved!");
                    }
                  }
                  return vm.typeEdit;
                },
              );
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text("${vm.typeEdit.name}${vm.isDirty ? " *" : ""}"),
              actions: [
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ConfirmDialog(
                        title: "Delete event type?",
                        action: () async {
                          final didDelete = await vm.delete();
                          if (context.mounted) {
                            if (didDelete) {
                              simpleSnack(
                                context,
                                "Deleted type ${vm.typeEdit.id}",
                              );
                            } else {
                              simpleSnack(
                                context,
                                "Failed to delete type",
                                color: Colors.red,
                              );
                            }
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    );
                  },
                  icon: Icon(Icons.delete_forever),
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TwoColumns(
                      rows: [
                        (
                          Text("Name"),
                          TextFormField(
                            onChanged: (v) => vm.updateName(v.trim()),
                            initialValue: vm.typeEdit.name,
                          ),
                        ),
                        (
                          Text("Color"),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ColorKeyPalette(
                                    selectedColorKey: vm.color,
                                    onColorSelected: (newCol) {
                                      vm.updateColor(newCol);
                                    },
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              vm.color.name.capitalized,
                              style: TextStyle(
                                color: vm.color.inContext(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                    if (vm.isDirty)
                      TextButton(
                        onPressed: () async {
                          final errMsg = await vm.save();
                          if (context.mounted) {
                            if (errMsg != null) {
                              simpleSnack(context, errMsg, color: Colors.red);
                            } else {
                              simpleSnack(context, "Saved!");
                              Navigator.of(context).pop(vm.typeEdit);
                            }
                          }
                        },
                        child: Text("Save & exit"),
                      ),
                    SizedBox(height: 32),
                    EventTypeDetailDisplay(vm.typeEdit),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EventTypeDetailDisplay extends StatelessWidget {
  final EvtTypeRec type;

  const EventTypeDetailDisplay(this.type, {super.key});

  // A helper method to create a row for a single data pair
  Widget _buildInfoRow(String title, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 0, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(title)),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontFamily: "monospace", color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subtitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(t, style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _subtitle("Details"),
        _buildInfoRow('Id', type.id.toString()),
        _buildInfoRow('Name', type.name),
        _buildInfoRow(
          'Color',
          type.color.toString(),
          color: type.color.inContext(context),
        ),
      ],
    );
  }
}
