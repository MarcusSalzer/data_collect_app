class CsvFormatError implements Exception {
  final int row;

  String message;
  CsvFormatError({required this.row, required this.message});

  @override
  String toString() {
    return "CSV Format error: $message (at row $row)";
  }
}
