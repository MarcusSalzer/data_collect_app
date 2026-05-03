import 'package:data_app2/data/location.dart';
import 'package:data_app2/location_manager.dart';
import 'package:data_app2/repos/location_repo.dart';
import 'package:data_app2/view_models/location_edit_vm.dart';
import 'package:data_app2/widgets/edit_scaffold.dart';
import 'package:flutter/material.dart';

class LocationEditScreen extends StatefulWidget {
  const LocationEditScreen({super.key, this.existing, required this.repo, required this.manager});

  final LocationRec? existing;
  final LocationRepo repo;
  final LocationManager manager;

  @override
  State<LocationEditScreen> createState() => _LocationEditScreenState();
}

class _LocationEditScreenState extends State<LocationEditScreen> {
  late final LocationEditVm _vm;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _coordCtrl;

  @override
  void initState() {
    super.initState();
    _vm = LocationEditVm(existing: widget.existing, repo: widget.repo, manager: widget.manager);
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _coordCtrl = TextEditingController(
      text: widget.existing != null ? '${widget.existing!.lat}, ${widget.existing!.lng}' : '',
    );
    // prime the parser if editing an existing record
    if (widget.existing != null) {
      _vm.setCoordRaw(_coordCtrl.text);
    }
  }

  @override
  void dispose() {
    _vm.dispose();
    _nameCtrl.dispose();
    _coordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) => EditScaffoldForVm(
        title: widget.existing == null ? 'New location' : 'Edit location',
        vm: _vm,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: _vm.setName,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _coordCtrl,
              decoration: InputDecoration(
                labelText: 'Coordinates',
                hintText: '55.7047, 13.1910',
                helperText: 'Paste decimal degrees, DMS...',
                errorText: _vm.coordError,
                suffixIcon: _coordCtrl.text.isNotEmpty
                    ? Icon(
                        _vm.coordError == null ? Icons.check_circle : Icons.error,
                        color: _vm.coordError == null ? Colors.green : Colors.red,
                      )
                    : null,
              ),
              onChanged: _vm.setCoordRaw,
            ),
            if (_vm.coordError == null && _coordCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 24),
              _MiniMap(lat: _vm.draft.lat, lng: _vm.draft.lng),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.lat, required this.lng});
  final double lat;
  final double lng;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: Text('📍 $lat, $lng')),
    );
  }
}
