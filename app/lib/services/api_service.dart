import 'package:dio/dio.dart';
import '../models/models.dart';
import '../utils/constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiService {
  late final Dio _dio;
  String _userId = 'user_001';

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['X-User-Id'] = _userId;
        handler.next(options);
      },
    ));
  }

  void setUserId(String id) => _userId = id;
  String get currentUserId => _userId;

  Future<List<Venue>> getVenues() async {
    final res = await _get('/venues');
    return (res['venues'] as List).map((e) => Venue.fromJson(e)).toList();
  }

  Future<List<Slot>> getSlots(int venueId, String date) async {
    final res = await _get('/venues/$venueId/slots', params: {'date': date});
    return (res['slots'] as List).map((e) => Slot.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> bookSlot(int slotId) async {
    return await _post('/bookings', body: {'slot_id': slotId});
  }

  Future<List<Booking>> getUserBookings(String userId) async {
    final res = await _get('/users/$userId/bookings');
    return (res['bookings'] as List).map((e) => Booking.fromJson(e)).toList();
  }

  Future<void> cancelBooking(int bookingId) async {
    await _delete('/bookings/$bookingId');
  }

  Future<Map<String, dynamic>> _get(String path, {Map<String, dynamic>? params}) async {
    try {
      final res = await _dio.get(path, queryParameters: params);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  Future<Map<String, dynamic>> _post(String path, {required Map<String, dynamic> body}) async {
    try {
      final res = await _dio.post(path, data: body);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  Future<void> _delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  ApiException _wrap(DioException e) {
    final data = e.response?.data;
    final msg = (data is Map ? data['message'] ?? data['error'] : null) as String?;
    if (msg != null) return ApiException(msg, statusCode: e.response?.statusCode);
    if (e.type == DioExceptionType.connectionError) return const ApiException('Cannot reach server');
    return ApiException('Something went wrong', statusCode: e.response?.statusCode);
  }
}
