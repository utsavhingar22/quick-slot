import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';
import 'booking_success_screen.dart';

class VenueDetailScreen extends ConsumerStatefulWidget {
  final Venue venue;
  const VenueDetailScreen({super.key, required this.venue});

  @override
  ConsumerState<VenueDetailScreen> createState() =>
      _VenueDetailScreenState();
}

class _VenueDetailScreenState extends ConsumerState<VenueDetailScreen> {
  Timer? _pollingTimer;
  Timer? _countdownTimer;
  int _secondsSinceRefresh = 0;

  @override
  void initState() {
    super.initState();
    _pollingTimer =
        Timer.periodic(const Duration(seconds: 8), (_) {
      final selectedDate =
          ref.read(selectedDateProvider(widget.venue.id));
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      ref.invalidate(
          slotsProvider((venueId: widget.venue.id, date: dateStr)));
      if (mounted) setState(() => _secondsSinceRefresh = 0);
    });
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _secondsSinceRefresh++);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final venue = widget.venue;
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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${venue.emoji} ${venue.name}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(venue.location,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13)),
            if (venue.description != null) ...[
              const SizedBox(height: 4),
              Text(venue.description!,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12)),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate:
                      DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) {
                  ref
                      .read(selectedDateProvider(venue.id).notifier)
                      .state = picked;
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
            _LegendDot(
                color: const Color(0xFFC8E6C9), label: 'Available'),
            const SizedBox(width: 16),
            _LegendDot(
                color: const Color(0xFFEF9A9A), label: 'Booked'),
          ]),
        ),
        const SizedBox(height: 8),

        // Time-of-day filter chips
        SizedBox(
          height: 40,
          child: Builder(builder: (context) {
            final filter = ref.watch(slotFilterProvider(venue.id));
            return ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12),
              children:
                  ['All', 'Morning', 'Afternoon', 'Evening'].map((label) {
                final selected = filter == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selected
                              ? Colors.white
                              : Colors.grey[600],
                        )),
                    selected: selected,
                    onSelected: (_) => ref
                        .read(slotFilterProvider(venue.id).notifier)
                        .state = label,
                    selectedColor: const Color(0xFF1B5E20),
                    backgroundColor: Colors.grey[100],
                    showCheckmark: false,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }).toList(),
            );
          }),
        ),
        const SizedBox(height: 4),

        // Auto-refresh countdown indicator
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                    color: Colors.green[400],
                    shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                _secondsSinceRefresh == 0
                    ? 'Just refreshed'
                    : 'Refreshing in ${8 - _secondsSinceRefresh.clamp(0, 7)}s',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ),

        // Slots grid
        Expanded(
          child: slotsAsync.when(
            loading: () =>
                const ShimmerList(count: 6, itemHeight: 60),
            error: (err, _) => ErrorState(
              message: err.toString(),
              onRetry: () => ref.invalidate(
                  slotsProvider(
                      (venueId: venue.id, date: dateStr))),
            ),
            data: (slots) {
              if (slots.isEmpty) {
                return const EmptyState(
                    message: 'No slots available for this date');
              }
              final filter =
                  ref.watch(slotFilterProvider(venue.id));
              final List<Slot> filteredSlots = switch (filter) {
                'Morning' => slots
                    .where((s) =>
                        int.parse(s.startTime.split(':')[0]) < 12)
                    .toList(),
                'Afternoon' => slots.where((s) {
                    final h =
                        int.parse(s.startTime.split(':')[0]);
                    return h >= 12 && h < 18;
                  }).toList(),
                'Evening' => slots
                    .where((s) =>
                        int.parse(s.startTime.split(':')[0]) >= 18)
                    .toList(),
                _ => slots,
              };
              if (filteredSlots.isEmpty) {
                return const EmptyState(
                    message: 'No slots in this time range',
                    icon: Icons.schedule_outlined);
              }
              final availableCount =
                  filteredSlots.where((s) => s.isAvailable).length;
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(slotsProvider(
                    (venueId: venue.id, date: dateStr))),
                child: Column(children: [
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: availableCount == 0
                              ? Colors.red
                              : availableCount <= 3
                                  ? Colors.amber
                                  : Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        availableCount == 0
                            ? 'Fully booked for this date'
                            : availableCount <= 3
                                ? '⚡ Only $availableCount slots left!'
                                : '$availableCount slots available',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: availableCount == 0
                              ? Colors.red
                              : availableCount <= 3
                                  ? Colors.amber[800]
                                  : Colors.green[700],
                        ),
                      ),
                    ]),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          16, 0, 16, 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 2,
                      ),
                      itemCount: filteredSlots.length,
                      itemBuilder: (_, i) => _SlotChip(
                        slot: filteredSlots[i],
                        venue: venue,
                        date: dateStr,
                      ),
                    ),
                  ),
                ]),
              );
            },
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
                  Text('✓ You',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue[800])),
              ]),
        ),
      ),
    );
  }

  Future<void> _confirmBooking(
      BuildContext context, WidgetRef ref) async {
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
      builder: (_) =>
          const Center(child: CircularProgressIndicator()),
    );

    final errorMsg =
        await ref.read(bookingProvider.notifier).book(slot.id);

    if (!context.mounted) return;
    Navigator.pop(context); // close loading

    if (errorMsg == null) {
      ref.invalidate(
          slotsProvider((venueId: venue.id, date: date)));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSuccessScreen(
            venueName: venue.name,
            date: date,
            timeLabel: slot.timeLabel,
            sport: venue.sport,
          ),
        ),
      );
    } else {
      ref.invalidate(
          slotsProvider((venueId: venue.id, date: date)));
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
              color: color,
              borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(label,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ]);
  }
}
