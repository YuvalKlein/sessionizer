import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/core/error/exceptions.dart';
import 'package:myapp/core/utils/logger.dart';
import 'package:myapp/features/schedule/data/models/schedule_model.dart';
import '../shared/rest_base_data_source.dart';
import '../shared/rest_response_model.dart';
import '../shared/api_config.dart';

abstract class ScheduleRemoteRestDataSource {
  Stream<List<ScheduleModel>> getSchedules(String instructorId);
  Future<ScheduleModel?> getSchedule(String scheduleId);
  Future<ScheduleModel> createSchedule(ScheduleModel schedule);
  Future<ScheduleModel> updateSchedule(String scheduleId, Map<String, dynamic> data);
  Future<void> updateScheduleEntity(ScheduleModel schedule);
  Future<void> deleteSchedule(String scheduleId);
  Future<void> setDefaultSchedule(String instructorId, String scheduleId, bool isDefault);
  Future<void> unsetAllDefaultSchedules();
  
  // Additional REST-specific methods
  Future<List<ScheduleModel>> searchSchedules({
    String? query,
    String? instructorId,
    String? name,
    bool? isDefault,
    int page = 1,
    int limit = 20,
  });
  
  Future<ScheduleModel?> getDefaultSchedule(String instructorId);
  
  Future<Map<String, dynamic>> getScheduleStats(String instructorId);
  
  Future<List<ScheduleModel>> getSchedulesByDateRange({
    required String instructorId,
    required DateTime startDate,
    required DateTime endDate,
  });
}

