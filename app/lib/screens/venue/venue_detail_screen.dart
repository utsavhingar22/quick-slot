import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class VenueDetailScreen extends ConsumerWidget {
  final Venue venue;
  const VenueDetailScreen({super.key, required this.venue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider(venue.id));
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final slotsAsync =
        ref.watch(slotsProvider((venueId: venue.id, date: dateStr)));

    return Scaffold(
      appBar: AppBar(title: Text(venue.name)),
      body: Column(children: [
        // Venue info header
        Container(
          width: double.infinity,
          color: const Color(0xFF1B5E20),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${venue.emoji} ${venue.name}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(venue.location,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            if (venue.description != null) ...[
              const SizedBox(height: 4),
              Text(venue.description!,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ]),
        ),

        // Date picker row
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Icon(Icons.calendar_today,
                size: 18, color: Color(0xFF1B5E20)),
            const SizedBox(width: 8),
            Text(DateFormat('EEE, dd MMM yyyy').format(selectedDate),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            const Spacer(),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1B5E20)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) {
                  ref.read(selectedDateProvider(venue.id).notifier).state =
                      picked;
                }
              },
              child: const Text('Change',
                  style: TextStyle(color: Color(0xFF1B5E20))),
            ),
          ]),
        ),

        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _LegendDot(color: const Color(0xFFC8E6C9), label: 'Available'),
            const SizedBox(width: 16),
            _LegendDot(color: const Color(0xFFEF9A9A), label: 'Booked'),
          ]),
        ),
        const SizedBox(height: 12),

        // Slots grid
        Expanded(
          child: slotsAsync.when(
            loading: () => const ShimmerList(count: 6, itemHeight: 60),
            error: (err, _) => ErrorState(
              message: err.toString(),
              onRetry: () => ref.invalidate(
                  slotsProvider((venueId: venue.id, date: dateStr))),
            ),
            data: (slots) => slots.isEmpty
                ? const EmptyState(
                    message: 'No slots available for this date')
                : RefreshIndicator(
                    onRefresh: () async => ref.invalidate(
                        slotsProvider((venueId: venue.id, date: dateStr))),
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 2,
                      ),
                      itemCount: slots.length,
                      itemBuilder: (_, i) => _SlotChip(
                        slot: slots[i],
                        venue: venue,
                        date: dateStr,
                      ),
                    ),
                  ),
          ),
        ),
      ]),
    );
  }
}

class _SlotChip extends ConsumerWidget {
  final Slot slot;
  final Venue venue;
  final String date;
  const _SlotChip(
      {required this.slot, required this.venue, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBooked = !slot.isAvailable;
    final currentUser = ref.watch(currentUserProvider);
    final isMyBooking = slot.bookedBy == currentUser.id;

    return GestureDetector(
      onTap: isBooked ? null : () => _confirmBooking(context, ref),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isBooked
              ? (isMyBooking
                  ? const Color(0xFFBBDEFB)
                  : const Color(0xFFEF9A9A))
              : const Color(0xFFC8E6C9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isBooked
                ? (isMyBooking ? Colors.blue[300]! : Colors.red[300]!)
                : Colors.green[300]!,
          ),
        ),
        child: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slot.startTime,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isBooked
                        ? Colors.grey[700]
                        : const Color(0xFF1B5E20),
                  ),
                ),
                if (isMyBooking)
                  const Text('Mine',
                      style: TextStyle(fontSize: 9, color: Colors.blue)),
              ]),
        ),
      ),
    );
  }

  Future<void> _confirmBooking(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Venue: ${venue.name}'),
              Text('Time: ${slot.timeLabel}'),
              Text('Date: $date'),
            ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Book')),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final errorMsg = await ref.read(bookingProvider.notifier).book(slot.id);

    if (!context.mounted) return;
    Navigator.pop(context); // close loading

    if (errorMsg == null) {
      ref.invalidate(slotsProvider((venueId: venue.id, date: date)));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Slot booked successfully!'),
          backgroundColor: Color(0xFF1B5E20),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ref.invalidate(slotsProvider((venueId: venue.id, date: date)));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMsg'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(label,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ]);
  }
}
