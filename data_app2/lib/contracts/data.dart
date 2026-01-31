/// Represents something stored in database
// abstract class DataRec {
//   final int id;
//   DataRec(this.id);
//   DataDraft toDraft();
// }

// /// Represent a non-persisted item
// abstract interface class DataDraft<R extends DataRec> {
//   R toRec(int id);
//   DataDraft<R> copyWith();
// }

abstract interface class Identifiable {
  int get id;
  Draft toDraft();
}

/// Contains all the data.
/// The corresponding [R] is a persisted version, with an id.
abstract class Draft<R extends Identifiable> {
  const Draft();
  const Draft.def();
  R toRec(int id);
}
