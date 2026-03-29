import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/view_models/evt_type_detail_vm.dart';
import 'package:data_app2/widgets/edit_scaffold.dart';
import 'package:data_app2/widgets/generic_autocomplete.dart';
import 'package:data_app2/widgets/two_columns.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventTypeDetailScreen extends StatelessWidget {
  final EvtTypeRec? stored;

  const EventTypeDetailScreen(this.stored, {super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EvtTypeDetailVm>(
      create: (context) {
        // Create VM and start loading "secondary" data
        final app = context.read<AppState>();
        return EvtTypeDetailVm(stored, app.db, app.evtTypeManager)..load();
      },
      child: Consumer<EvtTypeDetailVm>(
        // prevent pop if has unsaved changes
        builder: (context, vm, _) => EditScaffoldForVm<EvtTypeRec>(
          title: stored == null ? "New Type" : "Edit Type",
          body: Column(
            children: [
              EditInputs(vm: vm),
              SizedBox(height: 32),
              EventTypeDetailDisplay(vm.draft, vm.id),
            ],
          ),
          vm: vm,
        ),
      ),
    );
  }
}

class EditInputs extends StatelessWidget {
  const EditInputs({super.key, required this.vm});

  final EvtTypeDetailVm vm;

  @override
  Widget build(BuildContext context) {
    final loadedCategories = vm.categories;

    return TwoColumns(
      rows: [
        (Text("Name"), TextFormField(onChanged: vm.updateName, initialValue: vm.draft.name)),
        // (
        //   Text("Color"),
        //   ElevatedButton(
        //     onPressed: () {
        //       Navigator.of(context).push(
        //         MaterialPageRoute(
        //           builder: (context) => ColorKeyPalette(selectedColorKey: vm.color, onColorSelected: vm.updateColor),
        //         ),
        //       );
        //     },
        //     child: Text(
        //       vm.color.name.capitalized,
        //       style: TextStyle(color: vm.color.inContext(context), fontWeight: FontWeight.bold),
        //     ),
        //   ),
        // ),
        (
          Text("Category"),
          (loadedCategories == null)
              ? Text("Loading...")
              : GenericAutocomplete<EvtCatRec>(
                  options: loadedCategories,
                  initialValue: vm.currentCategory,
                  nameOf: (e) => e.name,
                  onSelected: (v) {
                    vm.updateCategory(v.id);
                  },
                  optionBuilder: (context, e) => ListTile(
                    leading: CircleAvatar(radius: 5, backgroundColor: e.color),
                    title: Text(e.name),
                  ),
                  searchMode: context.watch<AppState>().textSearchMode,
                ),
        ),
      ],
    );
  }
}

class EventTypeDetailDisplay extends StatelessWidget {
  final EvtTypeDraft type;
  final int? id;

  const EventTypeDetailDisplay(this.type, this.id, {super.key});

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
        _buildInfoRow('Id', id.toString()),
        _buildInfoRow('Name', type.name),
        _buildInfoRow('Category', type.categoryId.toString()),
        // TODO COLOR INFO (inlcuding compute info)
        // _buildInfoRow('Color', type.color.toString(), color: type.color.inContext(context)),
      ],
    );
  }
}
