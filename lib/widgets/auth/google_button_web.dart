import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';

Widget buildGoogleSignInButton({
  required VoidCallback onPressed,
  bool isLoading = false,
}) {
  try {
    final plugin = GoogleSignInPlatform.instance as GoogleSignInPlugin;
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: double.infinity,
        minHeight: 50,
      ),
      child: plugin.renderButton(),
    );
  } catch (_) {}
  // Fallback: plugin not yet initialized or not available
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: const Icon(Icons.login_rounded),
      label: const Text('Continuar con Google'),
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
