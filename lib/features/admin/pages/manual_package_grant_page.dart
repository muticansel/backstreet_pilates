import 'package:flutter/material.dart';

import '../data/admin_dashboard_data.dart';

class ManualPackageGrantPage extends StatefulWidget {
  const ManualPackageGrantPage({super.key, required this.members});

  final List<ActiveMember> members;

  @override
  State<ManualPackageGrantPage> createState() => _ManualPackageGrantPageState();
}

class _ManualPackageGrantPageState extends State<ManualPackageGrantPage> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  String? _member;
  String? _package;

  static const _packages = [
    '8 class package · Oran',
    '8 class package · İncek',
    '12 class package · Oran',
    '12 class package · İncek',
  ];

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Preview only — no package or payment has been recorded.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record a cash payment')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'This form will create a payment record and give the selected member a package. It is a visual preview for now.',
                ),
                const SizedBox(height: 28),
                DropdownButtonFormField<String>(
                  initialValue: _member,
                  decoration: const InputDecoration(labelText: 'Member'),
                  items: widget.members
                      .map((member) => DropdownMenuItem(
                            value: member.name,
                            child: Text(member.name),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _member = value),
                  validator: (value) =>
                      value == null ? 'Select a member.' : null,
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: _package,
                  decoration: const InputDecoration(labelText: 'Package'),
                  items: _packages
                      .map((name) =>
                          DropdownMenuItem(value: name, child: Text(name)))
                      .toList(),
                  onChanged: (value) => setState(() => _package = value),
                  validator: (value) =>
                      value == null ? 'Select a package.' : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _amount,
                  decoration: const InputDecoration(
                    labelText: 'Amount received (TRY)',
                    prefixText: '₺ ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    final amount =
                        double.tryParse(value?.replaceAll(',', '.') ?? '');
                    return amount == null || amount <= 0
                        ? 'Enter the amount received.'
                        : null;
                  },
                ),
                const SizedBox(height: 18),
                TextFormField(
                  initialValue: 'Cash',
                  readOnly: true,
                  decoration: InputDecoration(labelText: 'Payment method'),
                ),
                const SizedBox(height: 30),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Record payment and grant package'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
