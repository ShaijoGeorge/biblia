import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../providers/auth_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper to show a dialog with a text field
  Future<void> _showUpdateDialog({
    required String title,
    required String label,
    required TextEditingController controller,
    required Future<void> Function() onConfirm,
    bool isPassword = false,
  }) async {
    controller.clear();
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              try {
                await onConfirm();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$title Successful!')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                // Avatar
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
                // User Info
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

                // --- ACTION BUTTONS ---
                
                // Change Email Button
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Change Email'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showUpdateDialog(
                    title: 'Update Email',
                    label: 'New Email Address',
                    controller: _emailController,
                    onConfirm: () async {
                      final newEmail = _emailController.text.trim();
                      if (newEmail.isNotEmpty) {
                        await ref.read(authRepositoryProvider).updateEmail(newEmail);
                      }
                    },
                  ),
                ),
                const Divider(),

                // Change Password Button
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showUpdateDialog(
                    title: 'Update Password',
                    label: 'New Password',
                    isPassword: true,
                    controller: _passwordController,
                    onConfirm: () async {
                      final newPass = _passwordController.text.trim();
                      if (newPass.length >= 6) {
                        await ref.read(authRepositoryProvider).updatePassword(newPass);
                      } else {
                        throw "Password must be at least 6 characters";
                      }
                    },
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