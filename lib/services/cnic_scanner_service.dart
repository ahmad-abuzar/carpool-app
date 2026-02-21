import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/cnic_data.dart';

/// Service for scanning and parsing Pakistani CNIC using ML Kit OCR
class CnicScannerService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Scan CNIC image and extract data
  Future<CnicData?> scanCnic(File imageFile) async {
    try {
      print('Starting CNIC scan...');

      // Process image with ML Kit
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      print('Text recognized: ${recognizedText.text}');

      // Parse CNIC data from recognized text
      final cnicData = _parseCnicData(recognizedText.text);

      return cnicData;
    } catch (e) {
      print('Error scanning CNIC: $e');
      return null;
    }
  }

  /// Parse CNIC data from OCR text
  CnicData? _parseCnicData(String text) {
    try {
      // Extract CNIC number
      final cnicNumber = _extractCnicNumber(text);
      if (cnicNumber == null) {
        print('Could not extract CNIC number');
        return null;
      }

      // Extract name
      final name = _extractName(text);

      // Extract father's name
      final fatherName = _extractFatherName(text);

      // Extract dates
      final dob = _extractDateOfBirth(text);
      final doi = _extractDateOfIssue(text);
      final doe = _extractDateOfExpiry(text);

      return CnicData(
        cnicNumber: cnicNumber,
        name: name ?? 'Unknown',
        fatherName: fatherName ?? 'Unknown',
        dateOfBirth: dob,
        dateOfIssue: doi,
        dateOfExpiry: doe,
      );
    } catch (e) {
      print('Error parsing CNIC data: $e');
      return null;
    }
  }

  /// Extract CNIC number from text
  /// Format: XXXXX-XXXXXXX-X or XXXXXXXXXXXXX (13 digits)
  String? _extractCnicNumber(String text) {
    // Try with dashes: 12345-1234567-1
    final regexWithDashes = RegExp(r'\d{5}-\d{7}-\d{1}');
    final matchWithDashes = regexWithDashes.firstMatch(text);
    if (matchWithDashes != null) {
      return matchWithDashes.group(0);
    }

    // Try without dashes: 1234512345671
    final regexWithoutDashes = RegExp(r'\d{13}');
    final matchWithoutDashes = regexWithoutDashes.firstMatch(text);
    if (matchWithoutDashes != null) {
      final cnic = matchWithoutDashes.group(0)!;
      // Format with dashes
      return '${cnic.substring(0, 5)}-${cnic.substring(5, 12)}-${cnic.substring(12)}';
    }

    return null;
  }

  /// Extract name from text
  /// Usually appears after "Name" or on the second/third line
  String? _extractName(String text) {
    final lines = text.split('\n');

    // Look for line containing "Name"
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains('name') &&
          !lines[i].toLowerCase().contains('father')) {
        // Name is usually on the next line
        if (i + 1 < lines.length) {
          return lines[i + 1].trim();
        }
      }
    }

    // Fallback: second line (after card type)
    if (lines.length > 1) {
      return lines[1].trim();
    }

    return null;
  }

  /// Extract father's name from text
  String? _extractFatherName(String text) {
    final lines = text.split('\n');

    // Look for line containing "Father" or "S/O" or "D/O"
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      if (line.contains('father') ||
          line.contains('s/o') ||
          line.contains('d/o')) {
        // Father's name is usually on the next line
        if (i + 1 < lines.length) {
          return lines[i + 1].trim();
        }
      }
    }

    return null;
  }

  /// Extract date of birth
  DateTime? _extractDateOfBirth(String text) {
    return _extractDate(text, ['dob', 'date of birth', 'birth']);
  }

  /// Extract date of issue
  DateTime? _extractDateOfIssue(String text) {
    return _extractDate(text, ['issue', 'doi']);
  }

  /// Extract date of expiry
  DateTime? _extractDateOfExpiry(String text) {
    return _extractDate(text, ['expiry', 'doe', 'valid']);
  }

  /// Generic date extraction
  /// Supports formats: DD-MM-YYYY, DD/MM/YYYY, DD.MM.YYYY
  DateTime? _extractDate(String text, List<String> keywords) {
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();

      // Check if line contains any keyword
      for (final keyword in keywords) {
        if (line.contains(keyword)) {
          // Date is usually on same line or next line
          final dateStr = i < lines.length ? lines[i] : '';
          final nextLine = i + 1 < lines.length ? lines[i + 1] : '';

          // Try different date formats
          final date = _parseDate(dateStr) ?? _parseDate(nextLine);
          if (date != null) return date;
        }
      }
    }

    return null;
  }

  /// Parse date from string
  DateTime? _parseDate(String str) {
    // Remove all non-digit and non-separator characters
    final cleaned = str.replaceAll(RegExp(r'[^\d/\-.]'), '');

    // Try DD-MM-YYYY, DD/MM/YYYY, DD.MM.YYYY
    final dateRegex = RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})');
    final match = dateRegex.firstMatch(cleaned);

    if (match != null) {
      try {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        return DateTime(year, month, day);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}
