import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

class ToastService {
  static final FToast _fToast = FToast();

  static void show(BuildContext context, String message, {bool isError = false}) {
    _fToast.init(context);

    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      margin: const EdgeInsets.symmetric(horizontal: 20.0), // Margin from edges
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        color: isError ? const Color(0xFFEF5350) : const Color(0xFF66BB6A), // Softer Red and Green
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Wrap content
        children: [
          if (!isError) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12.0),
          ],
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );

    _fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 3),
      positionedToastBuilder: (context, child, gravity) {
        return Positioned(
          bottom: 40.0, // Distance from bottom
          left: 0,
          right: 0,
          child: Center(child: child),
        );
      },
    );
  }
}
