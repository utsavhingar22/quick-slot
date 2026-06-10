import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../bookings/my_bookings_screen.dart';

class BookingSuccessScreen extends StatelessWidget {
  final String venueName;
  final String date;
  final String timeLabel;
  final String sport;

  const BookingSuccessScreen({
    super.key,
    required this.venueName,
    required this.date,
    required this.timeLabel,
    required this.sport,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = sport == 'badminton' ? '🏸' : '⚽';
    final dateFormatted = DateFormat('EEE, dd MMM yyyy').format(DateTime.parse(date));

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 90, color: Color(0xFF1B5E20)),
                const SizedBox(height: 20),
                const Text('Slot Booked!',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B5E20))),
                const SizedBox(height: 8),
                Text('Your slot is confirmed',
                    style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                const SizedBox(height: 32),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(children: [
                      Text(emoji,
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(venueName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(dateFormatted,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600])),
                              const SizedBox(height: 2),
                              Text(timeLabel,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600])),
                            ]),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MyBookingsScreen()),
                      (route) => route.isFirst,
                    ),
                    child: const Text('View My Bookings'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1B5E20)),
                      foregroundColor: const Color(0xFF1B5E20),
                    ),
                    onPressed: () =>
                        Navigator.popUntil(context, (route) => route.isFirst),
                    child: const Text('Back to Venues'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
