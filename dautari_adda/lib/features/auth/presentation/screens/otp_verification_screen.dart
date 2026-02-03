import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dautari_adda/features/auth/data/otp_service.dart';
import 'package:dautari_adda/core/utils/toast_service.dart';
import 'dart:async';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String type; // 'signup' or 'reset'
  final Function(String code)? onSuccess;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.type,
    this.onSuccess,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final OtpService _otpService = OtpService();
  bool _isLoading = false;
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendTimer = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    String code = _controllers.map((c) => c.text).join();
    if (code.length < 6) {
      ToastService.show(context, 'Please enter the full 6-digit code', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _otpService.verifyOtp(email: widget.email, code: code);
      if (mounted) {
        if (result['success']) {
          ToastService.show(context, 'Verification successful');
          if (widget.onSuccess != null) {
            widget.onSuccess!(code);
          } else {
            Navigator.pop(context, code);
          }
        } else {
          ToastService.show(context, result['message'], isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        ToastService.show(context, 'Error verifying OTP: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendTimer > 0) return;

    setState(() => _isLoading = true);
    try {
      final result = await _otpService.sendOtp(email: widget.email, type: widget.type);
      if (mounted) {
        if (result['success']) {
          ToastService.show(context, 'New OTP sent to ${widget.email}');
          _startTimer();
          for (var c in _controllers) {
            c.clear();
          }
          _focusNodes[0].requestFocus();
        } else {
          ToastService.show(context, result['message'], isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        ToastService.show(context, 'Error resending OTP: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Verify Email", style: GoogleFonts.poppins(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 80,
                  color: Color(0xFFFFC107),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "OTP Verification",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600], height: 1.5),
                  children: [
                    const TextSpan(text: "We have sent a 6-digit verification code to\n"),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => _buildOtpBox(index)),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Verify and Proceed",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code? ",
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: _resendTimer > 0 || _isLoading ? null : _resendOtp,
                    child: Text(
                      _resendTimer > 0 ? "Resend in ${_resendTimer}s" : "Resend Now",
                      style: GoogleFonts.poppins(
                        color: _resendTimer > 0 ? Colors.grey : const Color(0xFFFFC107),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 45,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focusNodes[index].hasFocus ? const Color(0xFFFFC107) : Colors.grey[200]!,
          width: 2,
        ),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
              _verifyOtp();
            }
          } else {
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
        },
      ),
    );
  }
}
