class DbRefExistsError implements Exception {
  final int id;

  DbRefExistsError(this.id);

  @override
  String toString() {
    return "Item $id has references.";
  }
}
