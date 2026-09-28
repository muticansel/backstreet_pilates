import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/app_snack_bars.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  DateTime? _birthDate;
  String? _gender;
  bool _saving = false;
  late final Future<void> _profile = _load();

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = _client.auth.currentUser;
    if (user == null) throw const ProfileFailure('Please sign in again.');
    final row = await _client
        .from('profiles')
        .select('display_name, phone, birth_date, gender')
        .eq('id', user.id)
        .single();
    _name.text = row['display_name'] as String? ?? '';
    _email.text = user.email ?? '';
    _phone.text = row['phone'] as String? ?? '';
    final birthDate = row['birth_date'] as String?;
    _birthDate = birthDate == null ? null : DateTime.parse(birthDate);
    _gender = row['gender'] as String?;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _client.auth.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await _client.from('profiles').update({
        'display_name': _name.text.trim(),
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'birth_date': _birthDate?.toIso8601String().split('T').first,
        'gender': _gender,
      }).eq('id', user.id);
      final emailChanged = _email.text.trim() != (user.email ?? '');
      if (emailChanged) {
        await _client.auth.updateUser(
          UserAttributes(email: _email.text.trim()),
          emailRedirectTo: 'backstreetpilates://login-callback/',
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBars.success(
          emailChanged
              ? 'Profile saved. Confirm your new email address to finish changing it.'
              : 'Profile saved.',
        ),
      );
      Navigator.pop(context, true);
    } on AuthException catch (error) {
      _showError(error.message);
    } on PostgrestException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Profile could not be saved. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppTheme.terracotta,
      content: Text(message, style: const TextStyle(color: Colors.white)),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: FutureBuilder<void>(
          future: _profile,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Profile could not be loaded.'));
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
              child: Form(
                key: _formKey,
                child: Column(children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: AppTheme.sage,
                    foregroundColor: Colors.white,
                    child: Text(_initials(_name.text),
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                      'Profile photo will be available in a future update.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppTheme.sage)),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter your name.'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        const InputDecoration(labelText: 'Email address'),
                    validator: (value) => value == null || !value.contains('@')
                        ? 'Enter a valid email address.'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration:
                        const InputDecoration(labelText: 'Phone number'),
                  ),
                  const SizedBox(height: 18),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date of birth'),
                    subtitle: Text(_birthDate == null
                        ? 'Not provided'
                        : _date(_birthDate!)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        initialDate: _birthDate ?? DateTime(2000),
                      );
                      if (date != null) setState(() => _birthDate = date);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: const [
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(
                          value: 'non_binary', child: Text('Non-binary')),
                      DropdownMenuItem(
                          value: 'prefer_not_to_say',
                          child: Text('Prefer not to say')),
                    ],
                    onChanged: (value) => setState(() => _gender = value),
                  ),
                  const SizedBox(height: 30),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving…' : 'Save profile'),
                  ),
                ]),
              ),
            );
          },
        ),
      );

  String _initials(String name) {
    final words =
        name.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    final value = words.take(2).map((word) => word[0]).join();
    return value.isEmpty ? '?' : value.toUpperCase();
  }

  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}.'
      '${value.month.toString().padLeft(2, '0')}.${value.year}';
}

class ProfileFailure implements Exception {
  const ProfileFailure(this.message);
  final String message;
}
