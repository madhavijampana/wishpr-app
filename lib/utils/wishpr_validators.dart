/// Shared form validation for auth and safety flows.
abstract final class WishprValidators {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? email(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return 'Enter your email';
    if (!_emailRegex.hasMatch(s)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Sign-in: non-empty only (Firebase enforces format server-side).
  static String? passwordSignIn(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password';
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? passwordSignUp(String? value) {
    if (value == null || value.isEmpty) return 'Choose a password';
    if (value.length < 8) {
      return 'Use at least 8 characters';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'Include at least one letter';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Include at least one number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? fullName(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return 'Enter your name';
    if (s.length < 2) return 'Name looks too short';
    if (s.length > 80) return 'Name is too long';
    return null;
  }

  static String? phraseLabel(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return 'Give this phrase a label';
    if (s.length < 2) return 'Use at least 2 characters';
    if (s.length > 80) return 'Keep the label under 80 characters';
    return null;
  }

  static String? secretPhrase(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return 'Enter the exact words you will say';
    if (s.length < 3) {
      return 'Phrase should be at least 3 characters';
    }
    if (s.length > 500) return 'Phrase is too long';
    return null;
  }

  static String? phone(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return 'Enter a phone number';
    final digits = s.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      return 'Enter a number with at least 10 digits';
    }
    if (digits.length > 15) return 'Phone number looks too long';
    return null;
  }

  static String? relationship(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return 'Describe how you know this person';
    if (s.length < 2) return 'Add a bit more detail';
    if (s.length > 120) return 'Relationship note is too long';
    return null;
  }
}
