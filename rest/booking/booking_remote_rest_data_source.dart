import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/core/error/exceptions.dart';
import 'package:myapp/core/utils/logger.dart';
import 'package:myapp/features/booking/data/models/booking_model.dart';
import '../shared/rest_base_data_source.dart';
import '../shared/rest_response_model.dart';
import '../shared/api_config.dart';

abstract class BookingRemoteRestDataSource {
  Stream<List<BookingModel>> getBookings(String userId);
  Stream<List<BookingModel>> getBookingsByInstructor(String instructorId);
  Stream<List<BookingModel>> getBookingsByClient(String clientId);
  Future<BookingModel> getBooking(String id);
  Future<BookingModel> createBooking(BookingModel booking);
  Future<BookingModel> updateBooking(BookingModel booking);
  Future<void> deleteBooking(String id);
  Future<BookingModel> cancelBooking(String id);
  Future<BookingModel> confirmBooking(String id);
  
  // Additional REST-specific methods
  Future<List<BookingModel>> searchBookings({
    String? query,
    String? instructorId,
    String? clientId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  });
  
  Future<List<BookingModel>> getBookingsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? instructorId,
    String? clientId,
  });
  
  Future<Map<String, int>> getBookingStats(String userId);
}

class BookingRemoteRestDataSourceImpl extends RestBaseDataSource implements BookingRemoteRestDataSource {
  BookingRemoteRestDataSourceImpl({
    required http.Client httpClient,
    required FirebaseAuth firebaseAuth,
    required String baseUrl,
    Duration timeout = const Duration(seconds: 30),
  }) : super(
         httpClient: httpClient,
         firebaseAuth: firebaseAuth,
         baseUrl: baseUrl,
         timeout: timeout,
       );

  @override
  Stream<List<BookingModel>> getBookings(String userId) {
    return createStreamFromFuture(() => _fetchBookings(userId));
  }

  @override
  Stream<List<BookingModel>> getBookingsByInstructor(String instructorId) {
    return createStreamFromFuture(() => _fetchBookingsByInstructor(instructorId));
  }

  @override
  Stream<List<BookingModel>> getBookingsByClient(String clientId) {
    return createStreamFromFuture(() => _fetchBookingsByClient(clientId));
  }

  @override
  Future<BookingModel> getBooking(String id) async {
    try {
      AppLogger.info('🔍 Fetching booking: $id');
      
      final response = await get('/bookings/$id');
      
      AppLogger.info('✅ Booking fetched successfully');
      return BookingModel.fromMap(response['data']);
    } catch (e) {
      AppLogger.error('❌ Error fetching booking: $e');
      if (e is NotFoundException) {
        throw ServerException('Booking not found');
      }
      rethrow;
    }
  }

