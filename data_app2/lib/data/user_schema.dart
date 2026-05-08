import 'package:data_app2/contracts/data.dart';
import 'package:data_app2/users_schema.dart';

class UserEnumRec implements Identifiable {
  const UserEnumRec(this.id, {required this.name});
  @override
  final int id;
  final String name;
  @override
  UserEnumDraft toDraft() => UserEnumDraft(name);
}

class UserEnumDraft implements Draft<UserEnumRec> {
  UserEnumDraft(this.name);
  String name;
  @override
  UserEnumRec toRec(int id) => UserEnumRec(id, name: name);
}

class UserEnumValueRec implements Identifiable {
  const UserEnumValueRec(this.id, {required this.enumId, required this.name});
  @override
  final int id;
  final int enumId;
  final String name;
  @override
  UserEnumValueDraft toDraft() => UserEnumValueDraft(enumId, name);
}

class UserEnumValueDraft implements Draft<UserEnumValueRec> {
  UserEnumValueDraft(this.enumId, this.name);
  int enumId;
  String name;
  @override
  UserEnumValueRec toRec(int id) => UserEnumValueRec(id, enumId: enumId, name: name);
}

class UserColumnRec implements Identifiable {
  const UserColumnRec(this.id, {required this.name, required this.dtype, this.enumId});
  @override
  final int id;
  final String name;
  final DType dtype;
  final int? enumId;
  @override
  UserColumnDraft toDraft() => UserColumnDraft(name, dtype, enumId: enumId);
}

class UserColumnDraft implements Draft<UserColumnRec> {
  UserColumnDraft(this.name, this.dtype, {this.enumId});
  String name;
  DType dtype;
  int? enumId;
  @override
  UserColumnRec toRec(int id) => UserColumnRec(id, name: name, dtype: dtype, enumId: enumId);
}

class UserTableRec implements Identifiable {
  const UserTableRec(this.id, {required this.name, required this.columnIds});
  @override
  final int id;
  final String name;
  final List<int> columnIds;
  @override
  UserTableDraft toDraft() => UserTableDraft(name, List.of(columnIds));
}

class UserTableDraft implements Draft<UserTableRec> {
  UserTableDraft(this.name, this.columnIds);
  String name;
  List<int> columnIds;
  @override
  UserTableRec toRec(int id) => UserTableRec(id, name: name, columnIds: columnIds);
}

class UserRowRec implements Identifiable {
  const UserRowRec(
    this.id, {
    required this.tableId,
    this.eventId,
    this.timestampMillis,
    required this.values,
  });
  @override
  final int id;
  final int tableId;
  final int? eventId;
  final int? timestampMillis;
  final List<int?> values; // parallel to table.columnIds
  @override
  UserRowDraft toDraft() => UserRowDraft(
    tableId,
    eventId: eventId,
    timestampMillis: timestampMillis,
    values: List.of(values),
  );
}

class UserRowDraft implements Draft<UserRowRec> {
  UserRowDraft(this.tableId, {this.eventId, this.timestampMillis, this.values = const []});
  int tableId;
  int? eventId;
  int? timestampMillis;
  List<int?> values;
  @override
  UserRowRec toRec(int id) => UserRowRec(
    id,
    tableId: tableId,
    eventId: eventId,
    timestampMillis: timestampMillis,
    values: values,
  );
}
