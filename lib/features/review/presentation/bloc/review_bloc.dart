import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/features/review/domain/usecases/create_review.dart';
import 'package:myapp/features/review/domain/usecases/get_reviews_by_booking.dart';
import 'package:myapp/features/review/domain/usecases/get_review_by_booking_and_client.dart';
import 'package:myapp/features/review/presentation/bloc/review_event.dart';
import 'package:myapp/features/review/presentation/bloc/review_state.dart';

class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final CreateReview _createReview;
  final GetReviewsByBooking _getReviewsByBooking;
  final GetReviewByBookingAndClient _getReviewByBookingAndClient;

  ReviewBloc({
    required CreateReview createReview,
    required GetReviewsByBooking getReviewsByBooking,
    required GetReviewByBookingAndClient getReviewByBookingAndClient,
  })  : _createReview = createReview,
        _getReviewsByBooking = getReviewsByBooking,
        _getReviewByBookingAndClient = getReviewByBookingAndClient,
        super(ReviewInitial()) {
    on<CreateReviewEvent>(_onCreateReview);
    on<LoadReviewsByBookingEvent>(_onLoadReviewsByBooking);
    on<LoadReviewByBookingAndClientEvent>(_onLoadReviewByBookingAndClient);
  }

  Future<void> _onCreateReview(CreateReviewEvent event, Emitter<ReviewState> emit) async {
    emit(ReviewLoading());
    
    final params = CreateReviewParams(
      bookingId: event.bookingId,
      clientId: event.clientId,
      instructorId: event.instructorId,
      sessionId: event.sessionId,
      rating: event.rating,
      comment: event.comment,
    );

    final result = await _createReview(params);
    
    result.fold(
      (failure) => emit(ReviewError(message: failure.message)),
      (review) => emit(ReviewCreated(review: review)),
    );
  }

  Future<void> _onLoadReviewsByBooking(LoadReviewsByBookingEvent event, Emitter<ReviewState> emit) async {
    emit(ReviewLoading());
    
    final result = await _getReviewsByBooking(event.bookingId);
    
    result.fold(
      (failure) => emit(ReviewError(message: failure.message)),
      (reviews) => emit(ReviewLoaded(reviews: reviews)),
    );
  }

  Future<void> _onLoadReviewByBookingAndClient(LoadReviewByBookingAndClientEvent event, Emitter<ReviewState> emit) async {
    emit(ReviewLoading());
    
    final params = GetReviewByBookingAndClientParams(
      bookingId: event.bookingId,
      clientId: event.clientId,
    );

    final result = await _getReviewByBookingAndClient(params);
    
    result.fold(
      (failure) => emit(ReviewError(message: failure.message)),
      (review) => emit(ReviewLoaded(reviews: review != null ? [review] : [])),
    );
  }
}
