import 'package:data_app2/data/user_schema.dart';
import 'package:flutter/material.dart';

class EvtBlobSummaryIndicator extends StatelessWidget {
  final Iterable<UserBlobRec> _blobs;

  const EvtBlobSummaryIndicator(this._blobs, {super.key});
  @override
  Widget build(BuildContext context) {
    return Text(_blobs.map((b) => "*${b.schemaId}").join(", "));
  }
}
