import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((_) => ApiService());

// Current user
class CurrentUserNotifier extends Notifier<AppUser> {
  @override
  AppUser build() => AppUser.all.first;

  void select(AppUser user) {
    ref.read(apiServiceProvider).setUserId(user.id);
    state = user;
  }
}

final currentUserProvider =
    NotifierProvider<CurrentUserNotifier, AppUser>(CurrentUserNotifier.new);

// Venues
final venuesProvider = FutureProvider<List<Venue>>(
    (ref) => ref.read(apiServiceProvider).getVenues());

// Slots — keyed by (venueId, date) record; each pair is its own cache entry
final slotsProvider =
    FutureProvider.family<List<Slot>, ({int venueId, String date})>(
  (ref, args) =>
      ref.read(apiServiceProvider).getSlots(args.venueId, args.date),
);

// Selected date per venue
final selectedDateProvider = StateProvider.family<DateTime, int>(
  (_, __) => DateTime.now(),
);

// Booking action
class BookingNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String?> book(int slotId) async {
    state = const AsyncLoading();
    try {
      await ref.read(apiServiceProvider).bookSlot(slotId);
      state = const AsyncData(null);
      return null;
    } on ApiException catch (e) {
      state = AsyncError(e, StackTrace.current);
      return e.message;
    }
  }
}

final bookingProvider =
    AsyncNotifierProvider<BookingNotifier, void>(BookingNotifier.new);

// User bookings
final userBookingsProvider = FutureProvider<List<Booking>>((ref) {
  final user = ref.watch(currentUserProvider);
  return ref.read(apiServiceProvider).getUserBookings(user.id);
});

// Cancel booking
class CancelNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> cancel(int bookingId) async {
    state = const AsyncLoading();
    try {
      await ref.read(apiServiceProvider).cancelBooking(bookingId);
      state = const AsyncData(null);
      ref.invalidate(userBookingsProvider);
      return true;
    } on ApiException catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
}

final cancelProvider =
    AsyncNotifierProvider<CancelNotifier, void>(CancelNotifier.new);

// Time-of-day slot filter per venue
final slotFilterProvider = StateProvider.family<String, int>(
  (ref, venueId) => 'All',
);
