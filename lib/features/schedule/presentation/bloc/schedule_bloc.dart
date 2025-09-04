import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/features/schedule/domain/usecases/get_schedules.dart';
import 'package:myapp/features/schedule/domain/usecases/create_schedule.dart';
import 'package:myapp/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:myapp/features/schedule/presentation/bloc/schedule_event.dart';
import 'package:myapp/features/schedule/presentation/bloc/schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final GetSchedules _getSchedules;
  final CreateSchedule _createSchedule;
  final ScheduleRepository _scheduleRepository;

  ScheduleBloc({
    required GetSchedules getSchedules,
    required CreateSchedule createSchedule,
    required ScheduleRepository scheduleRepository,
  }) : _getSchedules = getSchedules,
       _createSchedule = createSchedule,
       _scheduleRepository = scheduleRepository,
       super(ScheduleInitial()) {
    
    on<LoadSchedules>(_onLoadSchedules);
    on<CreateScheduleEvent>(_onCreateSchedule);
    on<UpdateSchedule>(_onUpdateSchedule);
    on<DeleteSchedule>(_onDeleteSchedule);
    on<SetDefaultSchedule>(_onSetDefaultSchedule);
  }

  Future<void> _onLoadSchedules(LoadSchedules event, Emitter<ScheduleState> emit) async {
    emit(ScheduleLoading());
    
    final result = await _getSchedules(GetSchedulesParams(
      instructorId: event.instructorId,
    ));

    result.fold(
      (failure) => emit(ScheduleError(message: failure.message)),
      (schedules) => emit(ScheduleLoaded(schedules: schedules)),
    );
  }

  Future<void> _onCreateSchedule(CreateScheduleEvent event, Emitter<ScheduleState> emit) async {
    emit(ScheduleLoading());
    
    final result = await _createSchedule(CreateScheduleParams(
      schedule: event.schedule,
    ));

    result.fold(
      (failure) => emit(ScheduleError(message: failure.message)),
      (schedule) => emit(ScheduleOperationSuccess(message: 'Schedule created successfully')),
    );
  }

  Future<void> _onUpdateSchedule(UpdateSchedule event, Emitter<ScheduleState> emit) async {
    emit(ScheduleLoading());
    
    final result = await _scheduleRepository.updateSchedule(
      event.scheduleId,
      event.data,
    );

    result.fold(
      (failure) => emit(ScheduleError(message: failure.message)),
      (schedule) => emit(ScheduleOperationSuccess(message: 'Schedule updated successfully')),
    );
  }

  Future<void> _onDeleteSchedule(DeleteSchedule event, Emitter<ScheduleState> emit) async {
    emit(ScheduleLoading());
    
    final result = await _scheduleRepository.deleteSchedule(event.scheduleId);

    result.fold(
      (failure) => emit(ScheduleError(message: failure.message)),
      (_) => emit(ScheduleOperationSuccess(message: 'Schedule deleted successfully')),
    );
  }

  Future<void> _onSetDefaultSchedule(SetDefaultSchedule event, Emitter<ScheduleState> emit) async {
    emit(ScheduleLoading());
    
    final result = await _scheduleRepository.setDefaultSchedule(
      event.instructorId,
      event.scheduleId,
      event.isDefault,
    );

    result.fold(
      (failure) => emit(ScheduleError(message: failure.message)),
      (_) => emit(ScheduleOperationSuccess(message: 'Default schedule updated')),
    );
  }
}
