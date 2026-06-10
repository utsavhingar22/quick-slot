class Venue {
  final int id;
  final String name;
  final String sport;
  final String location;
  final String? description;

  const Venue({
    required this.id,
    required this.name,
    required this.sport,
    required this.location,
    this.description,
  });

  factory Venue.fromJson(Map<String, dynamic> j) => Venue(
        id: j['id'],
        name: j['name'],
        sport: j['sport'],
        location: j['location'],
        description: j['description'],
      );

  String get emoji => sport == 'badminton' ? '🏸' : '⚽';
}

class Slot {
  final int id;
  final int venueId;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final String? bookedBy;
  final int? bookingId;

  const Slot({
    required this.id,
    required this.venueId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.bookedBy,
    this.bookingId,
  });

  bool get isAvailable => status == 'available';

  factory Slot.fromJson(Map<String, dynamic> j) => Slot(
        id: j['id'],
        venueId: j['venue_id'],
        date: j['date'] as String,
        startTime: (j['start_time'] as String).substring(0, 5),
        endTime: (j['end_time'] as String).substring(0, 5),
        status: j['status'],
        bookedBy: j['booked_by'],
        bookingId: j['booking_id'],
      );

  String get timeLabel => '$startTime – $endTime';
}

class Booking {
  final int bookingId;
  final String bookedAt;
  final String userId;
  final int slotId;
  final String date;
  final String startTime;
  final String endTime;
  final int venueId;
  final String venueName;
  final String sport;
  final String location;

  const Booking({
    required this.bookingId,
    required this.bookedAt,
    required this.userId,
    required this.slotId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.venueId,
    required this.venueName,
    required this.sport,
    required this.location,
  });

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        bookingId: j['booking_id'],
        bookedAt: j['booked_at'],
        userId: j['user_id'],
        slotId: j['slot_id'],
        date: j['date'] as String,
        startTime: (j['start_time'] as String).substring(0, 5),
        endTime: (j['end_time'] as String).substring(0, 5),
        venueId: j['venue_id'],
        venueName: j['venue_name'],
        sport: j['sport'],
        location: j['location'],
      );

  String get timeLabel => '$startTime – $endTime';
  String get emoji => sport == 'badminton' ? '🏸' : '⚽';
}

class AppUser {
  final String id;
  final String name;
  final String email;

  const AppUser({required this.id, required this.name, required this.email});

  static const List<AppUser> all = [
    AppUser(id: 'user_001', name: 'Akriti', email: 'akriti@quickslot.com'),
    AppUser(id: 'user_002', name: 'Utsav', email: 'utsav@quickslot.com'),
    AppUser(id: 'user_003', name: 'Rahul', email: 'rahul@quickslot.com'),
  ];
}
