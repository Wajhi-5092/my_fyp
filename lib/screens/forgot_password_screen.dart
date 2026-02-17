import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../widgets/login_signup_widget.dart';
import '../widgets/custom_snackbar.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  int _step = 1; // 1: Email Input, 2: OTP & New Password
  bool _isLoading = false;

  Timer? _timer;
  int _start = 30;
  bool _canResend = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    _start = 30;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.forgotPassword(_emailController.text);
      if (res["success"] == true) {
        if (mounted) {
          CustomSnackBar.show(context, "OTP resent successfully!");
          startTimer();
        }
      } else {
        if (mounted) {
          CustomSnackBar.show(context, res["error"], isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, "Failed to resend OTP", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Step 1: Send OTP
  Future<void> _sendOtp() async {
    if (_emailController.text.isEmpty) {
      CustomSnackBar.show(context, "Please enter your email", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.forgotPassword(_emailController.text);
      if (res["success"] == true) {
        if (mounted) {
          CustomSnackBar.show(context, "OTP sent! Check your console.");
          setState(() => _step = 2);
          startTimer();
        }
      } else {
        if (mounted) {
          CustomSnackBar.show(context, res["error"], isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, "Failed to send OTP", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Step 2: Reset Password
  Future<void> _resetPassword() async {
    if (_otpController.text.isEmpty || _newPasswordController.text.isEmpty) {
      CustomSnackBar.show(context, "Please fill in all fields", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.resetPassword(
        _emailController.text,
        _otpController.text,
        _newPasswordController.text,
      );

      if (res["success"] == true) {
        if (mounted) {
          CustomSnackBar.show(context, "Password reset successfully!");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } else {
        if (mounted) {
          CustomSnackBar.show(context, res["error"], isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, "Failed to reset password", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Reset Password",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _step == 1
                    ? "Enter your email to receive an OTP."
                    : "Enter the OTP sent to your email and your new password.",
                style: const TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 40),

              if (_step == 1) ...[
                CustomTextField(
                  controller: _emailController,
                  hint: "Enter your Email",
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GradientButton(label: "SEND OTP", onTap: _sendOtp),
              ] else ...[
                CustomTextField(
                  controller: _otpController,
                  hint: "Enter OTP (4 digits)",
                  icon: Icons.lock_clock_outlined,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _newPasswordController,
                  hint: "New Password",
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GradientButton(
                        label: "RESET PASSWORD",
                        onTap: _resetPassword,
                      ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: _canResend && !_isLoading ? _resendOtp : null,
                    child: Text(
                      _canResend
                          ? "Resend OTP"
                          : "Resend OTP in $_start seconds",
                      style: TextStyle(
                        color: _canResend
                            ? const Color(0xFF00E5FF)
                            : Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
