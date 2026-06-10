import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../home/home_screen.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚡ QuickSlot',
                  style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B5E20))),
              const SizedBox(height: 8),
              Text('Book sports slots instantly.',
                  style: TextStyle(fontSize: 20, color: Colors.grey[600])),
              const SizedBox(height: 48),
              Text('SELECT ACCOUNT',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[500],
                      letterSpacing: 1.2)),
              const SizedBox(height: 12),
              ...AppUser.all.map((user) => _UserCard(user: user)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  final AppUser user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = [
      const Color(0xFF1B5E20),
      const Color(0xFF1565C0),
      const Color(0xFF6A1B9A)
    ];
    final idx = AppUser.all.indexOf(user);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colors[idx],
          child: Text(user.name[0],
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(user.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(user.email,
            style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          ref.read(currentUserProvider.notifier).select(user);
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()));
        },
      ),
    );
  }
}