class ScheduleRemoteRestDataSourceImpl extends RestBaseDataSource implements ScheduleRemoteRestDataSource {
  ScheduleRemoteRestDataSourceImpl({
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
  Stream<List<ScheduleModel>> getSchedules(String instructorId) {
    return createStreamFromFuture(() => _fetchSchedules(instructorId));
  }

  @override
  Future<ScheduleModel?> getSchedule(String scheduleId) async {
    try {
      AppLogger.info('🔍 Fetching schedule: $scheduleId');
      
      final response = await get('/schedules/$scheduleId');
      
      AppLogger.info('✅ Schedule fetched successfully');
      return ScheduleModel.fromMap(response['data']);
    } catch (e) {
      AppLogger.error('❌ Error fetching schedule: $e');
      if (e is NotFoundException) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<ScheduleModel> createSchedule(ScheduleModel schedule) async {
    try {
      AppLogger.info('➕ Creating schedule: ${schedule.name}');
      
      final response = await post(
        '/schedules',
        body: schedule.toMap(),
      );
      
      AppLogger.info('✅ Schedule created successfully');
      return ScheduleModel.fromMap(response['data']);
    } catch (e) {
      AppLogger.error('❌ Error creating schedule: $e');
      if (e is ValidationException) {
        throw ServerException('Invalid schedule data: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<ScheduleModel> updateSchedule(String scheduleId, Map<String, dynamic> data) async {
    try {
      AppLogger.info('✏️ Updating schedule: $scheduleId');
      
      final response = await put(
        '/schedules/$scheduleId',
        body: data,
      );
      
      AppLogger.info('✅ Schedule updated successfully');
      return ScheduleModel.fromMap(response['data']);
    } catch (e) {
      AppLogger.error('❌ Error updating schedule: $e');
      if (e is NotFoundException) {
        throw ServerException('Schedule not found');
      }
      rethrow;
    }
  }

  @override
  Future<void> updateScheduleEntity(ScheduleModel schedule) async {
    try {
      AppLogger.info('✏️ Updating schedule entity: ${schedule.id}');
      
      await put(
        '/schedules/${schedule.id}',
        body: schedule.toMap(),
      );
      
      AppLogger.info('✅ Schedule entity updated successfully');
    } catch (e) {
      AppLogger.error('❌ Error updating schedule entity: $e');
      if (e is NotFoundException) {
        throw ServerException('Schedule not found');
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      AppLogger.info('🗑️ Deleting schedule: $scheduleId');
      
      await delete('/schedules/$scheduleId');
      
      AppLogger.info('✅ Schedule deleted successfully');
    } catch (e) {
      AppLogger.error('❌ Error deleting schedule: $e');
      if (e is NotFoundException) {
        throw ServerException('Schedule not found');
      }
      rethrow;
    }
  }

  @override
  Future<void> setDefaultSchedule(String instructorId, String scheduleId, bool isDefault) async {
    try {
      AppLogger.info('⭐ Setting default schedule: $scheduleId (isDefault: $isDefault)');
      
      await put(
        '/schedules/$scheduleId/default',
        body: {
          'instructorId': instructorId,
          'isDefault': isDefault,
        },
      );
      
      AppLogger.info('✅ Default schedule set successfully');
    } catch (e) {
      AppLogger.error('❌ Error setting default schedule: $e');
      if (e is NotFoundException) {
        throw ServerException('Schedule not found');
      }
      if (e is ConflictException) {
        throw ServerException('Cannot set default schedule: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<void> unsetAllDefaultSchedules() async {
    try {
      AppLogger.info('🔄 Unsetting all default schedules');
      
      await put('/schedules/unset-defaults');
      
      AppLogger.info('✅ All default schedules unset successfully');
    } catch (e) {
      AppLogger.error('❌ Error unsetting default schedules: $e');
      rethrow;
    }
  }

  @override
  Future<List<ScheduleModel>> searchSchedules({
    String? query,
    String? instructorId,
    String? name,
    bool? isDefault,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      AppLogger.info('🔍 Searching schedules');
      
      final queryParams = buildPaginationParams(page: page, limit: limit);
      
      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }
      if (instructorId != null) {
        queryParams['instructorId'] = instructorId;
      }
      if (name != null) {
        queryParams['name'] = name;
      }
      if (isDefault != null) {
        queryParams['isDefault'] = isDefault.toString();
      }
      
      final response = await get('/schedules/search', queryParams: queryParams);
      
      AppLogger.info('✅ Search completed successfully');
      return (response['data'] as List)
          .map((item) => ScheduleModel.fromMap(item))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error searching schedules: $e');
      rethrow;
    }
  }

  @override
  Future<ScheduleModel?> getDefaultSchedule(String instructorId) async {
    try {
      AppLogger.info('⭐ Fetching default schedule for instructor: $instructorId');
      
      final response = await get('/schedules/default/$instructorId');
      
      AppLogger.info('✅ Default schedule fetched successfully');
      return ScheduleModel.fromMap(response['data']);
    } catch (e) {
      AppLogger.error('❌ Error fetching default schedule: $e');
      if (e is NotFoundException) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getScheduleStats(String instructorId) async {
    try {
      AppLogger.info('📊 Fetching schedule stats for instructor: $instructorId');
      
      final response = await get('/schedules/stats/$instructorId');
      
      AppLogger.info('✅ Schedule stats fetched successfully');
      return Map<String, dynamic>.from(response['data']);
    } catch (e) {
      AppLogger.error('❌ Error fetching schedule stats: $e');
      rethrow;
    }
  }

  @override
  Future<List<ScheduleModel>> getSchedulesByDateRange({
    required String instructorId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      AppLogger.info('📅 Fetching schedules by date range for instructor: $instructorId');
      
      final queryParams = {
        'instructorId': instructorId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };
      
      final response = await get('/schedules/date-range', queryParams: queryParams);
      
      AppLogger.info('✅ Date range schedules fetched successfully');
      return (response['data'] as List)
          .map((item) => ScheduleModel.fromMap(item))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error fetching schedules by date range: $e');
      rethrow;
    }
  }

  // Private helper methods

  Future<List<ScheduleModel>> _fetchSchedules(String instructorId) async {
    try {
      AppLogger.info('🔍 Fetching schedules for instructor: $instructorId');
      
      final response = await get('/schedules', queryParams: {'instructorId': instructorId});
      
      AppLogger.info('✅ Schedules fetched successfully');
      return (response['data'] as List)
          .map((item) => ScheduleModel.fromMap(item))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error fetching schedules: $e');
      rethrow;
    }
  }

  /// Get schedules with advanced filtering
  Future<List<ScheduleModel>> getSchedulesWithFilters({
    String? instructorId,
    String? name,
    bool? isDefault,
    String? sortBy = 'name',
    String? sortOrder = 'asc',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      AppLogger.info('🔍 Fetching schedules with filters');
      
      final queryParams = buildPaginationParams(
        page: page,
        limit: limit,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
      
      if (instructorId != null) {
        queryParams['instructorId'] = instructorId;
      }
      if (name != null) {
        queryParams['name'] = name;
      }
      if (isDefault != null) {
        queryParams['isDefault'] = isDefault.toString();
      }
      
      final response = await get('/schedules', queryParams: queryParams);
      
      AppLogger.info('✅ Filtered schedules fetched successfully');
      return (response['data'] as List)
          .map((item) => ScheduleModel.fromMap(item))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error fetching filtered schedules: $e');
      rethrow;
    }
  }

  /// Validate schedule data
  Future<bool> validateSchedule(ScheduleModel schedule) async {
    try {
      AppLogger.info('✅ Validating schedule data');
      
      final response = await post(
        '/schedules/validate',
        body: schedule.toMap(),
      );
      
      AppLogger.info('✅ Schedule validation completed');
      return response['data']['isValid'] ?? false;
    } catch (e) {
      AppLogger.error('❌ Error validating schedule: $e');
      return false;
    }
  }

  /// Duplicate a schedule
  Future<ScheduleModel> duplicateSchedule({
    required String scheduleId,
    required String newName,
  }) async {
    try {
      AppLogger.info('📋 Duplicating schedule: $scheduleId');
      
      final response = await post(
        '/schedules/$scheduleId/duplicate',
        body: {'name': newName},
      );
      
      AppLogger.info('✅ Schedule duplicated successfully');
      return ScheduleModel.fromMap(response['data']);
    } catch (e) {
      AppLogger.error('❌ Error duplicating schedule: $e');
      if (e is NotFoundException) {
        throw ServerException('Schedule not found');
      }
      rethrow;
    }
  }

  /// Get schedule availability
  Future<Map<String, dynamic>> getScheduleAvailability({
    required String scheduleId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      AppLogger.info('📅 Checking schedule availability: $scheduleId');
      
      final queryParams = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };
      
      final response = await get('/schedules/$scheduleId/availability', queryParams: queryParams);
      
      AppLogger.info('✅ Schedule availability checked successfully');
      return Map<String, dynamic>.from(response['data']);
    } catch (e) {
      AppLogger.error('❌ Error checking schedule availability: $e');
      rethrow;
    }
  }

  /// Archive a schedule
  Future<void> archiveSchedule(String scheduleId) async {
    try {
      AppLogger.info('📦 Archiving schedule: $scheduleId');
      
      await put(
        '/schedules/$scheduleId/archive',
        body: {'archived': true},
      );
      
      AppLogger.info('✅ Schedule archived successfully');
    } catch (e) {
      AppLogger.error('❌ Error archiving schedule: $e');
      if (e is NotFoundException) {
        throw ServerException('Schedule not found');
      }
      rethrow;
    }
  }

  /// Restore an archived schedule
  Future<void> restoreSchedule(String scheduleId) async {
    try {
      AppLogger.info('📤 Restoring schedule: $scheduleId');
      
      await put(
        '/schedules/$scheduleId/restore',
        body: {'archived': false},
      );
      
      AppLogger.info('✅ Schedule restored successfully');
    } catch (e) {
      AppLogger.error('❌ Error restoring schedule: $e');
      if (e is NotFoundException) {
        throw ServerException('Schedule not found');
      }
      rethrow;
    }
  }

  /// Get archived schedules
  Future<List<ScheduleModel>> getArchivedSchedules(String instructorId) async {
    try {
      AppLogger.info('📦 Fetching archived schedules for instructor: $instructorId');
      
      final response = await get('/schedules/archived', queryParams: {'instructorId': instructorId});
      
      AppLogger.info('✅ Archived schedules fetched successfully');
      return (response['data'] as List)
          .map((item) => ScheduleModel.fromMap(item))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error fetching archived schedules: $e');
      rethrow;
    }
  }
}
