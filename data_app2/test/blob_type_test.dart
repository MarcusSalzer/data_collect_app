import 'package:data_app2/data/user_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('null', () {
    expect(BlobFieldSpec(DInt(), nullable: false).isValid(null), isFalse);
    expect(BlobFieldSpec(DInt(), nullable: true).isValid(null), isTrue);
  });
  test('int', () {
    final f = BlobFieldSpec(DInt());
    expect(f.isValid(1), isTrue);
    expect(f.isValid("1"), isFalse);
  });
  test('double', () {
    final f = BlobFieldSpec(DDecimal());
    expect(f.isValid(1), isTrue);
    expect(f.isValid(1.1), isTrue);
    expect(f.isValid("1"), isFalse);
  });
  test('string', () {
    final f = BlobFieldSpec(DText());
    expect(f.isValid(1), isFalse);
    expect(f.isValid(1.1), isFalse);
    expect(f.isValid("1"), isTrue);
  });
  test('array', () {
    final f = BlobFieldSpec(DArray(BlobFieldSpec(DInt())));
    expect(f.isValid(1), isFalse);
    expect(f.isValid(1.1), isFalse);
    expect(f.isValid([1, 2, 3]), isTrue);
    expect(f.isValid([1, 2, null]), isFalse);
    expect(f.isValid(["1", "2", "3"]), isFalse);
  });
}
