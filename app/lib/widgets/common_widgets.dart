import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerList extends StatelessWidget {
  final int count;
  final double itemHeight;
  const ShimmerList({super.key, this.count = 4, this.itemHeight = 110});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: count,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: itemHeight,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ]),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyState(
      {super.key,
      required this.message,
      this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 56, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text(message, style: TextStyle(color: Colors.grey[600])),
      ]),
    );
  }
}

class SportBadge extends StatelessWidget {
  final String sport;
  const SportBadge({super.key, required this.sport});

  @override
  Widget build(BuildContext context) {
    final isBadminton = sport == 'badminton';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isBadminton
            ? const Color(0xFFE3F2FD)
            : const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isBadminton ? '🏸 Badminton' : '⚽ Turf',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isBadminton ? Colors.blue[700] : Colors.green[700],
        ),
      ),
    );
  }
}
