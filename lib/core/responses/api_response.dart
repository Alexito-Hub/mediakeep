/// Response wrapper for API calls
class ApiResponse {
  final bool success;
  final String? errorMessage;
  final Map<String, dynamic>? data;
  final String? platform;
  final bool limitReached;

  ApiResponse._({
    required this.success,
    this.errorMessage,
    this.data,
    this.platform,
    this.limitReached = false,
  });

  factory ApiResponse.success({
    required Map<String, dynamic> data,
    required String platform,
  }) {
    return ApiResponse._(success: true, data: data, platform: platform);
  }

  factory ApiResponse.error(String message, {bool limitReached = false}) {
    return ApiResponse._(
      success: false,
      errorMessage: message,
      limitReached: limitReached,
    );
  }
}
