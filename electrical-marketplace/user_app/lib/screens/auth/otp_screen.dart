import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../core/utils/toast_helper.dart';
import '../../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final String? devOtp;
  const OtpScreen({super.key, required this.phone, this.devOtp});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    if (widget.devOtp != null) {
      _otpController.text = widget.devOtp!;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown == 0) {
        t.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_otpController.text.length < 6) {
      ToastHelper.error('Enter the 6-digit OTP');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .verifyOtp(widget.phone, _otpController.text);
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      ToastHelper.error(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    try {
      final devOtp = await ref.read(authProvider.notifier).sendOtp(widget.phone);
      _startTimer();
      if (devOtp != null) {
        _otpController.text = devOtp;
      }
      ToastHelper.success('OTP sent again');
    } catch (e) {
      ToastHelper.error(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final pinTheme = PinTheme(
      width: 52,
      height: 56,
      textStyle: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: theme.colorScheme.onSurface),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('Verify OTP', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to +91 ${widget.phone}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (widget.devOtp != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bug_report, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Dev OTP: ${widget.devOtp}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),
              Center(
                child: Pinput(
                  controller: _otpController,
                  length: 6,
                  defaultPinTheme: pinTheme,
                  focusedPinTheme: pinTheme.copyWith(
                    decoration: BoxDecoration(
                      border: Border.all(color: primary, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onCompleted: (_) => _verify(),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _verify,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Verify OTP', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: _countdown > 0
                    ? Text(
                        'Resend OTP in $_countdown s',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      )
                    : TextButton(
                        onPressed: _resend,
                        child: const Text('Resend OTP'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
