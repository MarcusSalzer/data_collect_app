class CsvFormatError implements Exception {
  final int row;

  String msg;
  CsvFormatError({required this.row, required this.msg});

  @override
  String toString() {
    return "CSV Format error: $msg (at row $row)";
  }
}
