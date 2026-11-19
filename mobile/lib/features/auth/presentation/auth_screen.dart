import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/auth_repository.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.repository});

  final AuthRepository repository;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signup = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_form.currentState!.validate()) return;
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      await widget.repository.authenticate(
        email: _email.text.trim(),
        password: _password.text,
        signup: _signup,
      );
      if (!mounted) return;
      TextInput.finishAutofillContext();
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = _signup ? 'Create account' : 'Log in';
    return Scaffold(
      appBar: AppBar(title: const Text('Sri Lanka Travel Planner')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                onDisposeAction: AutofillContextAction.cancel,
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        action,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _email,
                        enabled: !_submitting,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) {
                          final email = value!.trim();
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
                        controller: _password,
                        enabled: !_submitting,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        autofillHints: [
                          _signup
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          helperText: _signup ? 'At least 15 characters' : null,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your password.';
                          }
                          if (_signup && value.runes.length < 15) {
                            return 'Use at least 15 characters.';
                          }
                          if (utf8.encode(value).length > 1024) {
                            return 'Password is too long.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 20),
                      if (_error != null)
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      FilledButton(
                        onPressed: _submitting ? null : _submit,
                        child: Text(_submitting ? 'Please wait…' : action),
                      ),
                      TextButton(
                        onPressed: _submitting
                            ? null
                            : () {
                                _form.currentState!.reset();
                                _password.clear();
                                setState(() {
                                  _signup = !_signup;
                                  _error = null;
                                });
                              },
                        child: Text(_signup ? 'Back to login' : 'Sign up'),
                      ),
                    ],
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
