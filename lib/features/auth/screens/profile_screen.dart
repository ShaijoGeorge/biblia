import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (user) {
        if (user == null) return const Scaffold(body: Center(child: Text('Not Logged In')));

        final name = user.userMetadata?['full_name'] ?? 'Reader';
        final email = user.email ?? 'No Email';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

        return Scaffold(
          appBar: AppBar(title: const Text('My Profile')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Gap(20),
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const Gap(24),
                Text(
                  name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Gap(8),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const Gap(40),

                // --- SECURE ACTION BUTTONS ---
                
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Change Email'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const _ChangeEmailDialog(),
                  ),
                ),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const _ChangePasswordDialog(),
                  ),
                ),
                const Divider(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- 1. CHANGE EMAIL DIALOG ---
class _ChangeEmailDialog extends ConsumerStatefulWidget {
  const _ChangeEmailDialog();

  @override
  ConsumerState<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends ConsumerState<_ChangeEmailDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isObscure = true;

  Future<void> _update() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@') || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid input")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      // 1. Verify Identity
      await repo.reauthenticate(pass);
      // 2. Update Email
      await repo.updateEmail(email);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Confirmation links sent to your old AND new email."),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Change Email"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: "New Email",
              prefixIcon: Icon(Icons.email),
            ),
          ),
          const Gap(16),
          TextField(
            controller: _passwordController,
            obscureText: _isObscure,
            decoration: InputDecoration(
              labelText: "Current Password",
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _isObscure = !_isObscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        FilledButton(
          onPressed: _isLoading ? null : _update,
          child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator()) : const Text("Update"),
        ),
      ],
    );
  }
}

// --- 2. CHANGE PASSWORD DIALOG  ---
class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  
  bool _isLoading = false;
  bool _obsOld = true;
  bool _obsNew = true;
  bool _obsConfirm = true;

  Future<void> _update() async {
    final oldPass = _oldPassController.text.trim();
    final newPass = _newPassController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("New password is too short")));
      return;
    }
    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      // 1. Verify Old Password
      await repo.reauthenticate(oldPass);
      // 2. Update to New Password
      await repo.updatePassword(newPass);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password updated successfully!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Change Password"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _oldPassController,
              obscureText: _obsOld,
              decoration: InputDecoration(
                labelText: "Current Password",
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obsOld ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obsOld = !_obsOld),
                ),
              ),
            ),
            const Gap(16),
            TextField(
              controller: _newPassController,
              obscureText: _obsNew,
              decoration: InputDecoration(
                labelText: "New Password",
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obsNew ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obsNew = !_obsNew),
                ),
              ),
            ),
            const Gap(16),
            TextField(
              controller: _confirmPassController,
              obscureText: _obsConfirm,
              decoration: InputDecoration(
                labelText: "Confirm New Password",
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obsConfirm ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obsConfirm = !_obsConfirm),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        FilledButton(
          onPressed: _isLoading ? null : _update,
          child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator()) : const Text("Update"),
        ),
      ],
    );
  }
}