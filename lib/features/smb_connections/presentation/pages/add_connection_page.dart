import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/smb_connection.dart';
import '../controllers/smb_controller.dart';

class AddConnectionPage extends ConsumerStatefulWidget {
  const AddConnectionPage({super.key, this.initialConnection});

  final SmbConnection? initialConnection;

  @override
  ConsumerState<AddConnectionPage> createState() => _AddConnectionPageState();
}

class _AddConnectionPageState extends ConsumerState<AddConnectionPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _sharedPathController;

  @override
  void initState() {
    super.initState();

    final SmbConnection? connection = widget.initialConnection;

    _nameController = TextEditingController(text: connection?.name ?? '');
    _hostController = TextEditingController(text: connection?.host ?? '');
    _portController = TextEditingController(text: '${connection?.port ?? 445}');
    _usernameController =
        TextEditingController(text: connection?.username ?? '');
    _passwordController = TextEditingController();
    _sharedPathController =
        TextEditingController(text: connection?.sharedPath ?? '/');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _sharedPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.initialConnection != null;

    return Scaffold(
      appBar:
          AppBar(title: Text(isEditing ? 'Edit Connection' : 'Add Connection')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'SMB Server Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Connection name'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hostController,
                decoration:
                    const InputDecoration(labelText: 'Host / IP address'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _portController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Port'),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final int? parsed = int.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Invalid port';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: isEditing ? 'New password (optional)' : 'Password',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sharedPathController,
                decoration: const InputDecoration(labelText: 'Shared path'),
                validator: _required,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _onSubmit,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save Connection'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final SmbConnection connection = SmbConnection(
      id: widget.initialConnection?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ?? 445,
      username: _usernameController.text.trim(),
      sharedPath: _sharedPathController.text.trim(),
    );

    await ref.read(smbControllerProvider.notifier).saveConnection(
          connection,
          password: _passwordController.text.trim(),
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
