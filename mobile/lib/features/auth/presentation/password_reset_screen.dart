import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/auth_repository.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({
    super.key,
    required this.repository,
    required this.email,
  });

  final AuthRepository repository;
  final String email;

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _codeRequested = false;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit({bool resend = false}) async {
    if (_busy || (!resend && !_form.currentState!.validate())) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _message = null;
    });
    final email = _email.text.trim();
    try {
      if (_codeRequested && !resend) {
        await widget.repository.resetPassword(
          email,
          _code.text.trim(),
          _password.text,
        );
        if (mounted) Navigator.of(context).pop(email);
      } else {
        await widget.repository.requestPasswordReset(email);
        if (!mounted) return;
        setState(() => _codeRequested = true);
        if (resend) {
          setState(
            () => _message = 'If a code was already sent, wait a minute before requesting another.',
          );
        }
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String? Function(String) validate, {
    bool secret = false,
    bool enabled = true,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        enabled: enabled && !_busy,
        obscureText: secret,
        autocorrect: false,
        enableSuggestions: false,
        keyboardType: keyboard,
        validator: (value) => validate(value ?? ''),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _codeRequested
                              ? 'If an account uses this email, a reset code will arrive shortly. Enter it within 15 minutes.'
                              : 'Enter your account email to request a reset code.',
                        ),
                        const SizedBox(height: 16),
                        _field(
                          'Email address',
                          _email,
                          (value) =>
                              value.trim().length <= 254 &&
                                  RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                      .hasMatch(value.trim())
                              ? null
                              : 'Enter a valid email address.',
                          enabled: !_codeRequested,
                          keyboard: TextInputType.emailAddress,
                        ),
                        if (_codeRequested) ...[
                          _field(
                            'Reset code',
                            _code,
                            (value) =>
                                RegExp(r'^[\w-]{32}$').hasMatch(value.trim())
                                ? null
                                : 'Paste the code from your email.',
                          ),
                          _field(
                            'New password',
                            _password,
                            (value) =>
                                value.runes.length >= 8 &&
                                    utf8.encode(value).length <= 1024
                                ? null
                                : 'Use at least 8 characters and at most 1024 bytes.',
                            secret: true,
                          ),
                          _field(
                            'Confirm new password',
                            _confirmation,
                            (value) => value == _password.text
                                ? null
                                : 'Passwords do not match.',
                            secret: true,
                          ),
                        ],
                        if (_message != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(_message!),
                            ),
                          ),
                        FilledButton(
                          onPressed: _busy ? null : () => _submit(),
                          child: Text(
                            _busy
                                ? 'Please wait…'
                                : _codeRequested
                                ? 'Update password'
                                : 'Send reset code',
                          ),
                        ),
                        if (_codeRequested)
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _submit(resend: true),
                            child: const Text('Resend code'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
