import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:myapp/features/user/domain/entities/user_entity.dart';
import 'package:myapp/features/user/domain/repositories/user_repository.dart';
import 'package:myapp/features/user/domain/usecases/get_instructors.dart';
import 'package:myapp/features/user/domain/usecases/get_user.dart';
import 'package:myapp/features/user/presentation/bloc/user_bloc.dart';
import 'package:myapp/features/user/presentation/bloc/user_event.dart';
import 'package:myapp/features/user/presentation/bloc/user_state.dart';
import 'package:myapp/core/error/failures.dart';

import 'user_bloc_test.mocks.dart';

@GenerateMocks([
  UserRepository,
  GetInstructors,
  GetUser,
])
void main() {
  late UserBloc userBloc;
  late MockUserRepository mockUserRepository;
  late MockGetInstructors mockGetInstructors;
  late MockGetUser mockGetUser;

  setUp(() {
    mockUserRepository = MockUserRepository();
    mockGetInstructors = MockGetInstructors();
    mockGetUser = MockGetUser();

    userBloc = UserBloc(
      getInstructors: mockGetInstructors,
      getUser: mockGetUser,
      userRepository: mockUserRepository,
    );
  });

  tearDown(() {
    userBloc.close();
  });

  group('UserBloc', () {
    test('initial state should be UserInitial', () {
      expect(userBloc.state, equals(UserInitial()));
    });

    group('LoadUser', () {
      const userId = 'user123';
      final userEntity = UserEntity(
        id: userId,
        email: 'test@example.com',
        displayName: 'Test User',
        isInstructor: false,
      );

      blocTest<UserBloc, UserState>(
        'emits [UserLoading, UserLoaded] when user loads successfully',
        build: () {
          when(mockGetUser(any))
              .thenAnswer((_) async => Right(userEntity));
          return userBloc;
        },
        act: (bloc) => bloc.add(LoadUser(userId: userId)),
        expect: () => [
          UserLoading(),
          UserLoaded(user: userEntity),
        ],
        verify: (_) {
          verify(mockGetUser(GetUserParams(userId: userId))).called(1);
        },
      );

      blocTest<UserBloc, UserState>(
        'emits [UserLoading, UserError] when user load fails',
        build: () {
          when(mockGetUser(any))
              .thenAnswer((_) async => Left(ServerFailure()));
          return userBloc;
        },
        act: (bloc) => bloc.add(LoadUser(userId: userId)),
        expect: () => [
          UserLoading(),
          UserError(message: 'Server error'),
        ],
      );
    });

    group('LoadInstructors', () {
      final instructors = [
        UserEntity(
          id: '1',
          email: 'instructor1@example.com',
          displayName: 'Instructor 1',
          isInstructor: true,
        ),
        UserEntity(
          id: '2',
          email: 'instructor2@example.com',
          displayName: 'Instructor 2',
          isInstructor: true,
        ),
      ];

      blocTest<UserBloc, UserState>(
        'emits [UserLoading, UserInstructorsLoaded] when instructors load successfully',
        build: () {
          when(mockGetInstructors(any))
              .thenAnswer((_) async => Right(instructors));
          return userBloc;
        },
        act: (bloc) => bloc.add(LoadInstructors()),
        expect: () => [
          UserLoading(),
          UserInstructorsLoaded(instructors: instructors),
        ],
        verify: (_) {
          verify(mockGetInstructors(NoParams())).called(1);
        },
      );

      blocTest<UserBloc, UserState>(
        'emits [UserLoading, UserError] when instructors load fails',
        build: () {
          when(mockGetInstructors(any))
              .thenAnswer((_) async => Left(ServerFailure()));
          return userBloc;
        },
        act: (bloc) => bloc.add(LoadInstructors()),
        expect: () => [
          UserLoading(),
          UserError(message: 'Server error'),
        ],
      );
    });
  });
}
