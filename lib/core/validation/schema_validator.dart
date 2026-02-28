import 'platform_schema.dart';

/// Generic validator that works with any PlatformSchema
class SchemaValidator {
  /// Validates data against a platform schema
  static ValidationResult validate(
    Map<String, dynamic> responseData,
    PlatformSchema schema,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    // Get the data root based on schema configuration
    final dataRoot = schema.hasDataWrapper
        ? (responseData['data'] as Map<String, dynamic>?)
        : responseData;

    if (dataRoot == null && schema.hasDataWrapper) {
      return ValidationResult(
        isValid: false,
        errors: ['Missing required "data" field'],
      );
    }

    final root = dataRoot ?? responseData;

    // Validate required fields
    for (final rule in schema.requiredFields) {
      _validateField(root, rule, errors, isRequired: true);
    }

    // Check optional fields (warnings only)
    for (final rule in schema.optionalFields) {
      _validateField(root, rule, warnings, isRequired: false);
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  static void _validateField(
    Map<String, dynamic> data,
    FieldRule rule,
    List<String> messages, {
    required bool isRequired,
  }) {
    // Navigate JSON path (e.g., 'data.media.nowatermark.play')
    final value = _getNestedValue(data, rule.path);

    if (value == null) {
      if (isRequired) {
        messages.add(
          rule.errorMessage ?? 'Missing required field: ${rule.path}',
        );
      } else {
        messages.add('Optional field missing: ${rule.path}');
      }
      return;
    }

    // Validate type
    if (!_validateType(value, rule.type)) {
      messages.add(
        'Field "${rule.path}" has wrong type. Expected ${rule.type}',
      );
      return;
    }

    // Run custom validators
    if (rule.validators != null) {
      for (final validator in rule.validators!) {
        if (!validator.validate(value)) {
          messages.add(
            rule.errorMessage ??
                'Field "${rule.path}": ${validator.errorMessage}',
          );
          return;
        }
      }
    }
  }

  static dynamic _getNestedValue(Map<String, dynamic> data, String path) {
    final parts = path.split('.');
    dynamic current = data;

    for (final part in parts) {
      if (current is! Map) return null;
      current = current[part];
      if (current == null) return null;
    }

    return current;
  }

  static bool _validateType(dynamic value, FieldType type) {
    switch (type) {
      case FieldType.string:
      case FieldType.url:
      case FieldType.mediaUrl:
        return value is String;
      case FieldType.number:
        return value is num;
      case FieldType.boolean:
        return value is bool;
      case FieldType.map:
        return value is Map;
      case FieldType.list:
        return value is List;
    }
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  bool get hasWarnings => warnings.isNotEmpty;

  String get summary {
    if (isValid && !hasWarnings) return 'Valido';
    if (isValid && hasWarnings) return 'Valido con advertencias';
    return 'Invalido';
  }

  String get detailedMessage {
    final parts = <String>[];
    if (errors.isNotEmpty) {
      parts.add('Errores:');
      for (final e in errors) {
        parts.add('  - $e');
      }
    }
    if (warnings.isNotEmpty) {
      if (parts.isNotEmpty) parts.add(''); // Empty line separator
      parts.add('Advertencias:');
      for (final w in warnings) {
        parts.add('  - $w');
      }
    }
    return parts.isEmpty ? 'Todos los campos validos' : parts.join('\n');
  }
}
