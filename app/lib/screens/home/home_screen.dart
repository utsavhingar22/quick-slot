import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import '../venue/venue_detail_screen.dart';
import '../bookings/my_bookings_screen.dart';
import '../login/login_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(venuesProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('⚡ QuickSlot',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MyBookingsScreen())),
          ),
          GestureDetector(
            onTap: () => _showMenu(context, ref, user),
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: Colors.white24,
                child: Text(user.name[0],
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('Hey ${user.name}! 👋',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: venuesAsync.when(
              loading: () => const ShimmerList(count: 5),
              error: (err, _) => ErrorState(
                message: err.toString(),
                onRetry: () => ref.invalidate(venuesProvider),
              ),
              data: (venues) => venues.isEmpty
                  ? const EmptyState(
                      message: 'No venues available',
                      icon: Icons.sports)
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(venuesProvider),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: venues.length,
                        itemBuilder: (_, i) => _VenueCard(venue: venues[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref, AppUser user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(user.name,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16)),
          Text(user.email,
              style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.switch_account),
              label: const Text('Switch Account'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  final Venue venue;
  const _VenueCard({required this.venue});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => VenueDetailScreen(venue: venue))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: venue.sport == 'badminton'
                    ? const Color(0xFFE3F2FD)
                    : const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                  child: Text(venue.emoji,
                      style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(venue.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 3),
                    Row(children: [
                      Icon(Icons.location_on_outlined,
                          size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 2),
                      Expanded(
                          child: Text(venue.location,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                              overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 6),
                    SportBadge(sport: venue.sport),
                  ]),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ]),
        ),
      ),
    );
  }
}
