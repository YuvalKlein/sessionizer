import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/core/utils/logger.dart';
import 'package:myapp/features/user/domain/usecases/get_instructors.dart';
import 'package:myapp/features/user/domain/usecases/get_user.dart';
import 'package:myapp/features/user/domain/repositories/user_repository.dart';
import 'package:myapp/core/utils/usecase.dart';
import 'package:myapp/features/user/presentation/bloc/user_event.dart';
import 'package:myapp/features/user/presentation/bloc/user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final GetInstructors _getInstructors;
  final GetUser _getUser;
  final UserRepository _userRepository;

  UserBloc({
    required GetInstructors getInstructors,
    required GetUser getUser,
    required UserRepository userRepository,
  }) : _getInstructors = getInstructors,
       _getUser = getUser,
       _userRepository = userRepository,
       super(UserInitial()) {
    
    on<LoadInstructors>(_onLoadInstructors);
    on<LoadUser>(_onLoadUser);
    on<UpdateUser>(_onUpdateUser);
  }

  Future<void> _onLoadInstructors(LoadInstructors event, Emitter<UserState> emit) async {
    emit(UserLoading());
    
    final result = await _getInstructors(NoParams());

    result.fold(
      (failure) => emit(UserError(message: failure.message)),
      (instructors) => emit(InstructorsLoaded(instructors: instructors)),
    );
  }

  Future<void> _onLoadUser(LoadUser event, Emitter<UserState> emit) async {
    AppLogger.blocEvent('UserBloc', 'LoadUser', data: {'userId': event.userId});
    emit(UserLoading());
    AppLogger.blocState('UserBloc', 'UserLoading');
    
    final result = await _getUser(GetUserParams(userId: event.userId));

    result.fold(
      (failure) {
        AppLogger.error('UserBloc LoadUser failed', failure);
        emit(UserError(message: failure.message));
        AppLogger.blocState('UserBloc', 'UserError', data: {'message': failure.message});
      },
      (user) {
        AppLogger.debug('UserBloc LoadUser success', data: {'userId': user.id, 'displayName': user.displayName});
        emit(UserLoaded(user: user));
        AppLogger.blocState('UserBloc', 'UserLoaded', data: {'userId': user.id});
      },
    );
  }

  Future<void> _onUpdateUser(UpdateUser event, Emitter<UserState> emit) async {
    emit(UserLoading());
    
    final result = await _userRepository.updateUser(
      event.userId,
      event.data,
    );

    result.fold(
      (failure) => emit(UserError(message: failure.message)),
      (user) => emit(UserOperationSuccess(message: 'User updated successfully')),
    );
  }
}
