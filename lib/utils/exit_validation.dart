class ExitValidation {
  static String? validateQuantity(String? value, int availableCount) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a number';
    }

    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 1) {
      return 'Enter a valid number';
    }

    if (parsed > availableCount) {
      return 'Only $availableCount animals available';
    }

    return null;
  }
}
