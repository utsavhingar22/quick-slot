import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(userBookingsProvider);
    final cancelState = ref.watch(cancelProvider);

    final titleText =
        bookingsAsync.whenData((b) => b.length).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText != null
            ? 'My Bookings ($titleText)'
            : 'My Bookings'),
      ),
      body: Stack(children: [
        bookingsAsync.when(
          loading: () =>
              const ShimmerList(count: 4, itemHeight: 120),
          error: (err, _) => ErrorState(
            message: err.toString(),
            onRetry: () => ref.invalidate(userBookingsProvider),
          ),
          data: (bookings) {
            if (bookings.isEmpty) {
              return const EmptyState(
                message: "You haven't booked any slots yet",
                icon: Icons.sports_outlined,
              );
            }

            final today =
                DateFormat('yyyy-MM-dd').format(DateTime.now());
            final upcoming = bookings
                .where((b) => b.date.compareTo(today) >= 0)
                .toList();
            final past = bookings
                .where((b) => b.date.compareTo(today) < 0)
                .toList();

            return RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(userBookingsProvider),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 12),
                children: [
                  if (upcoming.isNotEmpty) ...[
                    ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      title: Text('UPCOMING',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: Colors.grey[500])),
                    ),
                    ...upcoming.map((b) => _BookingCard(
                        booking: b,
                        isPast: false,
                        cancelState: cancelState,
                        onCancel: () =>
                            _confirmCancel(context, ref, b.bookingId))),
                  ],
                  if (past.isNotEmpty) ...[
                    ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      title: Text('PAST',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: Colors.grey[500])),
                    ),
                    ...past.map((b) => _BookingCard(
                        booking: b,
                        isPast: true,
                        cancelState: cancelState,
                        onCancel: () {})),
                  ],
                ],
              ),
            );
          },
        ),
        if (cancelState.isLoading)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ]),
    );
  }

  Future<void> _confirmCancel(
      BuildContext context, WidgetRef ref, int bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('This will free up the slot for others.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep it')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final ok =
        await ref.read(cancelProvider.notifier).cancel(bookingId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(ok ? '✅ Booking cancelled' : '❌ Failed to cancel'),
        backgroundColor: ok ? Colors.green[700] : Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isPast;
  final AsyncValue<void> cancelState;
  final VoidCallback onCancel;

  const _BookingCard({
    required this.booking,
    required this.isPast,
    required this.cancelState,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('EEE, dd MMM yyyy')
        .format(DateTime.parse(booking.date));

    final card = Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
                child: Text(booking.emoji,
                    style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.venueName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('$dateFormatted  ·  ${booking.timeLabel}',
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(booking.location,
                      style: TextStyle(
                          color: Colors.grey[500], fontSize: 12)),
                  if (isPast) ...[
                    const SizedBox(height: 4),
                    Text('Completed',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[400])),
                  ],
                ]),
          ),
          if (isPast)
            const SizedBox.shrink()
          else
            IconButton(
              icon:
                  const Icon(Icons.cancel_outlined, color: Colors.red),
              tooltip: 'Cancel',
              onPressed: cancelState.isLoading ? null : onCancel,
            ),
        ]),
      ),
    );

    return isPast ? Opacity(opacity: 0.5, child: card) : card;
  }
}
