abstract interface class Identifiable {
  int get id;
  Draft toDraft();
}

/// Contains all the data.
/// The corresponding [R] is a persisted version, with an id.
abstract class Draft<R extends Identifiable> {
  const Draft();
  R toRec(int id);
}