  @override
  Future<BookingModel> createBooking(BookingModel booking) async {
    try {
      AppLogger.info('➕ Creating booking for client: ${booking.clientId}');
      
      final response = await post(
        '/bookings',
        body: booking.toMap(),
      );
      
      AppLogger.info('✅ Booking created successfully');
      return BookingModel.fromMap(response['data']);
    } catch (e) {
      AppLogger.error('❌ Error creating booking: $e');
      if (e is ValidationException) {
        throw ServerException('Invalid booking data: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<BookingModel> updateBooking(BookingModel booking) async {
    try {
      AppLogger.info('✏️ Updating booking: ${booking.id}');
      
      final response = await put(
        '/bookings/${booking.id}',
        body: booking.toMap(),
      );
      
      AppLogger.info('✅ Booking updated successfully');
      return BookingModel.fromMap(response['data']);
    } catch (e) {
      AppLogger.error('❌ Error updating booking: $e');
      if (e is NotFoundException) {
        throw ServerException('Booking not found');
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteBooking(String id) async {
    try {
      AppLogger.info('🗑️ Deleting booking: $id');
      
      await delete('/bookings/$id');
      
      AppLogger.info('✅ Booking deleted successfully');
    } catch (e) {
      AppLogger.error('❌ Error deleting booking: $e');
      if (e is NotFoundException) {
        throw ServerException('Booking not found');
      }
      rethrow;
    }
  }

  @override
  Future<BookingModel> cancelBooking(String id) async {
    try {
      AppLogger.info('❌ Cancelling booking: $id');
      
      final response = await put(
        '/bookings/$id/cancel',
        body: {'status': 'cancelled'},
      );
      
      AppLogger.info('✅ Booking cancelled successfully');
      return BookingModel.fromMap(response['data']);
    } catch (e) {
      AppLogger.error('❌ Error cancelling booking: $e');
      if (e is NotFoundException) {
        throw ServerException('Booking not found');
      }
      if (e is ConflictException) {
        throw ServerException('Cannot cancel booking: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<BookingModel> confirmBooking(String id) async {
    try {
      AppLogger.info('✅ Confirming booking: $id');
      
      final response = await put(
        '/bookings/$id/confirm',
        body: {'status': 'confirmed'},
      );
      
      AppLogger.info('✅ Booking confirmed successfully');
      return BookingModel.fromMap(response['data']);
    } catch (e) {
      AppLogger.error('❌ Error confirming booking: $e');
      if (e is NotFoundException) {
        throw ServerException('Booking not found');
      }
      if (e is ConflictException) {
        throw ServerException('Cannot confirm booking: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<List<BookingModel>> searchBookings({
    String? query,
    String? instructorId,
    String? clientId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      AppLogger.info('🔍 Searching bookings');
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }
      if (instructorId != null) {
        queryParams['instructorId'] = instructorId;
      }
      if (clientId != null) {
        queryParams['clientId'] = clientId;
      }
      if (status != null) {
        queryParams['status'] = status;
      }
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      
      final response = await get('/bookings/search', queryParams: queryParams);
      
      AppLogger.info('✅ Search completed successfully');
      return (response['data'] as List)
          .map((item) => BookingModel.fromMap(item))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error searching bookings: $e');
      rethrow;
    }
  }

  @override
  Future<List<BookingModel>> getBookingsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? instructorId,
    String? clientId,
  }) async {
    try {
      AppLogger.info('📅 Fetching bookings by date range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
      
      final queryParams = <String, String>{
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };
      
      if (instructorId != null) {
        queryParams['instructorId'] = instructorId;
      }
      if (clientId != null) {
        queryParams['clientId'] = clientId;
      }
      
      final response = await get('/bookings/date-range', queryParams: queryParams);
      
      AppLogger.info('✅ Date range bookings fetched successfully');
      return (response['data'] as List)
          .map((item) => BookingModel.fromMap(item))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error fetching bookings by date range: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, int>> getBookingStats(String userId) async {
    try {
      AppLogger.info('📊 Fetching booking stats for user: $userId');
      
      final response = await get('/bookings/stats/$userId');
      
      AppLogger.info('✅ Booking stats fetched successfully');
      return Map<String, int>.from(response['data']);
    } catch (e) {
      AppLogger.error('❌ Error fetching booking stats: $e');
      rethrow;
    }
  }

  // Private helper methods

  Future<List<BookingModel>> _fetchBookings(String userId) async {
    try {
      AppLogger.info('🔍 Fetching bookings for user: $userId');
      
      final response = await get('/bookings', queryParams: {'userId': userId});
      
      AppLogger.info('✅ Bookings fetched successfully');
      return (response['data'] as List)
          .map((item) => BookingModel.fromMap(item))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error fetching bookings: $e');
      rethrow;
    }
  }

  Future<List<BookingModel>> _fetchBookingsByInstructor(String instructorId) async {
    try {
      AppLogger.info('🔍 Fetching bookings for instructor: $instructorId');
      
      final response = await get('/bookings', queryParams: {'instructorId': instructorId});
      
      AppLogger.info('✅ Instructor bookings fetched successfully');
      return (response['data'] as List)
          .map((item) => BookingModel.fromMap(item))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error fetching instructor bookings: $e');
      rethrow;
    }
  }

  Future<List<BookingModel>> _fetchBookingsByClient(String clientId) async {
    try {
      AppLogger.info('🔍 Fetching bookings for client: $clientId');
      
      final response = await get('/bookings', queryParams: {'clientId': clientId});
      
      AppLogger.info('✅ Client bookings fetched successfully');
      return (response['data'] as List)
          .map((item) => BookingModel.fromMap(item))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error fetching client bookings: $e');
      rethrow;
    }
  }

  /// Get bookings with advanced filtering
  Future<List<BookingModel>> getBookingsWithFilters({
    String? instructorId,
    String? clientId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy = 'startTime',
    String? sortOrder = 'asc',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      AppLogger.info('🔍 Fetching bookings with filters');
      
      final queryParams = buildPaginationParams(
        page: page,
        limit: limit,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
      
      if (instructorId != null) {
        queryParams['instructorId'] = instructorId;
      }
      if (clientId != null) {
        queryParams['clientId'] = clientId;
      }
      if (status != null) {
        queryParams['status'] = status;
      }
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      
      final response = await get('/bookings', queryParams: queryParams);
      
      AppLogger.info('✅ Filtered bookings fetched successfully');
      return (response['data'] as List)
          .map((item) => BookingModel.fromMap(item))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error fetching filtered bookings: $e');
      rethrow;
    }
  }

  /// Get booking availability for a specific time range
  Future<List<Map<String, dynamic>>> getBookingAvailability({
    required String instructorId,
    required DateTime startDate,
    required DateTime endDate,
    String? sessionTypeId,
    String? locationId,
  }) async {
    try {
      AppLogger.info('🔍 Checking booking availability');
      
      final queryParams = <String, String>{
        'instructorId': instructorId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };
      
      if (sessionTypeId != null) {
        queryParams['sessionTypeId'] = sessionTypeId;
      }
      if (locationId != null) {
        queryParams['locationId'] = locationId;
      }
      
      final response = await get('/bookings/availability', queryParams: queryParams);
      
      AppLogger.info('✅ Availability checked successfully');
      return List<Map<String, dynamic>>.from(response['data']);
    } catch (e) {
      AppLogger.error('❌ Error checking availability: $e');
      rethrow;
    }
  }

  /// Reschedule a booking
  Future<BookingModel> rescheduleBooking({
    required String bookingId,
    required DateTime newStartTime,
    required DateTime newEndTime,
    String? reason,
  }) async {
    try {
      AppLogger.info('🔄 Rescheduling booking: $bookingId');
      
      final response = await put(
        '/bookings/$bookingId/reschedule',
        body: {
          'newStartTime': newStartTime.toIso8601String(),
          'newEndTime': newEndTime.toIso8601String(),
          if (reason != null) 'reason': reason,
        },
      );
      
      AppLogger.info('✅ Booking rescheduled successfully');
      return BookingModel.fromMap(response['data']);
    } catch (e) {
      AppLogger.error('❌ Error rescheduling booking: $e');
      if (e is NotFoundException) {
        throw ServerException('Booking not found');
      }
      if (e is ConflictException) {
        throw ServerException('Cannot reschedule booking: ${e.message}');
      }
      rethrow;
    }
  }

  /// Get booking history for a user
  Future<List<BookingModel>> getBookingHistory({
    required String userId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      AppLogger.info('📚 Fetching booking history for user: $userId');
      
      final queryParams = buildPaginationParams(page: page, limit: limit);
      
      if (status != null) {
        queryParams['status'] = status;
      }
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      
      final response = await get('/bookings/history/$userId', queryParams: queryParams);
      
      AppLogger.info('✅ Booking history fetched successfully');
      return (response['data'] as List)
          .map((item) => BookingModel.fromMap(item))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error fetching booking history: $e');
      rethrow;
    }
  }
}
