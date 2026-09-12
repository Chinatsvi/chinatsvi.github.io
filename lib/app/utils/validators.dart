class Validations {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    return null;
  }

  static String? validateCrop(String? value) {
    if (value == null || value.trim().isEmpty) return 'Crop name is required';
    return null;
  }
}