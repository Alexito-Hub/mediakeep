import 'package:flutter/material.dart';

Widget buildGoogleSignInButton({
  required VoidCallback onPressed,
  bool isLoading = false,
}) {
  return OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: Colors.grey),
      foregroundColor: Colors.black, // Default color for mobile button
    ),
    icon: const Icon(Icons.g_mobiledata, size: 32, color: Colors.red),
    label: const Text(
      'Continuar con Google',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
    onPressed: isLoading ? null : onPressed,
  );
}
