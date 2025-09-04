import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/core/utils/injection_container.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:myapp/features/booking/presentation/bloc/booking_event.dart';
import 'package:myapp/features/booking/presentation/pages/bookings_page.dart';
import 'package:myapp/features/user/presentation/bloc/user_bloc.dart';
import 'package:myapp/features/user/presentation/bloc/user_state.dart';

class ClientBookingsPage extends StatelessWidget {
  const ClientBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, userState) {
        if (userState is UserLoaded) {
          return BlocProvider(
            create: (context) => sl<BookingBloc>()
              ..add(LoadBookingsByClient(clientId: userState.user.id)),
            child: BookingsPage(
              userId: userState.user.id,
              isInstructor: false,
            ),
          );
        }
        
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
