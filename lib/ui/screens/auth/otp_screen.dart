import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../../state/providers.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final int? resendToken;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  int _secondsRemaining = 60;
  Timer? _timer;
  bool _isLoading = false;
  late String _currentVerificationId;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 6-digit code')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = ref.read(firebaseAuthServiceProvider);

    try {
      final credential = auth.PhoneAuthProvider.credential(
        verificationId: _currentVerificationId,
        smsCode: otp,
      );

      await authService.signInWithPhoneCredential(credential);

      if (mounted) {
        context.go('/profile-setup');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invalid code: $e')));
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isLoading = true;
    });

    final authService = ref.read(firebaseAuthServiceProvider);

    try {
      await authService.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Resend Failed: ${e.message}')),
          );
        },
        codeSent: (verificationId, resendToken) {
          setState(() {
            _currentVerificationId = verificationId;
            _secondsRemaining = 60;
            _isLoading = false;
          });
          _startTimer();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Code resent!')));
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter verification code',
                style: AppTypography.headline(context),
              ),

              const SizedBox(height: Spacing.md),

              Text(
                'We sent a code to ${widget.phoneNumber}',
                style: AppTypography.bodySmall(context),
              ),

              const SizedBox(height: Spacing.xxxl),

              // OTP input boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      decoration: const InputDecoration(counterText: ''),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        }
                        if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        if (value.isNotEmpty && index == 5) {
                          _verifyOtp(); // Auto submit
                        }
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: Spacing.xl),

              // Resend code
              Center(
                child: TextButton(
                  onPressed: (_secondsRemaining == 0 && !_isLoading)
                      ? _resendCode
                      : null,
                  child: Text(
                    _secondsRemaining > 0
                        ? 'Resend code in $_secondsRemaining s'
                        : 'Resend code',
                  ),
                ),
              ),

              const Spacer(),

              // Verify button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
