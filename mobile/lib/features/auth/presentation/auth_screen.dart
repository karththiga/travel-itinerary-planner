import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/explore_lanka_theme.dart';
import '../data/auth_repository.dart';
import 'password_reset_screen.dart';

const _minimumPasswordLength = 8;
const _passwordHint = 'At least $_minimumPasswordLength characters';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.repository});

  final AuthRepository repository;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _signup = false;
  bool _submitting = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _switchMode() {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    _form.currentState?.reset();
    _password.clear();
    _confirmation.clear();
    setState(() {
      _signup = !_signup;
      _showPassword = false;
      _error = null;
    });
  }

  Future<void> _openPasswordReset() async {
    FocusScope.of(context).unfocus();
    final resetEmail = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => PasswordResetScreen(
          repository: widget.repository,
          email: _email.text.trim(),
        ),
      ),
    );
    if (!mounted || resetEmail == null) return;
    _email.text = resetEmail;
    _password.clear();
    setState(() => _error = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password updated. Sign in with your new password.'),
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      await widget.repository.authenticate(
        email: _email.text.trim(),
        password: _password.text,
        signup: _signup,
        fullName: _signup ? _name.text.trim() : null,
        phoneNumber: _signup ? _phone.text.trim() : null,
      );
      if (mounted) TextInput.finishAutofillContext();
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: exploreTeal),
      filled: true,
      fillColor: const Color(0xFFFFFAF6),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  String? _validateName(String? input) {
    final name = (input ?? '').trim();
    if (name.isEmpty ||
        name.length > 120 ||
        name.codeUnits.any((unit) => unit < 32 || unit == 127)) {
      return 'Enter a full name of up to 120 characters.';
    }
    return null;
  }

  String? _validatePhone(String? input) {
    final compact = (input ?? '').trim().replaceAll(RegExp(r'[ ().-]'), '');
    if (!RegExp(r'^0[1-9][0-9]{8}$').hasMatch(compact) &&
        !RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(compact)) {
      return 'Enter a local number or include the country code.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password.';
    if (_signup && value.runes.length < _minimumPasswordLength) {
      return 'Use at least $_minimumPasswordLength characters.';
    }
    if (utf8.encode(value).length > 1024) return 'Password is too long.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_signup,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _signup) _switchMode();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _signup ? BackButton(onPressed: _switchMode) : null,
          title: const Text(
            exploreLankaName,
            style: TextStyle(color: exploreTeal, fontWeight: FontWeight.w900),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/images/sigiriya.jpg',
                      height: _signup ? 115 : 168,
                      fit: BoxFit.cover,
                      semanticLabel: 'Illustration of Sigiriya',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: AutofillGroup(
                        onDisposeAction: AutofillContextAction.cancel,
                        child: Form(
                          key: _form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _signup
                                    ? 'Create your account'
                                    : 'Welcome back',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _signup
                                    ? 'Start planning your Sri Lanka trip.'
                                    : 'Log in to plan your next Sri Lanka trip.',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 18),
                              if (_signup) ...[
                                TextFormField(
                                  controller: _name,
                                  enabled: !_submitting,
                                  autofillHints: const [AutofillHints.name],
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  decoration: _decoration(
                                    'Full name',
                                    Icons.person_outline,
                                  ),
                                  validator: _validateName,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _phone,
                                  enabled: !_submitting,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [
                                    AutofillHints.telephoneNumber,
                                  ],
                                  decoration: _decoration(
                                    'Phone number',
                                    Icons.phone_outlined,
                                    hint: '077 123 4567 or +94 77 123 4567',
                                  ),
                                  validator: _validatePhone,
                                ),
                                const SizedBox(height: 12),
                              ],
                              TextFormField(
                                key: const ValueKey('auth-email'),
                                controller: _email,
                                enabled: !_submitting,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                autofillHints: const [
                                  AutofillHints.username,
                                  AutofillHints.email,
                                ],
                                decoration: _decoration(
                                  'Email',
                                  Icons.mail_outline,
                                ),
                                validator: (value) {
                                  final email = (value ?? '').trim();
                                  if (email.length > 254 ||
                                      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                          .hasMatch(email)) {
                                    return 'Enter a valid email address.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                key: const ValueKey('auth-password'),
                                controller: _password,
                                enabled: !_submitting,
                                obscureText: !_showPassword,
                                enableSuggestions: false,
                                autocorrect: false,
                                textInputAction: _signup
                                    ? TextInputAction.next
                                    : TextInputAction.done,
                                autofillHints: [
                                  _signup
                                      ? AutofillHints.newPassword
                                      : AutofillHints.password,
                                ],
                                decoration:
                                    _decoration(
                                      'Password',
                                      Icons.lock_outline,
                                    ).copyWith(
                                      helperText: _signup
                                          ? _passwordHint
                                          : null,
                                      suffixIcon: IconButton(
                                        tooltip: _showPassword
                                            ? 'Hide password'
                                            : 'Show password',
                                        icon: Icon(
                                          _showPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                        ),
                                        onPressed: _submitting
                                            ? null
                                            : () => setState(
                                                () => _showPassword =
                                                    !_showPassword,
                                              ),
                                      ),
                                    ),
                                validator: _validatePassword,
                                onFieldSubmitted: _signup
                                    ? null
                                    : (_) => _submit(),
                              ),
                              if (_signup) ...[
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _confirmation,
                                  enabled: !_submitting,
                                  obscureText: !_showPassword,
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  decoration: _decoration(
                                    'Confirm password',
                                    Icons.lock_outline,
                                  ),
                                  validator: (value) => value == _password.text
                                      ? null
                                      : 'Passwords do not match.',
                                  onFieldSubmitted: (_) => _submit(),
                                ),
                              ],
                              const SizedBox(height: 18),
                              if (_error != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      _error!,
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ),
                              FilledButton(
                                onPressed: _submitting ? null : _submit,
                                child: Text(
                                  _submitting
                                      ? 'Please wait…'
                                      : _signup
                                      ? 'Create account'
                                      : 'Log in',
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (!_signup)
                                TextButton(
                                  onPressed: _submitting
                                      ? null
                                      : _openPasswordReset,
                                  child: const Text('Forgot password?'),
                                ),
                              TextButton(
                                onPressed: _submitting ? null : _switchMode,
                                child: Text(
                                  _signup ? 'Back to login' : 'Sign up',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
