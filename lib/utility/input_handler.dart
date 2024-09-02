
class FormController {
  // TODO encapsulate form logic??
}




/// Validate an input field based on its [dtype].
String? validateField(String text, String dtype, {bool allowEmpty = true}) {
  text = text.trim();
  if (text.isEmpty) {
    if (allowEmpty) {
      return null;
    } else {
      return "Please enter a value";
    }
  } else if (text.contains(",")) {
    return "Value cannot contain ',' (CSV separator)";
  }

  switch (dtype) {
    case "numeric":
      if (num.tryParse(text) == null) {
        return "Invalid number";
      }
      break;
    case "datetime":
      if (DateTime.tryParse(text) == null) {
        return "Cannot parse DateTime";
      }
      break;
  }
  return null;
}
