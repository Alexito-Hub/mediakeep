/// Model for server health response
class ServerHealth {
  final String status;
  final DateTime timestamp;
  final double uptime;
  final String environment;

  ServerHealth({
    required this.status,
    required this.timestamp,
    required this.uptime,
    required this.environment,
  });

  factory ServerHealth.fromJson(Map<String, dynamic> json) {
    return ServerHealth(
      status: json['status'] ?? 'unknown',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      uptime: (json['uptime'] as num?)?.toDouble() ?? 0.0,
      environment: json['environment'] ?? 'unknown',
    );
  }
}

/// Model for individual platform status
class PlatformStatus {
  final String platformName;
  final int? statusCode;
  final Duration? responseTime;
  final String status;
  final String? errorMessage;
  final String? lastTestedUrl;
  final Map<String, dynamic>? responseData;
  final dynamic validation; // ValidationResult from schema_validator

  PlatformStatus({
    required this.platformName,
    this.statusCode,
    this.responseTime,
    required this.status,
    this.errorMessage,
    this.lastTestedUrl,
    this.responseData,
    this.validation,
  });

  bool get isHealthy =>
      statusCode == 200 &&
      (validation == null || (validation.isValid as bool? ?? true));
}
