part of 'reviews.dart';

abstract class ReviewsEvent extends Equatable {
  const ReviewsEvent();

  @override
  List<Object> get props => [];
}

class HotelReviewsLoadEvent extends ReviewsEvent {
  final int hotelId;

  const HotelReviewsLoadEvent({required this.hotelId});

  @override
  List<Object> get props => [hotelId];
}

class ReviewCreateEvent extends ReviewsEvent {
  final Map<String, dynamic> reviewData;

  const ReviewCreateEvent({required this.reviewData});

  @override
  List<Object> get props => [reviewData];
}

class ReviewUpdateEvent extends ReviewsEvent {
  final int reviewId;
  final Map<String, dynamic> reviewData;

  const ReviewUpdateEvent({
    required this.reviewId,
    required this.reviewData,
  });

  @override
  List<Object> get props => [reviewId, reviewData];
}

class ReviewReplyEvent extends ReviewsEvent {
  final int reviewId;
  final String reply;

  const ReviewReplyEvent({
    required this.reviewId,
    required this.reply,
  });

  @override
  List<Object> get props => [reviewId, reply];
}

class ReviewDeleteEvent extends ReviewsEvent {
  final int reviewId;

  const ReviewDeleteEvent({required this.reviewId});

  @override
  List<Object> get props => [reviewId];
}

class UserReviewsLoadEvent extends ReviewsEvent {}
