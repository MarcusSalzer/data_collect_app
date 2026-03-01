/// Convenience superclass for comparable objects
/// Note: for objects with final fields
/// Note: the fields themselves need to be comparable
abstract class ValueObject {
  const ValueObject();

  /// Subclass needs to declare its props
  List<Object?> get props;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other.runtimeType == runtimeType && other is ValueObject && _equals(props, other.props);

  @override
  int get hashCode => Object.hashAll(props);

  /// Compare all properties
  bool _equals(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
