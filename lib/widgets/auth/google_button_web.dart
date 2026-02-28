import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';

Widget buildGoogleSignInButton({
  required VoidCallback onPressed,
  bool isLoading = false,
}) {
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: double.infinity, minHeight: 50),
    child: (GoogleSignInPlatform.instance as GoogleSignInPlugin).renderButton(),
  );
}
