import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/theme/explore_lanka_theme.dart';
import '../data/auth_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.repository,
    required this.onBack,
  });

  final AuthRepository repository;
  final VoidCallback onBack;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  late AccountProfile _profile = widget.repository.profile;
  late final _name = TextEditingController(text: _profile.fullName);
  late final _phone = TextEditingController(text: _profile.phoneNumber);
  late final _email = TextEditingController(text: _profile.email);
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _phone,
      _email,
      _current,
      _password,
      _confirmation,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await _run(() async {
      final profile = await widget.repository.updateProfile({
        'fullName': _name.text.trim(),
        'phoneNumber': _phone.text.trim(),
        'email': _email.text.trim(),
        if (_current.text.isNotEmpty) 'currentPassword': _current.text,
        if (_password.text.isNotEmpty) 'newPassword': _password.text,
      });
      if (!mounted) return;
      setState(() => _profile = profile);
      _name.text = profile.fullName;
      _phone.text = profile.phoneNumber;
      _email.text = profile.email;
      _current.clear();
      _password.clear();
      _confirmation.clear();
      _message('Profile updated.');
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on AuthException catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboard,
    String? Function(String)? validate,
    bool secret = false,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: TextFormField(
        controller: controller,
        enabled: !_busy,
        keyboardType: keyboard,
        obscureText: secret,
        autocorrect: !secret,
        enableSuggestions: !secret,
        validator: validate == null ? null : (value) => validate(value ?? ''),
        decoration: InputDecoration(
          labelText: label,
          helperText: hint,
          helperMaxLines: 2,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _panel(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: widget.onBack),
        title: const Text('Your profile'),
        actions: [
          TextButton.icon(
            onPressed: _busy ? null : () => _run(widget.repository.logout),
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color: exploreTeal,
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              child: Icon(Icons.person_outline),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _profile.fullName.isEmpty
                                        ? 'Traveler'
                                        : _profile.fullName,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    _profile.email,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _panel('Contact details', [
                      _field(
                        'Full name',
                        _name,
                        Icons.badge_outlined,
                        validate: (value) =>
                            value.trim().isEmpty || value.trim().length > 120
                            ? 'Enter a full name of up to 120 characters.'
                            : null,
                      ),
                      _field(
                        'Phone number',
                        _phone,
                        Icons.phone_outlined,
                        keyboard: TextInputType.phone,
                        validate: (value) => value.trim().isEmpty
                            ? 'Enter your phone number.'
                            : null,
                      ),
                      _field(
                        'Email address',
                        _email,
                        Icons.mail_outline,
                        keyboard: TextInputType.emailAddress,
                        validate: (value) =>
                            RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(value.trim()) &&
                                value.trim().length <= 254
                            ? null
                            : 'Enter a valid email address.',
                      ),
                    ]),
                    _panel('Account security', [
                      _field(
                        'Current password',
                        _current,
                        Icons.lock_outline,
                        secret: true,
                        hint: 'Required to change your email or password.',
                        validate: (value) =>
                            value.isEmpty &&
                                (_password.text.isNotEmpty ||
                                    _email.text.trim().toLowerCase() !=
                                        _profile.email.toLowerCase())
                            ? 'Enter your current password.'
                            : null,
                      ),
                      _field(
                        'New password',
                        _password,
                        Icons.lock_outline,
                        secret: true,
                        validate: (value) =>
                            value.isNotEmpty &&
                                (value.runes.length < 8 ||
                                    utf8.encode(value).length > 1024)
                            ? 'Use at least 8 characters and at most 1024 bytes.'
                            : null,
                      ),
                      _field(
                        'Confirm new password',
                        _confirmation,
                        Icons.lock_outline,
                        secret: true,
                        validate: (value) => value != _password.text
                            ? 'Passwords do not match.'
                            : null,
                      ),
                    ]),
                    FilledButton(
                      onPressed: _busy ? null : _save,
                      child: Text(_busy ? 'Please wait…' : 'Save changes'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
