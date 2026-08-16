import 'package:data_app2/data/user_schema.dart';
import 'package:test/test.dart';

/// Test that various JSON-conversions work
void main() {
  group("BlobSchemaRec.fromJson", () {
    test("minimal", () {
      final r = BlobSchemaRec.fromJson({
        "id": 13,
        "name": "Ålder",
        "fields": {},
      });

      expect(r, BlobSchemaRec(13, name: "Ålder", fields: {}, evtLink: null));
    });

    test("any evtlink", () {
      final r = BlobSchemaRec.fromJson({"id": 13, "name": "Ålder", "fields": {}, "evtLink": []});

      expect(r, BlobSchemaRec(13, name: "Ålder", fields: {}, evtLink: EvtLinkSpec.allTypes()));
    });

    test("complete", () {
      final r = BlobSchemaRec.fromJson({
        "id": 1,
        "name": "Study details",
        "fields": {
          "variant": {
            "type": {"kind": "enum", "group": "studyVariant"},
            "nullable": true,
          },
          "rating": {
            "type": {"kind": "decimal"},
            "nullable": false,
          },
        },
        "evtLink": [3, 7],
      });

      expect(
        r,
        BlobSchemaRec(
          1,
          name: "Study details",
          fields: {
            "variant": BlobFieldSpec(const DEnum("studyVariant"), nullable: true),
            "rating": BlobFieldSpec(const DDecimal(), nullable: false),
          },
          evtLink: EvtLinkSpec({3, 7}),
        ),
      );
    });
  });
}
