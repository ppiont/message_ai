/// PII (Personally Identifiable Information) detection and sanitization
library;

/// Result of PII detection and sanitization
class PIIDetectionResult {
  const PIIDetectionResult({
    required this.sanitizedText,
    required this.containsPII,
    required this.detectedTypes,
  });

  /// Text with PII replaced by placeholders
  final String sanitizedText;

  /// Whether any PII was detected
  final bool containsPII;

  /// Types of PII detected (e.g., ['email', 'phone'])
  final List<String> detectedTypes;
}

/// Detector for PII in text messages
///
/// This class detects and sanitizes Personally Identifiable Information
/// before sending messages to cloud functions for analysis. This protects
/// user privacy and reduces liability.
///
/// Detected PII types:
/// - Email addresses -> `[EMAIL]`
/// - Phone numbers -> `[PHONE]`
/// - Credit card numbers -> `[CARD]`
/// - Social security numbers -> `[SSN]`
/// - URLs -> `[URL]`
class PIIDetector {
  /// Regex patterns for PII detection
  static final RegExp _emailPattern = RegExp(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    caseSensitive: false,
  );

  static final RegExp _phonePattern = RegExp(
    r'''(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b|'''
    r'''\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b|'''
    r'''\b\d{10}\b''',
  );

  static final RegExp _creditCardPattern = RegExp(
    r'\b(?:\d{4}[-\s]?){3}\d{4}\b',
  );

  static final RegExp _ssnPattern = RegExp(
    r'\b\d{3}[-\s]?\d{2}[-\s]?\d{4}\b',
  );

  static final RegExp _urlPattern = RegExp(
    r'https?://[^\s]+|www\.[^\s]+',
    caseSensitive: false,
  );

  /// Detect and sanitize PII in the given text
  ///
  /// Returns a [PIIDetectionResult] with:
  /// - sanitizedText: Text with PII replaced by placeholders
  /// - containsPII: Whether any PII was found
  /// - detectedTypes: List of PII types found
  static PIIDetectionResult detectAndSanitize(String text) {
    var sanitized = text;
    final detectedTypes = <String>{};

    // Detect and sanitize emails
    if (_emailPattern.hasMatch(sanitized)) {
      sanitized = sanitized.replaceAll(_emailPattern, '[EMAIL]');
      detectedTypes.add('email');
    }

    // Detect and sanitize phone numbers
    if (_phonePattern.hasMatch(sanitized)) {
      sanitized = sanitized.replaceAll(_phonePattern, '[PHONE]');
      detectedTypes.add('phone');
    }

    // Detect and sanitize credit card numbers
    if (_creditCardPattern.hasMatch(sanitized)) {
      sanitized = sanitized.replaceAll(_creditCardPattern, '[CARD]');
      detectedTypes.add('card');
    }

    // Detect and sanitize SSNs
    if (_ssnPattern.hasMatch(sanitized)) {
      sanitized = sanitized.replaceAll(_ssnPattern, '[SSN]');
      detectedTypes.add('ssn');
    }

    // Detect and sanitize URLs
    if (_urlPattern.hasMatch(sanitized)) {
      sanitized = sanitized.replaceAll(_urlPattern, '[URL]');
      detectedTypes.add('url');
    }

    return PIIDetectionResult(
      sanitizedText: sanitized,
      containsPII: detectedTypes.isNotEmpty,
      detectedTypes: detectedTypes.toList(),
    );
  }

  /// Check if text contains PII without sanitizing
  static bool containsPII(String text) => _emailPattern.hasMatch(text) ||
      _phonePattern.hasMatch(text) ||
      _creditCardPattern.hasMatch(text) ||
      _ssnPattern.hasMatch(text) ||
      _urlPattern.hasMatch(text);
}
