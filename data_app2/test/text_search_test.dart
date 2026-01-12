import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/text_search.dart';
import 'package:test/test.dart';

void main() {
  const opts = ["hell", "hello world", "world hello", "shello"];

  /// for concise tests
  searchOpts(String q, TextSearchMode mode, {List<String> opts = opts}) {
    return textSearchFilter(q, opts, mode, (s) => s).toList();
  }

  test("Starts", () {
    final m = TextSearchMode.starts;
    expect(searchOpts("hello", m), ["hello world"]);
    expect(searchOpts("he", m), ["hell", "hello world"]);
  });
  test("WordStarts", () {
    final m = TextSearchMode.wordStarts;
    expect(searchOpts("hello", m), ["hello world", "world hello"]);
    expect(searchOpts("he", m), ["hell", "hello world", "world hello"]);
  });
  test("Contains", () {
    final m = TextSearchMode.contains;
    expect(searchOpts("hello", m), ["hello world", "world hello", "shello"]);
    expect(searchOpts("he", m), ["hell", "hello world", "world hello", "shello"]);
    expect(searchOpts("wo", m), ["hello world", "world hello"]);
  });
  test("Is case insensitive", () {
    final m = TextSearchMode.contains;
    expect(searchOpts("a", m, opts: ["a", "b", "A"]), ["a", "A"]);
    expect(searchOpts("A", m, opts: ["a", "b", "A"]), ["a", "A"]);
  });
}
