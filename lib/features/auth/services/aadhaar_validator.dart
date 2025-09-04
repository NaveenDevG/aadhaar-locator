class AadhaarValidator {
  /// Validates Aadhaar number format
  /// Aadhaar should be 12 digits, not all same digits
  static bool isValidNumber(String value) {
    // Remove any non-digit characters
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Must be exactly 12 digits
    if (digits.length != 12) return false;
    
    // Cannot be all same digits (like 111111111111)
    if (RegExp(r'^(\d)\1{11}$').hasMatch(digits)) return false;
    
    // Basic checksum validation (simplified)
    // In production, implement proper Aadhaar checksum algorithm
    return true;
  }

  /// Validates Aadhaar name
  /// Name should have at least 2 words and minimum 3 characters
  static bool isValidName(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 3) return false;
    
    final words = trimmed.split(' ').where((word) => word.isNotEmpty).toList();
    return words.length >= 2;
  }

  /// Validates date of birth
  /// Must be in the past and user should be at least 18 years old
  static bool isValidDob(DateTime dob) {
    final now = DateTime.now();
    final age = now.year - dob.year;
    
    // Check if birthday has occurred this year
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      return age - 1 >= 18;
    }
    
    return age >= 18;
  }

  /// Validates complete Aadhaar information
  static Map<String, String?> validateAadhaarInfo({
    required String name,
    required String number,
    required DateTime dob,
  }) {
    final errors = <String, String?>{};
    
    if (!isValidName(name)) {
      errors['name'] = 'Please enter your full name as per Aadhaar';
    }
    
    if (!isValidNumber(number)) {
      errors['number'] = 'Please enter a valid 12-digit Aadhaar number';
    }
    
    if (!isValidDob(dob)) {
      errors['dob'] = 'You must be at least 18 years old';
    }
    
    return errors;
  }

  /// Formats Aadhaar number for display (XXXX-XXXX-XXXX)
  static String formatAadhaarNumber(String number) {
    final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 12) return number;
    
    return '${digits.substring(0, 4)}-${digits.substring(4, 8)}-${digits.substring(8)}';
  }

  /// Masks Aadhaar number for display (XXXX-XXXX-1234)
  static String maskAadhaarNumber(String number) {
    final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 12) return number;
    
    return 'XXXX-XXXX-${digits.substring(8)}';
  }
}
