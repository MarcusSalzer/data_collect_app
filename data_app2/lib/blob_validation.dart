import 'package:data_app2/data/user_schema.dart';

sealed class BFError {
  const BFError();

  String get message;
}

class BFMissing extends BFError {
  const BFMissing();
  @override
  get message => "Missing";
}

class BFTypeError extends BFError {
  final String t;
  const BFTypeError(this.t);
  @override
  get message => "Unexpected type $t";
}

/// Describe the status of a field value.
enum BlobFieldError {
  missing,
  type,
  constraint,
  enumGroup,
  enumValue,
}

class BlobValidationResult {
  final Set<String> excessKeys;
  final Map<String, BlobFieldError?> fieldErrors;
  const BlobValidationResult(this.excessKeys, this.fieldErrors);

  bool isOk() => excessKeys.isEmpty && fieldErrors.values.fold(true, (p, c) => p && c == null);
}

/// allows validating blob data w.r.t schema
class BlobValidation {
  /// check a value against this field
  BlobFieldError? validateField(Object? value, BlobFieldSpec field) {
    if (value == null) {
      return field.nullable ? null : BlobFieldError.missing;
    }

    // For most "simple" fields, only the field FieldType and the value is needed
    // Others need more care:
    // - Enum: needs access to enums for checking
    // - Tuple: needs validation of children

    if (!field.type.isValid(value)) {
      return BlobFieldError.type;
    }

    return null;
  }

  /// Separate, needs more loaded data to work!
  // validateEnum(UnmodifiableMapView<String, Set<String>> enumGroups) {
  //   // if (field.type case DEnum d) {
  //   //   final eVals = enumGroups[d.group];
  //   //   if (eVals == null) {
  //   //     return BlobFieldError.enumGroup;
  //   //   }
  //   //   if (!eVals.contains(value)) {
  //   //     return BlobFieldError.enumValue;
  //   //   }
  //   // }
  // }

  BlobValidationResult validateBlob(UserBlobRec blob, BlobSchemaRec schema) {
    final excessKeys = blob.values.keys.toSet().difference(schema.fields.keys.toSet());
    final fieldErrors = {
      for (var MapEntry(key: k, value: f) in schema.fields.entries) k: validateField(blob.values[k], f),
    };

    if (schema.evtLink != null && blob.eventId == null) {
      fieldErrors["event"] = BlobFieldError.missing;
    }

    return BlobValidationResult(excessKeys, fieldErrors);
  }
}
