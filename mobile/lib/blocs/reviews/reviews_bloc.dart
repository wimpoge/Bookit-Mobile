import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/api_service.dart';
import '../../models/review.dart';

part 'reviews_event.dart';
part 'reviews_state.dart';

class ReviewsBloc extends Bloc<ReviewsEvent, ReviewsState> {
  final ApiService _apiService;

  ReviewsBloc(this._apiService) : super(ReviewsInitial()) {
    on<HotelReviewsLoadEvent>(_onLoadHotelReviews);
    on<ReviewCreateEvent>(_onCreateReview);
    on<ReviewUpdateEvent>(_onUpdateReview);
    on<ReviewReplyEvent>(_onReplyToReview);
    on<ReviewDeleteEvent>(_onDeleteReview);
    on<UserReviewsLoadEvent>(_onLoadUserReviews);
  }

  Future<void> _onLoadHotelReviews(
      HotelReviewsLoadEvent event, Emitter<ReviewsState> emit) async {
    emit(ReviewsLoading());

    try {
      final reviews = await _apiService.getHotelReviews(event.hotelId);
      emit(ReviewsLoaded(reviews));
    } catch (e) {
      emit(ReviewsError(e.toString()));
    }
  }

  Future<void> _onCreateReview(
      ReviewCreateEvent event, Emitter<ReviewsState> emit) async {
    emit(ReviewActionLoading());

    try {
      final review = await _apiService.createReview(event.reviewData);
      emit(ReviewCreateSuccess('Review submitted successfully'));
    } catch (e) {
      emit(ReviewsError(e.toString()));
    }
  }

  Future<void> _onUpdateReview(
      ReviewUpdateEvent event, Emitter<ReviewsState> emit) async {
    emit(ReviewActionLoading());

    try {
      final review =
          await _apiService.updateReview(event.reviewId, event.reviewData);
      emit(ReviewActionSuccess('Review updated successfully'));
    } catch (e) {
      emit(ReviewsError(e.toString()));
    }
  }

  Future<void> _onReplyToReview(
      ReviewReplyEvent event, Emitter<ReviewsState> emit) async {
    emit(ReviewActionLoading());

    try {
      final review =
          await _apiService.replyToReview(event.reviewId, event.reply);
      emit(ReviewActionSuccess('Reply added successfully'));
    } catch (e) {
      emit(ReviewsError(e.toString()));
    }
  }

  Future<void> _onDeleteReview(
      ReviewDeleteEvent event, Emitter<ReviewsState> emit) async {
    emit(ReviewActionLoading());

    try {
      await _apiService.deleteReview(event.reviewId);
      emit(ReviewActionSuccess('Review deleted successfully'));
    } catch (e) {
      emit(ReviewsError(e.toString()));
    }
  }

  Future<void> _onLoadUserReviews(
      UserReviewsLoadEvent event, Emitter<ReviewsState> emit) async {
    emit(ReviewsLoading());

    try {
      final reviews = await _apiService.getUserReviews();
      emit(ReviewsLoaded(reviews));
    } catch (e) {
      emit(ReviewsError(e.toString()));
    }
  }
}
