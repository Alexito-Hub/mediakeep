// This file uses conditional exports to provide the correct implementation
// for the current platform (Web vs Native).

export 'download_service_native.dart'
    if (dart.library.js_util) 'download_service_web.dart'
    if (dart.library.html) 'download_service_web.dart';
