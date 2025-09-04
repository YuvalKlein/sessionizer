import 'package:flutter/material.dart';
import 'package:myapp/models/schedule.dart';
import 'package:myapp/services/schedule_service.dart';

class ScheduleViewModel extends ChangeNotifier {
  final ScheduleService _scheduleService;

  ScheduleViewModel(this._scheduleService);

  Stream<List<Schedule>> getSchedules(String instructorId) {
    return _scheduleService.getSchedulesStream(instructorId).map((snapshot) {
      return snapshot.docs.map((doc) => Schedule.fromFirestore(doc)).toList();
    });
  }

  Future<void> createSchedule(Schedule schedule) async {
    await _scheduleService.createSchedule(schedule.toMap());
    notifyListeners();
  }

  Future<void> updateSchedule(Schedule schedule) async {
    await _scheduleService.updateSchedule(schedule.id, schedule.toMap());
    notifyListeners();
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _scheduleService.deleteSchedule(scheduleId);
    notifyListeners();
  }
}
